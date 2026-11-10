import argparse
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

from analysis import KEY, analyze, timestamp, utc
from artifacts import load_events, offline_scope, save_analysis, write_json

CONNECTION_OPTIONS = ("profile", "region", "log_group")
DISCOVERY_BUCKET_SECONDS = 5


class Aws:
    def __init__(self, options):
        self.options = options

    def call(self, service, operation, *arguments):
        command = [
            "aws",
            "--profile",
            self.options.profile,
            "--region",
            self.options.region,
            "--no-cli-pager",
            "--cli-connect-timeout",
            "10",
            "--cli-read-timeout",
            "60",
            service,
            operation,
            *map(str, arguments),
            "--output",
            "json",
        ]
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=120,
            env={**os.environ, "AWS_CLI_AUTO_PROMPT": "off"},
        )
        if result.returncode:
            raise RuntimeError(
                f"AWS {operation} failed. Refresh the selected profile if its token expired.\n{result.stderr.strip()}"
            )
        return json.loads(result.stdout)

    def check_access(self):
        self.call("sts", "get-caller-identity", "--query", "Account")

    def query(self, start_ms, end_ms, query):
        result = self.call(
            "logs",
            "start-query",
            "--query-language",
            "CWLI",
            "--log-group-name",
            self.options.log_group,
            "--start-time",
            math.floor(start_ms / 1000),
            "--end-time",
            math.ceil(end_ms / 1000),
            "--query-string",
            query,
        )
        query_id = result["queryId"]
        return self.wait(query_id)

    def wait(self, query_id):
        deadline = time.monotonic() + 300
        while time.monotonic() < deadline:
            result = self.call("logs", "get-query-results", "--query-id", query_id)
            if result["status"] == "Complete":
                return {**result, "queryId": query_id}
            if result["status"] not in ("Scheduled", "Running"):
                raise RuntimeError(f"Query {query_id} ended with {result['status']}")
            time.sleep(1)
        self.call("logs", "stop-query", "--query-id", query_id)
        raise RuntimeError(f"Query {query_id} exceeded five minutes and was cancelled")

    def download(self, window, key, context):
        arguments = [
            "--log-group-name",
            self.options.log_group,
            "--start-time",
            window[0],
            "--end-time",
            window[1],
        ]
        if not context:
            arguments.extend(["--filter-pattern", f'"{key}"'])
        result = self.call("logs", "filter-log-events", *arguments)
        if result.get("nextToken"):
            raise RuntimeError("Incomplete download: AWS returned a continuation token")
        return result


def duration(value):
    match = re.fullmatch(r"([1-9][0-9]*)([smhd])", value)
    if not match:
        raise argparse.ArgumentTypeError(
            "Use a positive duration such as 15m, 1h, or 1d"
        )
    return (
        int(match[1]) * {"s": 1000, "m": 60000, "h": 3600000, "d": 86400000}[match[2]]
    )


def cache_key(value):
    if not KEY.fullmatch(value):
        raise argparse.ArgumentTypeError(
            "Expected a lowercase 64-character cache key hash"
        )
    return value


def positive(value):
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("Expected a positive integer")
    return number


def arguments(argv=None):
    shared = argparse.ArgumentParser(add_help=False)
    shared.add_argument(
        "--out",
        type=Path,
        help="New private artifact directory; defaults to a temporary directory",
    )
    shared.add_argument(
        "--gap", type=duration, default="5s", help="Burst inactivity gap"
    )
    parser = argparse.ArgumentParser(
        description="Read-only CloudWatch cache-stampede investigation. Requires AWS CLI and Python standard library."
    )
    commands = parser.add_subparsers(dest="command", required=True)
    command_options = {
        "parents": [shared],
        "formatter_class": argparse.ArgumentDefaultsHelpFormatter,
    }
    daily = commands.add_parser(
        "daily",
        **command_options,
        help="Rank miss candidates and download the top windows",
    )
    daily.add_argument(
        "--since",
        type=duration,
        default="1h",
        help="Discovery range; use 1d for a daily review",
    )
    daily.add_argument("--end", help="Timezone-qualified end; defaults to now")
    daily.add_argument(
        "--top", type=positive, default=3, help="Maximum candidate windows to download"
    )
    online = commands.add_parser(
        "investigate", **command_options, help="Download selected key/window pairs"
    )
    online.add_argument("--key", type=cache_key, required=True)
    online.add_argument(
        "--at",
        action="append",
        required=True,
        help="Timezone-qualified time; repeat for additional windows",
    )
    for command in (daily, online):
        for name in CONNECTION_OPTIONS:
            command.add_argument(
                "--" + name.replace("_", "-"),
                required=True,
                help="Selected AWS " + name.replace("_", " "),
            )
        command.add_argument(
            "--padding",
            type=duration,
            default="10s",
            help="Context before and after a candidate",
        )
        command.add_argument(
            "--context",
            action="store_true",
            help="Download full windows, including unrelated keys and requests",
        )
    offline = commands.add_parser(
        "analyze",
        **command_options,
        help="Reanalyze saved filter-log-events JSON without AWS access",
    )
    offline.add_argument(
        "--input",
        type=Path,
        nargs="+",
        required=True,
        help="Saved run directories or raw JSON files",
    )
    offline.add_argument(
        "--key", type=cache_key, help="Select one key from full-window downloads"
    )
    return parser.parse_args(argv)


