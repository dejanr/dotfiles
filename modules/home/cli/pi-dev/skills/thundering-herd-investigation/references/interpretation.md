# Evidence and interpretation

## Local source walkthrough

Use the application checkout resolved from the active harness working directory, not the skill's installation directory. Inspect it read-only; investigation does not authorize changes to application code or production settings.

1. **Establish provenance.** Record the repository/worktree root, `git rev-parse HEAD`, and `git status --short`. Identify the deployed revision from existing deployment metadata or captured version records. Record a match, mismatch, or unknown; local modifications and a different revision limit which behavior the checkout can establish. Inspect an available matching revision without switching or resetting the user's worktree.
2. **Find the emitters.** Search for literal event names, message fragments, or field names from a supplied log sample. Without a sample, locate logging configuration and the cache/render request path first. Read enclosing functions, logger wrappers, serializers, access-log templates, and middleware/proxy configuration. Distinguish application payload fields from transport envelopes, renamed fields, sampling, redaction, and omitted values. Verify the derived format against captured records before normalizing them.
3. **Trace execution semantics.** Follow each emitter's callers and relevant dependencies through lookup, rendering, writes, rejection, retries, and final response. Inspect tests for alternate branches. Establish the effective key and cache layer, request-ID propagation and retry scope, worker identity, timestamp units and clock origin, and whether durations cover rendering, queueing, or the whole request. Check whether a log marks an attempt, completion, acknowledged write, or merely scheduled work; follow the async/error paths before treating it as success.
4. **Resolve the disputed behavior.** For miss/skip claims, inspect key construction, eligibility checks, lookup results, expiry/invalidation, and store visibility. For header claims, trace conditional handling and header forwarding at the observed hop. For pressure/retry claims, identify the measured resource, threshold, rejection branch, retry policy, and final access record. For coalescing claims, determine whether coordination is worker-local or shared across the same effective key. An outcome label alone does not establish its cause.
5. **Save the mapping.** Maintain private `source-notes.md` with provenance and one row per event/field used in analysis:

   | Observed event/field | Emitter `path:line` | Meaning and emission condition | Generic field/conversion | Deployment match or uncertainty |
   | --- | --- | --- | --- | --- |

   Include supporting caller/config/test citations for interpretations that depend on more than the emitter. Keep source-derived behavior separate from log-observed execution and hypotheses. Add focused excerpts only when needed; keep application schemas and private source out of this public skill.

For a private converter, preserve raw downloads unchanged and write normalized copies separately with conversion provenance. Map only meanings established by source and samples. Preserve missing versus known-absent values, units, event identity, and correlation scope. Required fields that cannot be derived faithfully are a compatibility gap, not permission to invent IDs, timestamps, or success outcomes. Do not feed ambiguous conversions into the analyzer as established evidence.

When source is unavailable or does not match deployment, report observed counts and timing only where field meanings are established, and list the missing evidence needed for causal conclusions. Log text and source comments are leads; executable call paths, configuration, tests, and captured records support the interpretation.

## Generic event contract

The CLI consumes structured JSON messages in an AWS `filter-log-events` envelope. This is a synthetic interchange format, not a description of any application's diagnostics. Each message requires `event`, `cacheKeyId` (a lowercase 64-character hash), `requestId`, and `sourceEndMs` (UTC epoch milliseconds).

| Event | Additional fields |
| --- | --- |
| `fetch` | `outcome`: `missing`, `hit`, or another recorded result |
| `store` | `outcome`: `written` or another recorded result |
| `ssr` | `sourceStartMs`, `durationMs`, `hostname` (an opaque worker identifier) |
| `pressure` | `reason` (a generic rejection category) |
| `access` | `status` (HTTP), `requestMs`, `cacheStatus` (`HIT`, `MISS`, or another recorded result) |

Access events may include `upstreamStatus` (for example, `503, 200`), `ifModifiedSince`, and `lastModified`. Use `-` for a known absent header; an omitted field means unknown. The analyzer does not retain raw URLs or unhashed cache keys in request summaries.

Synthetic message example:

```json
{"event":"fetch","cacheKeyId":"1111111111111111111111111111111111111111111111111111111111111111","requestId":"request-1","sourceEndMs":1767268800000,"outcome":"missing"}
```

Fields live at the JSON root. Daily discovery queries this contract directly. Other formats, including plaintext access logs, need a private conversion before offline analysis. Preserve event IDs, streams, and timestamps in the download envelope. Keep converters and real diagnostic schemas outside public repositories.

Repeated event IDs are deduplicated across overlapping downloads. Missing IDs fall back to stream, timestamp, and message identity. Unrecognized event types and non-JSON messages are ignored; malformed recognized events produce coverage warnings. Confirm that the supplied format matches before treating empty output as evidence.

Use source timestamps for intervals; ingestion timestamps include transport delay. Cross-worker intervals assume synchronized clocks. Invalid or touching intervals contribute no positive overlap. Multiple render attempts remain separate intervals but retain one distinct rendered caller.

## Counts and concurrency

- **Miss callers:** distinct request IDs with a logged cache miss. Repeated lookups do not add callers.
- **Rendered callers:** distinct request IDs with a completed render event. Missing completion logs do not prove rejection or failure.
- **SSR attempts:** completed render events, potentially more than one per caller.
- **Burst:** first misses separated by no more than the configured inactivity gap. This can merge separate events during sustained traffic.
- **SSR peak:** maximum overlap of actual recorded render intervals. It excludes work before and after rendering.
- **Outstanding peak:** maximum overlap from first miss to final access time. It includes work and waiting outside rendering.
- **Starts after first write:** recorded render starts after the first successful write among that burst's captured requests. This shows continued work after population, not work that a particular fix would certainly avoid.

A burst is evidence of a stampede when multiple callers miss the same effective key before population and independently regenerate it. Sequential renders can still belong to the same herd: requests may already be queued or loading data. A five-second discovery bucket alone establishes only a candidate.

Short windows can omit earlier writes, fetches, completions, or other participants. Report observed lower bounds instead of treating unknown events as zero. The script counts successful writes, not failed store attempts. Outcomes remain available separately in `summary.json`.

## Pressure and retries

Correlate rejection reasons and final responses by request ID. For example, `503, 200` is one recovered caller; `503, 503` with final 503 is one failed caller. One caller can emit several rejection records.

A rejection category is not proof of its underlying cause. Render elapsed time is not CPU time. Pressure on other keys shows broader load, not which request caused it. Default downloads contain the selected key only; broader-pressure claims require `--context` or existing complete-window inputs.

## Conditional headers

Compare exact `If-Modified-Since` values across cache outcomes and correlate render events by request ID. Header presence on all misses is correlation, not proof of bypass. Identical headers on hits contradict a universal bypass rule. A cached 304 with no render is evidence of conditional handling on a hit.

A known absent header means the observed request hop received no value. A client, CDN, or intermediate proxy may make an unconditional request. User agents do not identify which hop omitted the header.

Validate the application's cache key, lookup outcomes, skip conditions, and response validators before attributing behavior. A miss is distinct from a skipped lookup or a cached 304. Expiry, eviction, invalidation, and revalidation need separate evidence. Generating a new `Last-Modified` value during rendering may explain changed validators, but not why an entry was missing.

## Follow-up decisions

For a confirmed cross-worker stampede, evaluate distributed request coalescing over the effective cache key. A worker-local lock cannot cover other workers. Consider stale serving only when freshness requirements permit it. A late cache recheck may save rendering while leaving earlier work intact.

Choose remedies supported by the source walkthrough and its deployment-match evidence. A response header or a cache-specific lock setting does not establish coordination across an unrelated cache layer.
