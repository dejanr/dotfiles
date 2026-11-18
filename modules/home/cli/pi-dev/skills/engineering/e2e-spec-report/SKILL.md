---
name: e2e-spec-report
description: Create source-grounded Given/When/Then and Gherkin reports for the E2E tests in a folder.
disable-model-invocation: true
compatibility: Python 3.10+ standard library for reports and serving. Node.js 18+ and a locally installed TypeScript compiler for Playwright AST discovery.
---

# E2E specification report

Turn a folder of E2E tests into a readable comparison and Gherkin specification. The agent interprets code; the scripts discover declarations, validate the inventory, and render artifacts. Running the renderer alone does not extract behavior.

Invoke with `/skill:e2e-spec-report /path/to/module-or-e2e-folder`.

Resolve `SKILL_DIR` to this directory. Resolve `REPO` from the user's application checkout, not the dotfiles repository publishing this skill.

## 1. Establish scope

Use the folder supplied after `/skill:e2e-spec-report`. If absent, ask for it. Read that checkout's agent instructions and test-runner configuration.

Default to source inspection without running tests, starting application services, or installing dependencies. Use a fresh OS temp directory for analysis and output unless the user selects a destination.

For Playwright, find its actual entry files, imports, wrappers, and testMatch/testIgnore rules. Inspect `.spec.*`, `.e2e.*`, `.smoke.*`, and relevant `.test.*` files. Classify unit tests separately. Other frameworks require a source-grounded discovery adapter; the bundled scanner is Playwright-oriented.

```sh
WORK=$(mktemp -d "${TMPDIR:-/tmp}/e2e-spec.XXXXXX")
node "$SKILL_DIR/scripts/scan.mjs" "$FOLDER" --repo "$REPO" \
  --output "$WORK/inventory.json"
```

The scanner resolves TypeScript from the target checkout. If unavailable, locate an existing installation and pass `--typescript /path/to/typescript.js`. If none exists, report the blocker; do not silently replace AST discovery with regex counts.

**Done:** every candidate entry file has a classification, and the discovery manifest exists.

## 2. Account for declarations and registration

Read [references/inventory.md](references/inventory.md) before editing the manifest.

Inspect each entry file and its setup/teardown hooks. Follow every registration candidate into its implementation, including shared helpers outside the requested folder. Record additional generated declarations and their evidence in the manifest.

Resolve aliases, title constants, nested loops, brand/device/vendor lists, licensing filters, inherited skips, conditional skips, expected failures, and environment branches. Expand each statically known variant into a separate case. Retain browser/device suite context when titles repeat.

Use bounded reads and process one entry file at a time. Store substantial intermediate results in files rather than codemode state. Inspect syntax and literals; never evaluate test modules or guessed expression strings to expand cases. Test collection can execute module code too.

Record unresolved expressions or registrations explicitly. Partial inventories must identify what is missing, not invent a case count.

**Done:** each discovered declaration has cases or an unresolved reason; every registration candidate has a written resolution or unresolved reason.

## 3. Derive observable behavior

For every case, read the full implementation and every helper that affects setup, actions, assertions, or execution conditions. Follow page objects and fixture defaults until the behavior is clear.

Write:

- **Given:** fixture, permissions, saved state, and relevant hook setup.
- **When:** actions the implementation actually performs.
- **Then:** assertions the implementation actually makes.

Preserve the exact resolved original title. Put title/implementation differences in `notes`; leave the test code unchanged. Separate static skips from conditional skips, omitted branches, and early returns. Distinguish stubbed responses from real integration calls.

Use [the interpretation checklist](references/inventory.md#interpretation-checklist) to avoid turning actions, helper names, or comments into stronger assertions. Keep claims tied to source locations, including helper evidence.

Author `cases` in the canonical inventory or separate JSON arrays per entry file. Keep Given/When/Then as single-line strings. If a prior inventory is the selected base, copy these strings exactly rather than paraphrasing for Gherkin.

**Done:** every documented case has source-grounded Given/When/Then, execution metadata, and notes for any meaningful mismatch.

## 4. Render and verify

```sh
python3 "$SKILL_DIR/scripts/report.py" build "$WORK/inventory.json"
```

If cases are in separate arrays, repeat `--cases "$WORK/cases/<entry>.json"`. Read `--help` for the interface. Set `--outdir` only to a new directory; existing output is never overwritten.

Set `OUTPUT` to the returned `directory`. Use resolved absolute paths across separate tool calls; shell variables may not persist.

The builder produces:

- `report.html`: styled, searchable Gherkin and title-comparison views.
- `report.md`: portable specification and notes.
- `specification.feature`: one Scenario per expanded case.
- `inventory.csv` and `inventory.json`: exact titles, parameters, steps, and provenance.
- `sources.html`: escaped excerpts around allowlisted source references.

Verify that case IDs/counts and Given/When/Then values agree across JSON, CSV, Markdown, HTML, and Gherkin. Check source links and skipped counts. Counts are static expanded cases, before browser-project/retry multiplication. Treat unresolved items as an incomplete inventory.

Gherkin is as-built documentation, not independent acceptance requirements or executable BDD integration. Skip metadata and original CI tags do not configure a Gherkin runner.

**Done:** artifacts preserve the reviewed inventory and disclose every remaining limitation.

## 5. Provide a local URL

Start a server only for the generated report directory:

```sh
nohup python3 "$SKILL_DIR/scripts/report.py" serve "$OUTPUT" --port 0 \
  > "$OUTPUT/server.log" 2>&1 < /dev/null &
```

Read `$OUTPUT/server.json` after startup for its URL and PID. Confirm an HTTP 200 for `report.html` and download links before giving the URL. If the tool environment ends background processes, use its supported session/service mechanism or provide the restart command; never promise an unverified URL.

The server binds only to `127.0.0.1`, selects a free port, and serves report artifacts only. Never serve the application repository root. Give the user the URL, output directory, scenario count, unresolved count, and stop command `kill <PID>`.

**Done:** the URL responds and the user can download the specification. No commit or Nix rebuild is part of this workflow.
