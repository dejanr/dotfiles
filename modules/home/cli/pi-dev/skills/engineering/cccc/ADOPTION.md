# Adopting complexity reporting

## Report first

1. Inspect existing lint rules, task runners, and CI before proposing another check. Use cccc when its per-function metrics or mixed-language coverage add useful information.
2. Add an explicit report task only when requested. Pin the CLI through the repository's package/dev-shell mechanism; keep local and CI versions aligned. Publish the JSON and triaged findings without blocking changes initially.
3. Agree on roots, exclusions, supported-language coverage, and tool-specific thresholds using the measured baseline. Record how justified complexity and suspected measurement artifacts are handled.

A possible configuration, after agreeing on these values:

```toml
table = false
cache = false
max-cognitive = 15
max-cyclomatic = 20
```

Run `cccc --config cccc.toml <roots...>` through the existing task runner. Keep roots explicit and use ordinary JSON output; the analysis skill's independent `--no-config` inventory deliberately bypasses this policy. Cache or changed-files optimizations should follow measured runtime problems, not be prerequisites.

## Gate only after policy is agreed

Decide whether the gate applies to the full tree or only new/regressed complexity. Built-in `--max-cognitive` and `--max-cyclomatic` check absolute values; they do not implement a baseline or attribute violations to a diff. For an existing codebase, a changed-function policy needs a separately implemented and validated comparison. Without that mechanism, describe the gate as full-scope enforcement.

A trustworthy CI task must:

- Capture cccc's exit status separately from JSON post-processing. Exit 1 means a threshold was exceeded; exit 2 indicates a CLI/configuration error. An exact threshold value passes: the comparison is strictly greater than the limit.
- Validate the JSON shape, expected nonempty coverage, and zero `summary.parse_error_count`, even when cccc exits 0. Publish affected paths and treat partial parsing or missing coverage as unverified/failing, rather than a pass.
- Keep the full JSON as an artifact even on failure. Threshold failures may produce no stderr; extract violating functions recursively through `children[]` for a readable diagnostic.
- Check both metrics and preserve the agreed exclusion/exception policy. Lowering thresholds, expanding exclusions, or updating a baseline is a policy change, not an automatic fix for a failing build.

**Done:** the user has approved the policy; local and CI commands use the same version and scope; deliberate threshold violations, parse errors, and empty coverage have each been exercised before enforcement is enabled.
