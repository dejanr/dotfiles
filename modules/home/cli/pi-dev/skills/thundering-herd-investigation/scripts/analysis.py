import collections
import datetime as dt
import json
import re
import statistics

EVENT_KINDS = {"fetch", "ssr", "store", "pressure", "access"}
KEY = re.compile(r"^[a-f0-9]{64}$")


def utc(milliseconds):
    return dt.datetime.fromtimestamp(milliseconds / 1000, dt.timezone.utc).isoformat(
        timespec="milliseconds"
    )


def timestamp(value):
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("Use an explicit timezone, for example 2026-01-01T12:00:00Z")
    return round(parsed.timestamp() * 1000)


def validate_diagnostic(data, kind):
    data["sourceEndMs"] = int(data["sourceEndMs"])
    if kind in ("fetch", "store"):
        data["outcome"] = str(data["outcome"])
    if kind == "ssr":
        data["sourceStartMs"] = int(data["sourceStartMs"])
        data["durationMs"] = float(data["durationMs"])
        data["hostname"] = str(data["hostname"])
    if kind == "access":
        data["status"] = int(data["status"])
        data["requestMs"] = float(data["requestMs"])
        data["cacheStatus"] = str(data["cacheStatus"])
    if kind == "pressure":
        data["reason"] = str(data["reason"])


def parse_event(raw):
    try:
        data = json.loads(raw["message"])
    except json.JSONDecodeError:
        return None
    if not isinstance(data, dict) or data.get("event") not in EVENT_KINDS:
        return None
    if not KEY.fullmatch(str(data.get("cacheKeyId", ""))):
        raise ValueError("Expected a hashed cache key")
    if not isinstance(data.get("requestId"), str) or not data["requestId"]:
        raise ValueError("Expected a request ID")
    kind = data["event"]
    validate_diagnostic(data, kind)
    return {
        **data,
        "kind": kind,
        "at": int(data["sourceEndMs"]),
        "stream": raw.get("logStreamName", ""),
    }


def normalize(raw_events):
    seen = set()
    events, warnings = [], []
    for raw in raw_events:
        identity = raw.get("eventId") or (
            raw.get("logStreamName"),
            raw.get("timestamp"),
            raw.get("message"),
        )
        if identity in seen:
            continue
        seen.add(identity)
        try:
            event = parse_event(raw)
        except (KeyError, TypeError, ValueError, OverflowError):
            warnings.append(
                "A malformed event was excluded; inspect the private raw download."
            )
            continue
        if event:
            events.append(event)
    return sorted(events, key=lambda event: event["at"]), warnings


def first(values):
    return min(values, default=None)


def last(values):
    return max(values, default=None)


def distribution(values):
    if not values:
        return None
    return {"min": min(values), "median": statistics.median(values), "max": max(values)}


def peak(intervals):
    valid = [
        (start, end)
        for start, end in intervals
        if start is not None and end is not None and start < end
    ]
    edges = sorted(
        [(start, 1) for start, end in valid] + [(end, -1) for start, end in valid]
    )
    active = maximum = 0
    at = None
    for time, change in edges:
        active += change
        if active > maximum:
            maximum, at = active, time
    return {"count": maximum, "firstAt": utc(at) if at is not None else None}


def request_row(identity, events):
    grouped = collections.defaultdict(list)
    for event in events:
        grouped[event["kind"]].append(event)
    access = (grouped["access"] or [{}])[-1]
    ssr = grouped["ssr"]
    misses = [
        event["at"] for event in grouped["fetch"] if event.get("outcome") == "missing"
    ]
    writes = [
        event["at"] for event in grouped["store"] if event.get("outcome") == "written"
    ]
    return {
        "cacheKeyId": identity[0],
        "requestId": identity[1],
        "firstMissMs": first(misses),
        "fetchRows": len(grouped["fetch"]),
        "ssrCount": len(ssr),
        "ssrStartMs": first([event["sourceStartMs"] for event in ssr]),
        "ssrEndMs": last([event["sourceEndMs"] for event in ssr]),
        "ssrStartsMs": [event["sourceStartMs"] for event in ssr],
        "ssrDurationsMs": [event["durationMs"] for event in ssr],
        "ssrDurationMs": sum(event["durationMs"] for event in ssr),
        "hosts": sorted({event["hostname"] for event in ssr}),
        "firstWriteMs": first(writes),
        "lastWriteMs": last(writes),
        "writeRows": len(writes),
        "pressureRows": len(grouped["pressure"]),
        "status": access.get("status"),
        "cacheStatus": access.get("cacheStatus"),
        "requestEndMs": access.get("sourceEndMs"),
        "requestMs": access.get("requestMs"),
        "upstreamStatus": access.get("upstreamStatus"),
        "ifModifiedSince": access.get("ifModifiedSince"),
        "lastModified": access.get("lastModified"),
    }


def correlate(events):
    grouped = collections.defaultdict(list)
    for event in events:
        request_id = event.get("requestId")
        if request_id:
            grouped[(event["cacheKeyId"], request_id)].append(event)
    return [
        request_row(identity, records) for identity, records in sorted(grouped.items())
    ]


