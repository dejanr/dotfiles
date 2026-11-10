import csv
import json
from pathlib import Path

from analysis import utc


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")
    path.chmod(0o600)


def input_files(paths):
    files = []
    for path in map(Path, paths):
        if path.is_dir():
            downloads = sorted(path.glob("raw-*.json"))
            if not downloads:
                raise ValueError(f"{path}: no raw-*.json downloads")
            files.extend(downloads)
        else:
            files.append(path)
    return files


def load_events(paths):
    events = []
    for path in input_files(paths):
        data = json.loads(path.read_text())
        if not isinstance(data, dict) or not isinstance(data.get("events"), list):
            raise ValueError(f"{path}: expected an AWS filter-log-events download")
        if data.get("nextToken"):
            raise ValueError(f"{path}: paginated input is incomplete")
        events.extend(data["events"])
    return events


def offline_scope(paths):
    parents = {path.parent.resolve() for path in input_files(paths)}
    captures = [
        json.loads((parent / "scope.json").read_text())
        for parent in sorted(parents)
        if (parent / "scope.json").exists()
    ]
    return {
        "inputs": [str(Path(path).resolve()) for path in paths],
        "offline": True,
        "captures": captures,
        "captureBoundaries": "See captures; unknown for inputs without scope.json",
    }


def write_csv(path, rows):
    if not rows:
        path.write_text("")
    else:
        with path.open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
    path.chmod(0o600)


def cell(value):
    if value is None:
        return "unknown"
    return str(value).replace("|", "\\|").replace("\n", " ")


def table(headers, rows):
    lines = [headers, ["---"] * len(headers), *rows]
    return "\n".join(
        "| " + " | ".join(cell(value) for value in row) + " |" for row in lines
    )


def optional_time(value):
    return utc(value) if value is not None else "unknown"


def burst_table(bursts):
    rows = [
        [
            optional_time(burst["firstMissMs"]),
            burst["missCallers"],
            burst["renderCallers"],
            burst["containers"],
            burst["ssrPeak"]["count"],
            burst["successfulWrites"],
            burst["statuses"].get(503, 0),
            burst["ssrStartsAfterFirstWrite"],
        ]
        for burst in bursts
    ]
    return table(
        [
            "First miss (UTC)",
            "Miss callers",
            "Rendered callers",
            "Containers",
            "SSR peak",
            "Writes",
            "Final 503",
            "SSR starts after first write",
        ],
        rows,
    )


def key_report(key):
    totals = key["totals"]
    headers = [
        [row["ifModifiedSince"], row["cacheStatus"], row["status"], row["requests"]]
        for row in key["headers"]
    ]
    lines = [
        f"## Key `{key['cacheKeyId']}`",
        "",
        f"Requests: {totals['requests']}; miss callers: {totals['missCallers']}; "
        f"rendered callers: {totals['renderCallers']}; cache hits: {totals['cacheHits']}.",
        "",
        f"Missing final access records: {totals['missingAccessRecords']}. "
        f"Fetch outcomes: {key['fetchOutcomes']}. Store outcomes: {key['storeOutcomes']}.",
        "",
        burst_table(key["bursts"]),
        "",
        "### If-Modified-Since",
        "",
        table(
            ["Request validator", "Cache status", "HTTP status", "Requests"], headers
        ),
    ]
    for burst in key["bursts"]:
        lines.extend(burst_details(burst))
    return "\n".join(lines)


def burst_details(burst):
    return [
        "",
        f"### Burst at {optional_time(burst['firstMissMs'])}",
        "",
        f"Last first-miss: {optional_time(burst['lastMissMs'])}. "
        f"First write: {optional_time(burst['firstWriteMs'])}. "
        f"Last write: {optional_time(burst['lastWriteMs'])}. "
        f"Last SSR end: {optional_time(burst['lastSsrEndMs'])}.",
        "",
        f"Miss callers before the first write: {burst['missCallersBeforeFirstWrite']}. "
        f"Post-miss outstanding peak: {burst['postMissOutstandingPeak']['count']}. "
        f"SSR events: {burst['ssrEvents']}; rendered callers: {burst['renderCallers']}.",
        "",
        f"Pressure: {burst['pressureRows']} events across {burst['pressureCallers']} callers. "
        f"Reasons: {burst['pressure']['reasons']}.",
        "",
        f"SSR elapsed milliseconds: {burst['ssrDurationMs']}. "
        f"Miss-request milliseconds: {burst['missRequestDurationMs']}.",
    ]


def report(summary, scope):
    lines = [
        "# Thundering herd investigation",
        "",
        "PRIVATE: may contain infrastructure identifiers and request data. Redact before sharing.",
        "",
        "## Scope",
        "",
        "```json",
        json.dumps(scope, indent=2),
        "```",
        "",
        f"Raw input events: {summary['rawEvents']}. Normalized events: {summary['normalizedEvents']}.",
        "",
        "## Coverage and interpretation",
        "",
        "- Bursts group first misses by an inactivity gap; they are candidates, not simultaneous-call counts.",
        "- SSR overlap uses recorded intervals and assumes synchronized host clocks; elapsed time is not CPU time.",
        "- Capture boundaries can omit starts, completions, or earlier writes. Missing records remain unknown.",
        "- Cache misses do not distinguish expiry, eviction, or invalidation.",
        "- Header counts describe the observed request hop, not which earlier hop added or omitted a header.",
        "- Summaries cover the downloaded windows, not the entire discovery range.",
        "",
        f"Pressure reasons within the supplied input: {summary['contextPressure']['reasons']}.",
    ]
    lines.extend(f"- Warning: {warning}" for warning in summary["warnings"])
    if not summary["keys"]:
        lines.extend(
            [
                "",
                "No matching diagnostic events. Check scope, deployment, logging, and access before inferring absence.",
            ]
        )
    return (
        "\n".join(lines)
        + "\n\n"
        + "\n\n".join(key_report(key) for key in summary["keys"])
        + "\n"
    )


def save_analysis(directory, summary, rows, events, scope):
    write_json(directory / "summary.json", {**summary, "scope": scope})
    write_csv(directory / "requests.csv", rows)
    timeline = [
        {
            "timeUtc": utc(event["at"]),
            "cacheKeyId": event["cacheKeyId"],
            "requestId": event.get("requestId"),
            "kind": event["kind"],
            "outcome": event.get("outcome", event.get("status")),
            "stream": event["stream"],
        }
        for event in events
    ]
    write_csv(directory / "timeline.csv", timeline)
    path = directory / "report.md"
    path.write_text(report(summary, scope))
    path.chmod(0o600)
    return path
