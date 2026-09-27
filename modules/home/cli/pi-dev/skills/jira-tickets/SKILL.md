---
name: jira-tickets
description: Draft, format, and create or edit Jira tickets with explicit approval of the final content before publishing. Use when asked to turn a discussion into a ticket, post a Jira issue, revise a description, or troubleshoot Jira Cloud scoped-token authentication.
---

# Jira tickets

## 1. Establish scope

Confirm the project and issue type from the user's request. Ask if either is missing; repository context alone is not permission to choose them. For edits, confirm the existing issue key.

Read relevant repository instructions and ticket-style skills. Inspect the implementation when the ticket depends on code behaviour. Distinguish agreed scope from suggestions that the user has not accepted.

Read the destination project's creation metadata and any required template before finalizing the draft. Use read-only requests for this preparation. Read [JIRA-CLOUD.md](JIRA-CLOUD.md) when authentication, missing CLI configuration, or direct REST access is involved.

**Done when:** destination, type, agreed scope, required fields, and applicable template are known. Surface unresolved requirements instead of inventing values.

## 2. Draft for people

Use a short, outcome-focused title and English unless the user asks otherwise. Follow a required project template; otherwise use only the sections the ticket needs:

- **Description:** prose explaining the deliverable and intended use.
- **Context & why:** prose explaining the problem and value.
- **Scope / coverage:** bullets for distinct capabilities, route families, or products.
- **Acceptance Criteria:** independently verifiable outcomes as a list.
- **Developer notes:** concise implementation constraints and useful source pointers.
- **Out of scope:** a list of explicit exclusions.
- **Open questions:** actual unresolved decisions, not placeholder questions.

Paragraphs explain; lists enumerate. Keep explanatory sections as paragraphs rather than wrapping every paragraph in a bullet. A qualification below a coverage list belongs in a paragraph when it is not another coverage item.

Preserve required checklist rows, resetting copied completion states to unchecked. Reuse the template's structure, not its stakeholder mentions, assignments, completed work, or unrelated examples. Include every proposed checklist row in the draft shown to the user. If applicability is unclear, ask rather than silently dropping rows or marking them complete.

**Done when:** one complete draft includes the exact title, description, formatting, checklist, and any metadata to be explicitly set.

## 3. Approval gate — stop before publishing

Show the complete final draft in the conversation, including project, issue type, and proposed metadata. Ask: **“Create this ticket exactly as shown?”** For an edit, show the exact proposed change and ask approval to apply it.

Wait for an explicit approval referring to that draft. Agreement with the idea, “sounds good” during planning, confirmation of the project/type, or the initial request to create a ticket is not approval of an unseen final draft.

If anything changes after approval—including appended checklist items, scope, wording, or metadata—show the revised draft and obtain approval again. Authentication troubleshooting or changing from CLI to REST does not waive this gate.

**Done when:** the user has approved the exact content and explicit metadata that will be submitted. No create/update request is allowed before this condition is met.

## 4. Publish only the approved payload

Prefer an already-working Jira CLI; check the installed command's help before using flags. A direct REST request is a valid fallback when the token supports the requested operation but CLI setup fails.

For Jira REST v3, preserve formatting in Atlassian Document Format (ADF):

- Prose → `paragraph` nodes.
- Section titles → the approved heading or bold-paragraph style.
- Lists → `bulletList` / `orderedList` containing `listItem` nodes.
- Required checklists → preserve the applicable task-list structure, with fresh local IDs and unchecked states for new tickets.

Convert the approved draft without adding content. Validate the outgoing title, text order, paragraph/list structure, and explicitly set fields against that draft. Resolve issue-type IDs from project metadata rather than hardcoding them. Leave assignee, priority, sprint, labels, and other optional fields to Jira defaults unless explicitly approved.

For edits, fetch the latest issue first, change only the approved fields, and preserve unrelated content. If the issue changed since the reviewed draft, reconcile and seek approval as needed.

Submit once and save the returned issue key immediately. After an ambiguous timeout, check whether creation succeeded before retrying; avoid duplicate tickets.

**Done when:** a successful response identifies the created issue or confirms the update. A local payload file is not a created ticket.

## 5. Verify and report

Read the saved issue back. Verify project, type, title, description, formatting structure, and explicitly set metadata. Check the rendered description when browser access is available. Report discrepancies without claiming success or silently applying new wording.

Return the issue key and its human-facing site URL. If blocked, state the exact blocker and whether any issue was created; preserve the approved draft for resumption.

**Done when:** the saved result matches the approved draft and the user receives the issue link.
