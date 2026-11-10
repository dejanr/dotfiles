import argparse
import contextlib
import io
import json
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

from analysis import analyze, normalize, peak, timestamp
from artifacts import load_events, save_analysis
from herd import (
    Aws,
    arguments,
    cache_key,
    discover,
    discovery_query,
    duration,
    execute,
    output_directory,
)

KEY = "1" * 64
OTHER_KEY = "2" * 64
BASE = timestamp("2026-01-01T12:00:00Z")


def event(number, kind, at, **fields):
    data = {
        "event": kind,
        "requestId": f"{number:032x}",
        "cacheKeyId": KEY,
        "sourceEndMs": BASE + at,
        **fields,
    }
    return {
        "eventId": str((number, kind, at)),
        "timestamp": BASE + at,
        "logStreamName": f"container/{number}",
        "message": json.dumps(data),
    }


def fetch(number, at):
    return event(
        number,
        "fetch",
        at,
        outcome="missing",
    )


def render(number, start, end, key=KEY):
    return event(
        number,
        "ssr",
        end,
        cacheKeyId=key,
        sourceStartMs=BASE + start,
        sourceEndMs=BASE + end,
        durationMs=end - start,
        hostname=f"host-{number}",
        pid=10,
    )


def store(number, at):
    return event(
        number,
        "store",
        at,
        outcome="written",
    )


def access(
    number,
    at,
    status=200,
    cache="MISS",
    header="Wed, 31 Dec 2025 23:59:00 GMT",
    upstream="200",
):
    return event(
        number,
        "access",
        at,
        status=status,
        cacheStatus=cache,
        requestMs=1000,
        upstreamStatus=upstream,
        ifModifiedSince=header,
        lastModified=header,
    )


def five_callers():
    intervals = [(300, 815), (469, 751), (836, 1300), (860, 1178), (879, 1166)]
    records = []
    for number, (start, end) in enumerate(intervals, 1):
        records.extend(
            [
                fetch(number, 100 + number),
                fetch(number, 101 + number),
                render(number, start, end),
                store(number, end + 10),
                access(number, end + 20),
            ]
        )
    return records