def output_directory(path):
    target = (Path(tempfile.gettempdir()) if path is None else path).resolve()
    if any((parent / ".git").exists() for parent in (target, *target.parents)):
        raise ValueError("Keep investigation artifacts outside Git repositories")
    if path is None:
        return Path(tempfile.mkdtemp(prefix="thundering-herd-run-"))
    target.mkdir(mode=0o700, parents=True, exist_ok=False)
    return target


def discovery_query(top):
    return (
        'filter event = "fetch" and outcome = "missing" '
        "| stats count(*) as fetchRows, count_distinct(requestId) as callers "
        f"by cacheKeyId, bin({DISCOVERY_BUCKET_SECONDS}s) as bucket "
        f"| filter callers > 1 | sort callers desc | limit {top}"
    )


def discover(aws, options, directory):
    end = timestamp(options.end) if options.end else round(time.time() * 1000)
    start = end - options.since
    print(
        f"Discovery: {utc(start)} to {utc(end)}; this scans CloudWatch data.",
        file=sys.stderr,
    )
    result = aws.query(start, end, discovery_query(options.top))
    write_json(directory / "discovery.json", result)
    candidates = [
        dict((cell["field"], cell["value"]) for cell in row)
        for row in result["results"]
    ]
    windows = []
    for candidate in candidates:
        key = cache_key(candidate["cacheKeyId"])
        at = timestamp(candidate["bucket"].replace(" ", "T") + "+00:00")
        windows.append(
            (
                key,
                at - options.padding,
                at + DISCOVERY_BUCKET_SECONDS * 1000 + options.padding,
            )
        )
    return windows, {
        "startUtc": utc(start),
        "endUtc": utc(end),
        "statistics": result.get("statistics"),
        "candidateLimit": options.top,
        "bucketSeconds": DISCOVERY_BUCKET_SECONDS,
    }


def capture(aws, windows, options, directory):
    paths = []
    for index, (key, start, end) in enumerate(windows):
        print(
            f"Download {index + 1}/{len(windows)}: {key} {utc(start)}–{utc(end)}",
            file=sys.stderr,
        )
        path = directory / f"raw-{index + 1:02d}-{key[:12]}.json"
        data = aws.download((start, end), key, options.context)
        write_json(path, data)
        paths.append(path)
    return paths


def online_run(options, directory, aws):
    scope = {name: getattr(options, name) for name in CONNECTION_OPTIONS}
    scope["context"] = options.context
    if options.command == "daily":
        windows, discovery = discover(aws, options, directory)
        scope["discovery"] = discovery
    else:
        windows = [
            (
                options.key,
                timestamp(at) - options.padding,
                timestamp(at) + options.padding,
            )
            for at in options.at
        ]
    scope["windows"] = [
        {"cacheKeyId": key, "startUtc": utc(start), "endUtc": utc(end)}
        for key, start, end in windows
    ]
    write_json(directory / "scope.json", scope)
    paths = capture(aws, windows, options, directory)
    raw_events = load_events(paths)
    selected_keys = {key for key, start, end in windows}
    return raw_events, selected_keys, scope


def execute(options):
    os.umask(0o077)
    if options.command != "analyze":
        aws = Aws(options)
        aws.check_access()
    directory = output_directory(options.out)
    if options.command == "analyze":
        raw = load_events(options.input)
        scope = offline_scope(options.input)
        captured_keys = {
            window["cacheKeyId"]
            for capture in scope["captures"]
            for window in capture["windows"]
        }
        keys = {options.key} if options.key else captured_keys or None
        summary, rows, events = analyze(raw, keys, options.gap)
    else:
        raw, keys, scope = online_run(options, directory, aws)
        summary, rows, events = analyze(raw, keys, options.gap)
    path = save_analysis(directory, summary, rows, events, scope)
    print(path)
    for key in summary["keys"]:
        print(
            f"{key['cacheKeyId']}: {key['totals']['missCallers']} miss callers; "
            f"{key['totals']['renderCallers']} rendered callers; SSR peak {key['ssrPeak']['count']}"
        )
    return directory


def main():
    try:
        execute(arguments())
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
