---
name: cccc
description: Measure cognitive and cyclomatic complexity with moznion/cccc. Use when ranking complex functions, investigating complexity warnings, comparing a refactor's before/after scores, or adopting complexity reporting or CI gates.
compatibility: Requires the moznion/cccc CLI and jq; command examples use Bash.
---

# Complexity analysis with cccc

Use scores to locate code worth reading, not as a verdict on its design. Analysis is read-only; change code or enforcement only when requested.

## 1. Establish scope and tooling

- Identify the requested roots or files, relevant languages, existing complexity tasks, and `cccc.toml` / `.cccc.toml` in the working directory and its ancestors. Reuse the repository's dev shell or task runner.
- Confirm `cccc --version`, `cccc --help`, and `jq --version`. These commands and JSON shapes were checked against cccc 1.8.3. For other versions, verify compatibility rather than silently upgrading or downgrading. If a dependency is missing, report it and agree on setup; prefer a repository-managed dependency over a global install.
- Record the version, working directory, roots, extension overrides, and thresholds. Follow repository thresholds; without a policy, use cognitive >15 or cyclomatic >20 as exploratory cutoffs, not acceptance criteria.
- For a before/after comparison, capture the baseline before editing. Use identical versions, roots, flags, and cutoffs for both runs; compare individual functions against the diff, accounting for renames and moved lines. If no baseline can be recovered safely, report the comparison as unverified.

**Done:** scope and invocation are reproducible, or a missing prerequisite is reported.

## 2. Capture a trustworthy inventory

Run from the agreed working directory. Replace `src` with the actual roots; preserve any required custom extension mappings with explicit `--ext` flags. Use a temporary directory outside the repository for artifacts.

```bash
out=$(mktemp -d "${TMPDIR:-/tmp}/cccc.XXXXXX")
roots=(src)
cccc --no-config --no-cache "${roots[@]}" > "$out/all.json"
jq -e '
  (.files | type == "array") and
  (.summary.parse_error_count | type == "number")
' "$out/all.json"
jq '.summary' "$out/all.json"
jq -r '.files[].path' "$out/all.json" | sort -u > "$out/all.paths"
```

Check the CLI exit status before consuming its output. `--no-config` makes this an independent inventory: discovered config can otherwise hide files, change extensions, set thresholds, or switch output to a table. This is not a run of the repository's configured gate. `--no-cache` avoids cache artifacts. Keep JSON mode and omit `--min` and `--top-*` so the inventory stays complete.

Inspect `file_count`, `function_count`, `parse_error_count`, and `parse_error_files`. Zero files or functions means empty/unsupported coverage, not a clean result. Match the inventory to the expected source files and disclose unsupported languages or extensions. Directory walks respect ignore files and skip `node_modules`; use `--no-ignore` only when ignored sources are explicitly in scope.

Parse errors can coexist with exit 0 and empty stderr. Report affected paths first and label their scores partial; they cannot establish a clean pass. Missing expected JSON fields are a compatibility problem, not implicit zeros.

**Done:** expected coverage is accounted for and any empty, unsupported, or partially parsed scope is identified.

## 3. Apply deliberate exclusions

Choose exclusions from the task, not a blanket rule that tests or generated code never matter. For a production-code report, tests, stories, mocks, or vendored files may be noise. Keep the unfiltered inventory for comparison.

```bash
excludes=(--exclude '**/*.{test,spec}.{ts,tsx}' --exclude '**/*.stories.tsx')
cccc --no-config --no-cache "${excludes[@]}" "${roots[@]}" > "$out/scoped.json"
jq '.summary' "$out/scoped.json"
jq -r '.files[].path' "$out/scoped.json" | sort -u > "$out/scoped.paths"
comm -23 "$out/all.paths" "$out/scoped.paths"
```

Use the same extension/language flags as the inventory and repeat its exit-status, schema, coverage, and parse-error checks. With no exclusions, reuse `all.json` as `scoped.json`.

Globs match paths relative to each input root and also bare filenames. For `cccc src`, use `dev/**` or `**/dev/**`, not `src/dev/**`. Quote globs; `*` does not span `/`, while `**` does. A valid pattern that matches nothing is silent. Verify every intended exclusion against the actual removed paths and check that relevant production files remain. Inline Rust `#[cfg(test)]` modules need classification later; file globs cannot remove them independently.

**Done:** every exclusion is explained, its effect is verified, and remaining coverage is nonempty or explicitly reported as empty.

## 4. Rank and read the candidates

Set the agreed cutoffs in this query. Include both metrics: a flat dispatcher may have high cyclomatic but low cognitive complexity.

```bash
jq --argjson cognitive 15 --argjson cyclomatic 20 '
  [.files[] | .path as $path
   | .functions[] | recurse(.children[]?)
   | select(.cognitive > $cognitive or .cyclomatic > $cyclomatic)
   | {path: $path, name, kind, line, cognitive, cyclomatic}]
  | sort_by(-.cognitive, -.cyclomatic, .path, .line)
' "$out/scoped.json" > "$out/candidates.json"
```

Nested functions and callbacks have independent scores under `children[]`; traversing only `.functions[]` misses them. `--top-cognitive` / `--top-cyclomatic` change the shape to `{metric, top, summary}`; use them for a quick preview, not this full-inventory query.

Read each candidate and classify it with file:line evidence:

| Classification                 | Evidence to record                                                                                             |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| Actionable                     | Branching or nesting that obscures behavior; identify the specific decision or responsibility to simplify.     |
| Justified complexity           | Necessary dispatch or domain cases whose current structure is readable; explain why.                           |
| Test / out of scope            | Test setup, fixtures, generated or vendored code; explain its relevance or exclusion.                          |
| Suspected measurement artifact | A concrete mismatch between the score and source; confirm with a minimal example before calling it a tool bug. |

Same-name calls can be mistaken for recursion: e.g. `build()` calling another object's `build()`. Inspect the call targets, especially when cognitive is high but cyclomatic is low. A simple flat `switch` / `match` contributes one cognitive increment while its cases increase cyclomatic complexity; inspect case bodies before recommending a split. Scores from Biome, SonarJS, Clippy, or other tools need not agree; compare baselines within the same tool/version.

**Done:** every candidate is classified with evidence. If the candidate set exceeds the available review budget, state the reviewed count and unreviewed remainder instead of claiming complete triage.

## 5. Report or hand off

Report version and invocation, covered/unsupported scope, parse errors, verified exclusions, cutoffs, counts per classification, and a concise candidate table with both scores, file:line, evidence, and recommendation. Include artifact paths; distinguish partial measurements from verified findings.

For an authorized refactor, preserve behavior and rerun the same measurement plus relevant tests, lint, and type checks. Use `codebase-design` when choosing a seam or interface: named responsibilities should justify extraction, rather than splitting solely to lower a score. Unrelated existing violations remain outside the change's scope.

For adoption of reporting or enforcement, read [ADOPTION.md](ADOPTION.md).