class AnalysisTests(unittest.TestCase):
    def test_five_callers_are_one_burst_with_three_overlapping_ssr(self):
        summary, rows, events = analyze(five_callers())
        burst = summary["keys"][0]["bursts"][0]
        self.assertEqual(
            (burst["missCallers"], burst["renderCallers"], burst["containers"]),
            (5, 5, 5),
        )
        self.assertEqual(burst["ssrPeak"]["count"], 3)
        self.assertEqual(burst["postMissOutstandingPeak"]["count"], 5)
        self.assertEqual(burst["ssrStartsAfterFirstWrite"], 3)
        self.assertEqual(len(rows), 5)
        self.assertEqual(len(events), 25)

    def test_nonoverlapping_renders_remain_burst_candidates(self):
        records = [fetch(1, 1), fetch(2, 2), render(1, 20, 30), render(2, 40, 50)]
        summary, _, _ = analyze(records)
        burst = summary["keys"][0]["bursts"][0]
        self.assertEqual(burst["ssrPeak"]["count"], 1)
        self.assertEqual(burst["missingAccessRecords"], 2)
        self.assertIsNone(burst["firstWriteMs"])
        self.assertIsNone(burst["ssrStartsAfterFirstWrite"])

    def test_adjacent_intervals_and_zero_length_intervals_do_not_overlap(self):
        self.assertEqual(peak([(1, 2), (2, 3), (2, 2), (None, 4)])["count"], 1)

    def test_overlapping_downloads_are_deduplicated(self):
        records = five_callers()
        summary, _, _ = analyze(records + records)
        self.assertEqual(summary["normalizedEvents"], 25)
        self.assertEqual(summary["keys"][0]["totals"]["renderCallers"], 5)

    def test_pressure_retry_keeps_one_caller_and_preserves_status_list(self):
        records = [
            fetch(1, 1),
            event(1, "pressure", 2, reason="capacity"),
            render(1, 10, 20),
            store(1, 21),
            access(1, 22, upstream="503, 200"),
        ]
        summary, rows, _ = analyze(records)
        self.assertEqual(rows[0]["upstreamStatus"], "503, 200")
        self.assertEqual(summary["keys"][0]["totals"]["missCallers"], 1)
        self.assertEqual(summary["contextPressure"]["reasons"], {"capacity": 1})

    def test_equal_headers_can_hit_miss_or_return_cached_304(self):
        records = [
            fetch(1, 1),
            render(1, 2, 3),
            access(1, 4),
            access(2, 5, cache="HIT"),
            access(3, 6, status=304, cache="HIT"),
            access(4, 7, cache="HIT", header="-"),
        ]
        summary, rows, _ = analyze(records)
        headers = summary["keys"][0]["headers"]
        self.assertEqual(sum(row["requests"] for row in headers), 4)
        self.assertEqual(
            next(row for row in rows if row["status"] == 304)["ssrCount"], 0
        )
        self.assertEqual(
            next(row for row in rows if row["ifModifiedSince"] == "-")["cacheStatus"],
            "HIT",
        )

    def test_key_filter_preserves_context_pressure(self):
        records = [
            render(1, 1, 2),
            event(
                2,
                "pressure",
                3,
                cacheKeyId=OTHER_KEY,
                reason="capacity",
            ),
        ]
        summary, _, _ = analyze(records, {KEY})
        self.assertEqual(len(summary["keys"]), 1)
        self.assertEqual(summary["contextPressure"]["reasons"]["capacity"], 1)

    def test_gap_separates_bursts_without_fixed_bucket_boundaries(self):
        records = [fetch(1, 4999), fetch(2, 5001), fetch(3, 12000), fetch(4, 12001)]
        summary, _, _ = analyze(records, gap_ms=5000)
        self.assertEqual(
            [burst["missCallers"] for burst in summary["keys"][0]["bursts"]], [2, 2]
        )

    def test_malformed_access_is_a_warning_not_a_silent_clean_result(self):
        record = access(1, 10)
        data = json.loads(record["message"])
        data["requestMs"] = "invalid"
        record["message"] = json.dumps(data)
        events, warnings = normalize([record])
        self.assertEqual(events, [])
        self.assertEqual(len(warnings), 1)

    def test_multiple_ssr_attempts_keep_one_rendered_caller(self):
        summary, _, _ = analyze([render(1, 1, 2), render(1, 4, 5)])
        totals = summary["keys"][0]["totals"]
        self.assertEqual((totals["renderCallers"], totals["ssrEvents"]), (1, 2))

    def test_malformed_ssr_is_reported_as_a_coverage_warning(self):
        record = event(1, "ssr", 10, sourceEndMs=BASE + 10)
        events, warnings = normalize([record])
        self.assertEqual(events, [])
        self.assertEqual(len(warnings), 1)

    def test_recognized_events_require_common_fields(self):
        for field in ("requestId", "cacheKeyId", "sourceEndMs", "outcome"):
            record = fetch(1, 1)
            data = json.loads(record["message"])
            del data[field]
            record["message"] = json.dumps(data)
            with self.subTest(field=field):
                events, warnings = normalize([record])
                self.assertEqual(events, [])
                self.assertEqual(len(warnings), 1)

    def test_unrelated_messages_are_ignored(self):
        records = [
            {"message": "unrelated plaintext", "timestamp": BASE},
            event(1, "unrelated", 1),
        ]
        self.assertEqual(normalize(records), ([], []))

    def test_request_summary_omits_raw_host_and_cache_key(self):
        record = access(1, 10)
        data = json.loads(record["message"])
        data.update(host="example.test", cacheKey="https://example.test/?private=value")
        record["message"] = json.dumps(data)
        _, rows, _ = analyze([record])
        self.assertNotIn("host", rows[0])
        self.assertNotIn("cacheKey", rows[0])
        self.assertNotIn("private=value", json.dumps(rows))

    def test_physical_attempts_after_a_write_are_not_lost(self):
        records = [
            fetch(1, 1),
            render(1, 2, 3),
            store(1, 4),
            render(1, 5, 8),
            store(1, 9),
        ]
        summary, _, _ = analyze(records)
        totals = summary["keys"][0]["totals"]
        self.assertEqual(totals["ssrStartsAfterFirstWrite"], 1)
        self.assertEqual(totals["lastWriteMs"], BASE + 9)
        self.assertEqual(totals["ssrDurationMs"], {"min": 1, "median": 2, "max": 3})


