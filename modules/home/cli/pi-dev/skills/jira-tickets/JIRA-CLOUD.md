# Jira Cloud access and scoped tokens

Use this reference for Cloud authentication, reads, searches, and writes. Ticket writes still require the approval gate in [SKILL.md](SKILL.md).

## Connection and helper

The CTF role (`modules/nixos/roles/ctf.nix`) exports `JIRA_SITE`, `JIRA_EMAIL`, `JIRA_TOKEN_TYPE`, `JIRA_CLOUD_ID`, and `JIRA_PROJECT` through Home Manager. `JIRA_API_TOKEN` comes from agenix through the shell. Apply the Home Manager configuration and start a fresh login session to load changed settings. Existing agent processes keep their original environment.

Run the dependency-free Node.js helper relative to this skill directory:

```bash
node scripts/jira.mjs check
node scripts/jira.mjs view CTF-7441 --fields summary,description,status,updated
node scripts/jira.mjs search 'project = CTF ORDER BY updated DESC' --limit 20
```

`check` probes identity and project access separately and prints no account data. It does not test write access. `view` returns raw JSON, including ADF. `search` uses enhanced `/rest/api/3/search/jql`, follows `nextPageToken`, and defaults to 50 results. Increase `--limit` only when needed; the output says whether results were truncated.

For an approved update, write a JSON file containing only changed fields:

```json
{"fields":{"summary":"The exact approved title"}}
```

A description value must be ADF (or `null` for an explicitly approved removal). Read the current ADF, preserve unrelated nodes and checklists, and replace only the approved content. The helper does not convert prose to ADF or merge descriptions automatically.

After showing the exact payload and obtaining approval:

```bash
node scripts/jira.mjs update CTF-7441 /tmp/jira-approved-update.json \
  --approved --expected-updated '<updated timestamp from the reviewed issue>'
```

The helper checks the current timestamp, sends one PUT, and reads the changed fields back for verification. Review the returned values; a successful PUT alone does not prove the saved content matches. The preflight cannot prevent an edit between GET and PUT. Workflow transitions and comments need their own endpoints and approval; this helper updates fields only.

Only read operations retry transient errors, at most twice. Writes never retry. After an uncertain write or failed verification, read the issue before deciding whether to resubmit. The helper blocks redirects and redacts credentials from errors. Run its mocked tests with `node --test scripts/jira.test.mjs`.

## Select the endpoint before diagnosing the token

Obtain the site URL, account email, and token type from the user or trusted configuration. The API token belongs in `JIRA_API_TOKEN`, never in chat, a committed file, or command output.

| Token | REST base URL | Authentication |
| --- | --- | --- |
| Unscoped API token | `https://<site>.atlassian.net` | Basic: account email + API token |
| Scoped API token | `https://api.atlassian.com/ex/jira/<cloudId>` | Basic: account email + API token |

The browser's `/jira/` path is not part of the site REST base. An `invalid character '<'` JSON error can mean the client received an HTML page from the wrong URL; inspect status and content type.

Retrieve the cloud ID with an unauthenticated GET to `https://<site>.atlassian.net/_edge/tenant_info`; read its `cloudId` field. Keep the site URL separately for human-facing links: `https://<site>.atlassian.net/browse/<KEY>`.

Confirm the token belongs to the supplied account email. A scoped API token still uses Basic authentication, not OAuth Bearer authentication.

## Diagnose permission per operation

`jira setup` is an alias for `jira init`, not an alternative authentication flow. Inspect `jira init --help` and `jira issue create --help` for the installed version.

A failed CLI initialization does not necessarily mean the token is invalid. Probe read-only endpoints at the correct REST base and inspect sanitized JSON error details:

- `GET /rest/api/3/myself`: Jira identity; classic scope `read:jira-user`.
- `GET /rest/api/3/project/<PROJECT>`: access to the intended project; classic scope `read:jira-work`.

`read:me` covers Atlassian account identity; it does not replace Jira's `read:jira-user` scope. An identity request returning `401` with `Unauthorized; scope does not match` while the project request returns `200` demonstrates an operation-specific scope mismatch, not rejected credentials.

For classic Jira scopes, use `read:jira-work` for issue reads, searches, and creation metadata, and `write:jira-work` for creation and updates, subject to project permissions. Granular-scoped tokens have different requirements; consult the endpoint documentation rather than treating these classic scope names as universal.

If the requested operation works, prefer the REST fallback over requesting broader token permissions just to complete CLI initialization. If the user wants the CLI configured, explain its additional scope requirements and use the scoped-token REST base where supported by the installed client.

Only investigate expiry, revocation, wrong account, or organization restrictions after checking the endpoint and error details. Never conclude that a token needs replacing from `/myself` status alone. Tokens are injected into process environments: changing one in another shell does not automatically refresh an existing agent session.

## Safe request handling

Use an HTTP library that reads `JIRA_API_TOKEN` from the environment and builds the Basic Authorization header in memory. Avoid shell tracing, verbose authorization logs, credentials in process arguments, and printing complete environment variables or response headers.

Print only the HTTP status and selected error fields (`message`, `errorMessages`, `errors`, `code`) when diagnosing. Redact secrets before reporting output. Keep identity responses and unrelated project/user data out of logs. Send credentials only to the confirmed Atlassian API endpoint; inspect redirects rather than forwarding Authorization to an unverified host.

## Direct REST workflow

1. Inspect `GET /rest/api/3/issue/createmeta/<PROJECT>/issuetypes` and select the requested type by name.
2. Inspect `GET /rest/api/3/issue/createmeta/<PROJECT>/issuetypes/<TYPE_ID>` for fields, defaults, and allowed values. Follow pagination for both metadata requests.
3. Read a project-approved template/reference ticket if needed. Preserve template requirements without copying its completed states or people.
4. Prepare and show the full draft. Stop for approval as required by the main skill.
5. Submit `POST /rest/api/3/issue` with the approved fields. Use ADF for `fields.description` and rely on documented defaults only where metadata allows.
6. Preserve the successful response's issue key before any further requests. Do not automatically retry a create request after an ambiguous response.
7. Read `GET /rest/api/3/issue/<KEY>?fields=summary,issuetype,project,description` and any explicitly set metadata to verify the result.

Updates use `PUT /rest/api/3/issue/<KEY>` with only the approved fields. Fetch the latest description first and preserve unrelated edits. On an uncertain create result, reconcile using recent issues in the destination project and the approved title before considering a retry.

## Primary references

- [Atlassian API tokens and scoped-token URL format](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
- [Jira Cloud current-user endpoint](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-myself/)
- [Jira Cloud issue reads, edits, and creation metadata](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/)
- [Jira Cloud enhanced JQL search](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/)
- [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
