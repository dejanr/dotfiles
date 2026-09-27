# Jira Cloud access and scoped tokens

Use this reference for Cloud authentication and the REST fallback. Ticket writes still require the approval gate in [SKILL.md](SKILL.md).

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

For classic Jira scopes, `read:jira-work` and `write:jira-work` can support reading creation metadata and creating an issue, subject to project permissions. Granular-scoped tokens have different requirements; consult the endpoint documentation rather than treating these classic scope names as universal.

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
- [Jira Cloud issue creation and metadata](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/)
- [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
