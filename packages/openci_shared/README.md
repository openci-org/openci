# openci_shared

Shared constants and models for OpenCI.

## Upgrading to 2.0.0

Remove `githubBaseUrl` arguments and property reads from `Team` and `BuildJobPlan`.
The server owns repository URL configuration through `GITHUB_API_BASE_URL`.
`BuildJobPlan.fromJson` accepts older planner payloads by ignoring their legacy
`githubBaseUrl` field. Use the verified GitHub connection API below for team
connections.

## GitHub connection

Use `OpenCIApiService` to read and confirm a pending GitHub connection:

| Method | Endpoint | Response body type |
| --- | --- | --- |
| `getGitHubConnectionSession(teamId, reference)` | `POST /teams/{teamId}/github/session` | `GitHubConnectionSessionResult` |
| `getGitHubConnectionCandidates(teamId, reference)` | `POST /teams/{teamId}/github/candidates` | `GitHubConnectionCandidatesResult` |
| `confirmGitHubConnection(teamId, reference, installationId)` | `POST /teams/{teamId}/github/confirm` | `GitHubConnectionConfirmationResult` |

Read methods send only `reference` in the JSON body. Confirmation sends
`reference` and the selected `installationId`. Configure
`createOpenCIChopperClient` with the existing Firebase ID-token provider; the
token is added to the Bearer header. Keep the reference out of URLs and logs.
Session reads have a ten-second timeout. Candidate reads and confirmation allow
one minute for the server's GitHub requests.

Confirmation rechecks the user's authority before saving the connection and
consuming the temporary session. Its successful response contains only
`success: true`.

Check `response.isSuccessful` before using the typed body. An empty candidates
list is a successful response. For non-2xx responses, `response.body` is null
and `response.error` retains the JSON string. GitHub failures include a `code`:
`github_reauthorization_required` (409), `github_permissions_required` (403),
or `github_unavailable` (502). These differ from an OpenCI authentication
failure (401) or an invalid connection session (403 without a GitHub code).
Confirmation can also return `github_connection_conflict` (409) when another
team owns the selected installation.

## Workflow files

`OpenCIApiService.fetchOpenCIFiles` requests
`GET /teams/{teamId}/repositories/{repo}/openci-files`. Pass the commit or
branch as `ref`, plus the repository `owner` and GitHub App `installationId`.
The response contains Dart workflow files from `openci/` as JSON objects with
`name`, `path`, and `content`. Requests require team membership or a valid
internal API key.
