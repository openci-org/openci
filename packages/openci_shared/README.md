# openci_shared

Shared constants and models for OpenCI.

## GitHub connection

Use `OpenCIApiService` to read a pending GitHub connection:

| Method | Endpoint | Response body type |
| --- | --- | --- |
| `getGitHubConnectionSession(teamId, reference)` | `POST /teams/{teamId}/github/session` | `GitHubConnectionSessionResult` |
| `getGitHubConnectionCandidates(teamId, reference)` | `POST /teams/{teamId}/github/candidates` | `GitHubConnectionCandidatesResult` |

Both methods send only `reference` in the JSON body. Configure
`createOpenCIChopperClient` with the existing Firebase ID-token provider; the
token is added to the Bearer header. Keep the reference out of URLs and logs.
Session reads have a ten-second timeout. Candidate reads allow one minute for
the server to check multiple organizations.

Check `response.isSuccessful` before using the typed body. An empty candidates
list is a successful response. For non-2xx responses, `response.body` is null
and `response.error` retains the JSON string. GitHub failures include a `code`:
`github_reauthorization_required` (409), `github_permissions_required` (403),
or `github_unavailable` (502). These differ from an OpenCI authentication
failure (401) or an invalid connection session (403 without a GitHub code).

## Workflow files

`OpenCIApiService.fetchOpenCIFiles` requests
`GET /teams/{teamId}/repositories/{repo}/openci-files`. Pass the commit or
branch as `ref`, plus the repository `owner` and GitHub App `installationId`.
The response contains Dart workflow files from `openci/` as JSON objects with
`name`, `path`, and `content`. Requests require team membership or a valid
internal API key.
