# Inventory contract

The discovery manifest is the canonical model. Add reviews and cases to it; preserve the scanner's declarations and registration candidates. The builder does not infer behavior or prove parameter expansion.

## Structure

```json
{
  "version": 1,
  "title": "Checkout E2E specification",
  "repoRoot": "/absolute/path/to/application",
  "scope": "tests/e2e",
  "snapshot": "Git commit and working-tree state at inspection",
  "files": [
    {
      "file": "tests/e2e/checkout.spec.ts",
      "review": "Playwright entry; all direct tests and shared registrations inspected."
    }
  ],
  "declarations": [
    {
      "id": "tests/e2e/checkout.spec.ts:12:3",
      "source": { "file": "tests/e2e/checkout.spec.ts", "line": 12 },
      "titleExpression": "'checkout_guest_order'",
      "status": "declared"
    }
  ],
  "registrations": [],
  "registrationReviews": [],
  "unresolved": [],
  "cases": [
    {
      "id": "E2E-001.1",
      "declaration": "tests/e2e/checkout.spec.ts:12:3",
      "title": "checkout_guest_order",
      "suite": ["Guest checkout"],
      "parameters": {},
      "status": "declared",
      "given": "A guest has one available item in the cart.",
      "when": "Submit the checkout form with valid details.",
      "then": "The confirmation page shows the created order number.",
      "conditions": [],
      "notes": [],
      "evidence": [
        { "file": "tests/helpers/checkout.ts", "line": 45 }
      ]
    }
  ]
}
```

This is an illustrative example; source paths/line numbers must exist in the selected checkout.

- `files[].review` records the entry-file classification, exclusions, and manual discovery findings. Every file needs a review.
- `declarations[].id` is the stable scanner key. Multiple variants refer to the same declaration.
- `source` is the call/declaration shown in the report. Paths are relative to `repoRoot`; source references cannot escape it through paths or symlinks.
- `titleExpression` is original source syntax; `cases[].title` is the exact resolved runtime title, including original whitespace and tags.
- `suite` is the resolved describe path. Keep device/browser context here when needed to distinguish identical titles.
- `status` is `declared` or `skipped`. An inherited static skip must survive expansion. Expected-failure modifiers belong in `conditions` or `notes`.
- `conditions` names conditional skips, environment branches, fixture-dependent skips, and paths that return before assertions.
- `notes` records mismatches, assertion limits, stubs, and uncertain behavior. Use arrays, even for one item.
- `evidence` points to helpers/constants/fixtures supporting the interpretation. Source snippets are private local report artifacts.
- Add manually discovered shared registrations as declarations with the local registration call as `source`; cite the actual shared test implementation in `evidence`.
- Each `registrations[]` candidate needs `registrationReviews: [{ "id": "<candidate id>", "resolution": "<what it registers; which declarations account for it>" }]`.
- If expansion remains unknown, add `unresolved: [{ "id": "<declaration or registration id>", "reason": "<missing evidence>" }]`. Known variants can coexist with unresolved remaining variants. The report then displays an incomplete-inventory banner.

Only actual expanded cases go in `cases`. The declaration list and unresolved ledger protect against omissions; they are not a substitute for inspecting custom registration code.

The scanner checks `.spec`, `.e2e`, `.smoke`, and `.test` JS/TS suffixes. It skips dependency/build/report directories and symlink entries. Inspect runner configuration for additional names or symlinked tests. Registration candidates are calls receiving a known test alias, not an exhaustive call-graph analysis; follow other registration wrappers found while reading imports and entry code.

## Large inventories

Read and describe one entry file at a time. Case batches are JSON arrays using the same case shape:

```sh
python3 "$SKILL_DIR/scripts/report.py" build "$WORK/inventory.json" \
  --cases "$WORK/cases/editor.json" \
  --cases "$WORK/cases/rendering.json"
```

Keep `inventory.json`'s `cases` empty when using batches. The rendered `inventory.json` contains the combined canonical model. The builder validates IDs, titles within suite scope, source paths/lines, skips, file reviews, and discovery accounting before writing output.

## Interpretation checklist

| Implementation evidence | Report it as |
|---|---|
| A helper named publish only saves a draft | Draft save; preserve the original title and note the mismatch. |
| UI action or `isVisible()` result is ignored | Performed action, not an asserted result. |
| Save clicked without response/reload assertion | Save attempted, not proven persistence. |
| Fixed input is corrected after an error | Errors clear; successful recovery save only if actually asserted. |
| A helper accepts an attached fallback or one of several widgets | That fallback/minimum condition, not every third-party embed loaded. |
| API fixture creation followed by URL checks | API setup and URL assertion, not full UI creation/rendering. |
| Two HTTP requests only check status | Repeated status checks, not proof of cache HIT/reuse. |
| Content assertions request no-cache | Fresh fetched content, not freshness of ordinary cached responses. |
| Suite-level skip, runtime skip, and an early return | Separate static-skip count, conditional execution, and omitted assertions. |
| Test labels loop over IDs but requests use one URL | Repeated endpoint checks, not ID-specific behavior. |
| Mocked workflow/check responses drive badges | Stubbed UI behavior, not an analytics integration. |

Inspect helper implementations, not only names or step descriptions. Avoid false precision from hard-coded brand/ticket maps: resolve the current source definitions and licensing filters each run.

## Safety and delivery

Inspect code as data. AST parsing is safe discovery; evaluating source expressions, importing test modules, or invoking test collection can run application code.

Reports have inline CSS/JavaScript and no CDN dependencies. Text and source excerpts are HTML-escaped. The local server allowlists the six generated artifacts, denies directory listings, and binds to loopback. Report directories can contain proprietary test details; keep them local unless the user approves sharing.

Source snippets are a few lines around each cited location, not a copy of the repository. An HTML file also works offline; keep the output directory together for downloads/source links.

A successful build is structural validation, not a test run, a formal Gherkin-parser check, or independent proof that all generated runtime variants were found.

## Skill maintenance

Run the bundled tests after changing its scripts:

```sh
python3 -m unittest discover -s "$SKILL_DIR/scripts" -p 'test_*.py' -v
node --test "$SKILL_DIR/scripts/scan.test.mjs"
```

Scanner tests require TypeScript. Set `E2E_REPORT_TYPESCRIPT` to an existing compiler path when it is not resolvable from the working checkout.