def request_counts(rows, misses, renders):
    return {
        "requests": len(rows),
        "missCallers": len(misses),
        "renderCallers": len(renders),
        "ssrEvents": sum(row["ssrCount"] for row in rows),
        "containers": len({host for row in renders for host in row["hosts"]}),
        "successfulWrites": sum(row["writeRows"] for row in rows),
        "cacheHits": sum(row["cacheStatus"] == "HIT" for row in rows),
        "statuses": dict(collections.Counter(row["status"] for row in rows)),
        "pressureRows": sum(row["pressureRows"] for row in rows),
        "pressureCallers": sum(row["pressureRows"] > 0 for row in rows),
        "missingAccessRecords": sum(row["status"] is None for row in rows),
    }


def cache_timing(rows, misses, renders):
    writes = [row["firstWriteMs"] for row in rows if row["firstWriteMs"] is not None]
    first_write = first(writes)
    return {
        "firstMissMs": first([row["firstMissMs"] for row in misses]),
        "lastMissMs": last([row["firstMissMs"] for row in misses]),
        "firstWriteMs": first_write,
        "lastWriteMs": last(
            [row["lastWriteMs"] for row in rows if row["lastWriteMs"] is not None]
        ),
        "missCallersBeforeFirstWrite": before_write(misses, "firstMissMs", first_write),
        "ssrStartsAfterFirstWrite": after_write(renders, first_write),
    }


def render_timing(misses, renders):
    return {
        "lastSsrEndMs": last([row["ssrEndMs"] for row in renders]),
        "postMissOutstandingPeak": peak(
            [(row["firstMissMs"], row["requestEndMs"]) for row in misses]
        ),
        "ssrDurationMs": distribution(
            [value for row in renders for value in row["ssrDurationsMs"]]
        ),
        "missRequestDurationMs": distribution(
            [row["requestMs"] for row in misses if row["requestMs"] is not None]
        ),
        "totalSsrElapsedMs": sum(row["ssrDurationMs"] for row in renders),
        "firstMissToSsrMs": distribution(
            [
                row["ssrStartMs"] - row["firstMissMs"]
                for row in renders
                if row["firstMissMs"] is not None
            ]
        ),
    }


def metrics(rows):
    misses = [row for row in rows if row["firstMissMs"] is not None]
    renders = [row for row in rows if row["ssrCount"]]
    return {
        **request_counts(rows, misses, renders),
        **cache_timing(rows, misses, renders),
        **render_timing(misses, renders),
    }


def before_write(rows, field, first_write):
    if first_write is None:
        return None
    return sum(row[field] < first_write for row in rows)


def after_write(rows, first_write):
    if first_write is None:
        return None
    return sum(start > first_write for row in rows for start in row["ssrStartsMs"])


def header_counts(rows):
    counts = collections.Counter(
        (row["ifModifiedSince"], row["cacheStatus"], row["status"])
        for row in rows
        if row["status"] is not None
    )
    return [
        {
            "ifModifiedSince": header,
            "cacheStatus": cache,
            "status": status,
            "requests": count,
        }
        for (header, cache, status), count in sorted(
            counts.items(), key=lambda item: str(item[0])
        )
    ]


def ssr_intervals(events):
    return [
        (event["sourceStartMs"], event["sourceEndMs"])
        for event in events
        if event["kind"] == "ssr"
    ]


def pressure_summary(events):
    pressure = [event for event in events if event["kind"] == "pressure"]
    return {
        "reasons": dict(collections.Counter(event["reason"] for event in pressure)),
        "attempts": [
            {"requestId": event["requestId"], "reason": event["reason"]}
            for event in pressure
        ],
    }


def burst_groups(rows, gap_ms):
    misses = sorted(
        (row for row in rows if row["firstMissMs"] is not None),
        key=lambda row: row["firstMissMs"],
    )
    groups = []
    for row in misses:
        if not groups or row["firstMissMs"] - groups[-1][-1]["firstMissMs"] > gap_ms:
            groups.append([])
        groups[-1].append(row)
    return [group for group in groups if len(group) > 1]


def burst_summary(rows, events):
    ids = {row["requestId"] for row in rows}
    selected = [event for event in events if event.get("requestId") in ids]
    return {
        **metrics(rows),
        "ssrPeak": peak(ssr_intervals(selected)),
        "requestIds": sorted(ids),
        "pressure": pressure_summary(selected),
    }


def key_summary(key, rows, events, gap_ms):
    selected_rows = [row for row in rows if row["cacheKeyId"] == key]
    selected_events = [event for event in events if event["cacheKeyId"] == key]
    return {
        "cacheKeyId": key,
        "totals": metrics(selected_rows),
        "ssrPeak": peak(ssr_intervals(selected_events)),
        "headers": header_counts(selected_rows),
        "fetchOutcomes": dict(
            collections.Counter(
                event.get("outcome")
                for event in selected_events
                if event["kind"] == "fetch"
            )
        ),
        "storeOutcomes": dict(
            collections.Counter(
                event.get("outcome")
                for event in selected_events
                if event["kind"] == "store"
            )
        ),
        "bursts": [
            burst_summary(group, selected_events)
            for group in burst_groups(selected_rows, gap_ms)
        ],
    }


def analyze(raw_events, keys=None, gap_ms=5000):
    context, warnings = normalize(raw_events)
    events = [event for event in context if keys is None or event["cacheKeyId"] in keys]
    rows = correlate(events)
    present_keys = sorted({event["cacheKeyId"] for event in events})
    summary = {
        "rawEvents": len(raw_events),
        "normalizedEvents": len(events),
        "warnings": warnings,
        "gapMs": gap_ms,
        "contextPressure": pressure_summary(context),
        "keys": [key_summary(value, rows, events, gap_ms) for value in present_keys],
    }
    return summary, rows, events