class CollectionTests(unittest.TestCase):
    def options(self, **overrides):
        return argparse.Namespace(
            **{
                "profile": "example-readonly",
                "region": "us-east-1",
                "log_group": "example-logs",
                "out": None,
                "gap": 5000,
                "command": "daily",
                "since": 3600000,
                "end": "2026-01-01T12:00:00Z",
                "top": 3,
                "padding": 10000,
                "context": False,
                **overrides,
            }
        )

    def test_credentials_are_checked_without_retaining_account(self):
        aws = Aws(self.options())
        aws.call = Mock(return_value="000000000000")
        self.assertIsNone(aws.check_access())
        aws.call.assert_called_once_with(
            "sts", "get-caller-identity", "--query", "Account"
        )

    def test_online_commands_require_explicit_connection(self):
        connection = [
            "--profile",
            "example-readonly",
            "--region",
            "us-east-1",
            "--log-group",
            "example-logs",
        ]
        for command in (
            ["daily"],
            ["investigate", "--key", KEY, "--at", "2026-01-01T12:00:00Z"],
        ):
            self.assertEqual(
                arguments(command + connection).profile, "example-readonly"
            )
            for index in range(0, len(connection), 2):
                with self.subTest(command=command, missing=connection[index]):
                    with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(
                        SystemExit
                    ):
                        arguments(
                            command + connection[:index] + connection[index + 2 :]
                        )

    def test_offline_command_needs_no_aws_options(self):
        options = arguments(["analyze", "--input", "saved-run"])
        self.assertEqual(options.command, "analyze")
        self.assertFalse(hasattr(options, "profile"))

    def test_output_inside_repository_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for marker in ("directory", "worktree"):
                git = root / marker / ".git"
                git.parent.mkdir()
                if marker == "directory":
                    git.mkdir()
                else:
                    git.write_text("gitdir: /unused")
                target = git.parent / "nested" / "artifacts"
                with self.subTest(marker=marker), self.assertRaisesRegex(
                    ValueError, "outside Git"
                ):
                    output_directory(target)
                self.assertFalse(target.exists())

    def test_symlink_into_repository_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "repository"
            repository.mkdir()
            (repository / ".git").mkdir()
            link = root / "link"
            link.symlink_to(repository, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "outside Git"):
                output_directory(link / "artifacts")

    def test_temporary_directory_inside_repository_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".git").mkdir()
            with patch("herd.tempfile.gettempdir", return_value=directory):
                with self.assertRaisesRegex(ValueError, "outside Git"):
                    output_directory(None)

    def test_new_output_directory_is_private(self):
        with tempfile.TemporaryDirectory() as directory:
            path = output_directory(Path(directory) / "artifacts")
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700)

    def test_expired_token_does_not_create_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "not-created"
            with patch.object(
                Aws, "check_access", side_effect=RuntimeError("ExpiredTokenException")
            ):
                with self.assertRaisesRegex(RuntimeError, "ExpiredToken"):
                    execute(self.options(out=output))
            self.assertFalse(output.exists())

    def test_failed_aws_command_is_not_consumed_as_json(self):
        aws = Aws(self.options())
        result = subprocess.CompletedProcess([], 1, "", "ExpiredTokenException")
        with patch("herd.subprocess.run", return_value=result):
            with self.assertRaisesRegex(RuntimeError, "Refresh"):
                aws.call("sts", "get-caller-identity")

    def test_query_failure_is_not_treated_as_empty_results(self):
        aws = Aws(self.options())
        aws.call = Mock(return_value={"status": "Failed"})
        with self.assertRaisesRegex(RuntimeError, "Failed"):
            aws.wait("test-id")

    def test_query_timeout_cancels_the_running_query(self):
        aws = Aws(self.options())
        aws.call = Mock()
        with patch("herd.time.monotonic", side_effect=[0, 301]):
            with self.assertRaisesRegex(RuntimeError, "cancelled"):
                aws.wait("test-id")
        aws.call.assert_called_once_with("logs", "stop-query", "--query-id", "test-id")

    def test_discovery_pads_both_sides_of_the_whole_bucket(self):
        result = {
            "results": [
                [
                    {"field": "cacheKeyId", "value": KEY},
                    {"field": "bucket", "value": "2026-01-01 12:00:00.000"},
                ]
            ],
            "status": "Complete",
        }
        aws = Mock()
        aws.query.return_value = result
        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stderr(io.StringIO()):
                windows, scope = discover(aws, self.options(), Path(directory))
        self.assertEqual(windows, [(KEY, BASE - 10000, BASE + 15000)])
        self.assertEqual(scope["bucketSeconds"], 5)
        self.assertIn("count_distinct(requestId)", discovery_query(3))
        self.assertIn('event = "fetch"', discovery_query(3))

    def test_download_rejects_unfinished_pagination(self):
        aws = Aws(self.options())
        aws.call = Mock(return_value={"events": [], "nextToken": "more"})
        with self.assertRaisesRegex(RuntimeError, "Incomplete"):
            aws.download((BASE, BASE + 1000), KEY, False)

    def test_offline_artifacts_have_private_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "raw.json"
            source.write_text(json.dumps({"events": five_callers()}))
            records = load_events([source])
            summary, rows, events = analyze(records)
            path = save_analysis(root, summary, rows, events, {"offline": True})
            self.assertIn("SSR peak", path.read_text())
            self.assertIn("PRIVATE", path.read_text())
            self.assertNotIn("account", path.read_text())
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
            self.assertEqual(
                json.loads((root / "summary.json").read_text())["keys"][0]["totals"][
                    "missCallers"
                ],
                5,
            )

    def test_offline_directory_retains_key_scope_without_aws(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(
            Aws, "call", side_effect=AssertionError("offline must not call AWS")
        ):
            root = Path(directory)
            source = root / "saved"
            source.mkdir()
            records = five_callers() + [render(9, 1, 2, OTHER_KEY)]
            (source / "raw-01.json").write_text(json.dumps({"events": records}))
            (source / "scope.json").write_text(
                json.dumps({"windows": [{"cacheKeyId": KEY}]})
            )
            options = self.options(
                command="analyze", input=[source], key=None, out=root / "result"
            )
            with contextlib.redirect_stdout(io.StringIO()):
                result = execute(options)
            summary = json.loads((result / "summary.json").read_text())
            self.assertEqual([row["cacheKeyId"] for row in summary["keys"]], [KEY])
            self.assertEqual(summary["keys"][0]["totals"]["missCallers"], 5)

    def test_empty_input_is_not_reported_as_proof_of_no_herd(self):
        summary, rows, events = analyze([])
        with tempfile.TemporaryDirectory() as directory:
            path = save_analysis(
                Path(directory), summary, rows, events, {"offline": True}
            )
            self.assertIn("No matching diagnostic events", path.read_text())

    def test_input_with_a_continuation_token_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "raw.json"
            path.write_text(json.dumps({"events": [], "nextToken": "more"}))
            with self.assertRaisesRegex(ValueError, "incomplete"):
                load_events([path])

    def test_dates_and_cache_keys_are_validated(self):
        self.assertEqual(timestamp("2026-01-01T13:00:00+01:00"), BASE)
        self.assertEqual(duration("1d"), 86400000)
        with self.assertRaises(ValueError):
            timestamp("2026-01-01T12:00:00")
        with self.assertRaises(argparse.ArgumentTypeError):
            cache_key("bad-key")
        with self.assertRaises(argparse.ArgumentTypeError):
            duration("0h")


if __name__ == "__main__":
    unittest.main()
