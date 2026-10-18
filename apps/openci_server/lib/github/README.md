# GitHub installation authorization

`verifyGitHubInstallation` checks whether the authenticated GitHub user can
connect a selected installation to an OpenCI team. It fetches `/user` and
`/user/installations` with the user access token on each call; the input
installation ID only selects a candidate from that fresh list.

- `GITHUB_API_BASE_URL` selects the operator's GitHub.com or GHES API endpoint.
- `GITHUB_APP_ID` must be a positive integer matching the selected installation.
- Suspended installations and candidates absent from the user's list are denied.
- A personal installation requires the account ID to match the authenticated
  user's ID. Names are not used as proof of ownership.
- An organization installation requires `GET /user/memberships/orgs/{org}` to
  return `state: active` and `role: admin`, with matching user and organization
  IDs. The GitHub App needs the **Members: read** organization permission for
  this endpoint. Ordinary members, pending invitations, and missing proof are
  denied. See the [GitHub membership API documentation](https://docs.github.com/en/rest/orgs/members#get-an-organization-membership-for-the-authenticated-user).

The helper returns the verified installation, or `null` for a denied candidate.
When `expectedGitHubUserId` is supplied, the current GitHub user must also match
the user recorded in the connection session.
GitHub API failures, including 403/404 membership responses, throw sanitized
exceptions instead of authorizing a connection. Each API operation is bounded by
a 10-second timeout; installation pagination shares its own 10-second budget.

Call this immediately before saving a connection. It does not persist a team
connection or replace OpenCI authentication, team membership checks, or binding
the completion session to the user who initiated it.

`fetchGitHubConnectionCandidates`, in the same library, fetches the current user
and installation list once per call, then applies the same connection rules to
every installation. It returns an immutable list of eligible installations;
an empty list means no eligible candidates were found. Each organization
membership request has its own 10-second timeout. If any GitHub request or
verification fails, the call throws a sanitized exception instead of returning
partial results. User and installation-list fetches retain their separate
10-second limits.

The helper itself does not read a connection session. The candidates API below
authenticates and binds the session before using its decrypted token. Selecting
a candidate still requires fresh `verifyGitHubInstallation` checks immediately
before persisting the connection.

## GitHub connection callback

Set `GITHUB_CONNECTION_RETURN_URL` on the server to the complete Dashboard return
URL, for example `https://dashboard.example/github/connection`. It must be an
absolute HTTP(S) URL without credentials, query parameters, or a fragment. Use
HTTPS outside local development. Docker Compose forwards this setting to the
server. It is distinct from `GITHUB_OAUTH_REDIRECT_URI`, which points GitHub to
the server's `/github/callback` endpoint.

After saving a pending connection session, the callback sends a `303 See Other`
to the fixed return URL with `#reference=<fresh-reference>`. The reference stays
in the fragment so it is not sent to the Dashboard server in the HTTP request.
The response retains `Cache-Control: no-store` and `Referrer-Policy: no-referrer`.
No token, OAuth code/state, or user/team identity is included in the redirect.
An unset or invalid return URL returns a generic 500 before consuming state,
calling GitHub, or creating a session; there is no request-supplied fallback URL.

Denied or failed authorization also sends a `303` to the same fixed URL, with
only `#error=<code>` in the fragment:

| Code | Meaning |
| --- | --- |
| `access_denied` | GitHub reported that authorization was denied, with valid state. |
| `invalid_callback` | Required callback parameters are missing, blank, duplicated, or conflicting. |
| `invalid_state` | State is unknown, expired, or already used. |
| `forbidden` | The initiating user is no longer a member of the team. |
| `connection_failed` | GitHub, server configuration, or database processing failed, or GitHub reported another authorization error. |

GitHub error text, exception details, and session references are never included
in failure redirects. Malformed callbacks leave state untouched; a valid state
is consumed before handling denial or contacting GitHub, so those failures
require starting a new connection attempt. An invalid return URL still returns
500 without a redirect, and methods other than GET return 405.

The Dashboard receiver is follow-up work. It must read and remove the fragment
before login redirects or analytics run, then authenticate the initiating user
through the server before continuing. A result in the URL is not proof that a
team is connected. Do not use a route that copies the reference into a login
redirect's query string.

## Reading a pending connection session

`POST /teams/:id/github/session` accepts a Firebase ID token in the Bearer header
and a JSON body containing `reference`, taken from the callback fragment. Keep
the reference out of request URLs and logs. The server uses the verified Firebase
UID and the team ID from the path; identity values supplied in the body are
ignored.

The reference must belong to that initiating user and team. The user must still
be a team member, and the session must be unexpired and unused with its encrypted
token still present. On success, the response is:

```json
{
  "success": true,
  "session": {
    "teamId": "team-1",
    "githubUserId": 123,
    "expiresAt": "2026-10-16T12:10:00.000Z"
  }
}
```

No token, reference, stored hash, or session database ID is returned. Reads do not
consume the session or connect an installation to a team. A UID alone, the
original OAuth state, and the OAuth request ID cannot retrieve the result.

Missing authentication returns 401; malformed JSON or a missing/invalid reference
field returns 400. Unknown, expired, consumed, or unauthorized sessions all return
the same 403 response. Database failures return a generic 500, and methods other
than POST return 405. All responses include `Cache-Control: no-store` and
`Referrer-Policy: no-referrer`. The Dashboard receiver remains follow-up work.
Saving a connection requires the explicit confirmation endpoint below.

## Reading connection candidates

`POST /teams/:id/github/candidates` accepts the same Bearer authentication and
JSON `{ "reference": "<post-callback-reference>" }` as the session endpoint.
After verifying the initiating UID, team, membership, expiry, and unused state,
the server decrypts the stored token using `SECRET_ENCRYPTION_KEY` and fetches
verified candidates from the operator's GitHub API endpoint. It checks the
session again after the GitHub requests, so a session that expires, is consumed,
or loses team membership during those requests cannot return candidates.

```json
{
  "success": true,
  "candidates": [
    {
      "installationId": 100,
      "accountLogin": "octocat",
      "accountType": "User"
    }
  ]
}
```

Each candidate contains only installation ID, account login, and account type.
Credentials, references, session IDs, and other teams' connection data are
excluded. Caller identity, tokens, and GitHub settings supplied in the body are
ignored. Reading does not consume the session or save a team connection.

Set the optional `GITHUB_APP_INSTALLATION_URL` to the full installation or
management page of the operator's GitHub App on GitHub.com or GHES, for example
`https://github.example/apps/openci/installations/new`. Docker Compose forwards
this setting to the server. The URL must be absolute HTTP(S), without credentials,
query parameters, or a fragment. Use HTTPS outside local development.

When the setting is valid, successful responses include `installationUrl` next
to `candidates`, including when the candidate list is empty. A missing, blank,
or invalid setting omits this field without failing candidate retrieval. No
request-supplied URL is used as a fallback. The server only returns this link;
it does not fetch the URL or use it to authorize or save a connection. Reading
the field in the shared client and displaying the link in the Dashboard are
follow-up work.

No eligible candidates returns 200 with an empty array. Authentication/input/
session/method failures use the same 401/400/403/405 responses as the session
endpoint. Database, GitHub API configuration, or decryption failures return a
generic 500.
GitHub failures include a fixed `code` alongside `success: false` and `error`:

| HTTP status | Code | Meaning |
| --- | --- | --- |
| 409 | `github_reauthorization_required` | GitHub rejected the stored token with 401. Start GitHub authorization again. This differs from an OpenCI/Firebase 401. |
| 403 | `github_permissions_required` | GitHub returned 403 or 404 while fetching the user or installation list. Check app permissions and organization access. |
| 502 | `github_unavailable` | GitHub rate limiting, network errors, malformed responses, or other upstream failures. |

Rate-limited 403 responses are recognized by `x-ratelimit-remaining: 0`,
`retry-after`, or GitHub's secondary rate-limit message; 429 also maps to
`github_unavailable`. See [GitHub's REST API troubleshooting guide](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api).
An individual organization's membership 403/404 excludes that organization from
the candidates, so inaccessible installations do not block other verified
connections. Token rejection, rate limits, and other upstream failures still
fail the whole request. Confirmation rechecks the selected installation and
continues to reject missing membership proof.
No upstream error details are returned. All responses
include `Cache-Control: no-store` and `Referrer-Policy: no-referrer`. The Dashboard
selection UI remains follow-up work.

## Confirming a team connection

`POST /teams/:id/github/confirm` requires Firebase Bearer authentication and this
JSON body:

```json
{ "reference": "<post-callback-reference>", "installationId": 200 }
```

Only these two fields are accepted. The reference must be a nonempty string and
the installation ID a positive JSON integer. Extra fields, including caller
identity, team/account metadata, tokens, and GitHub settings, return 400.
The verified Firebase UID and path team ID are passed to
`persistGitHubConnection`, which checks the session and current membership,
decrypts its token, and freshly verifies the GitHub user and selected
installation before saving and consuming the session in one transaction.
Success returns 200 with only `{ "success": true }`; the temporary token is
cleared. Neither the OAuth callback nor candidate reads save a connection.

| HTTP status | Code | Meaning |
| --- | --- | --- |
| 400 | — | Invalid JSON or confirmation fields. |
| 401 | — | Missing OpenCI/Firebase authentication. |
| 403 | — | Invalid, expired, consumed, or unauthorized session. |
| 403 | `github_permissions_required` | The selected installation or current GitHub identity/authority cannot be verified. |
| 409 | `github_reauthorization_required` | GitHub rejected the temporary user token. |
| 409 | `github_connection_conflict` | The installation is reserved by another team; no other team's details are returned. |
| 502 | `github_unavailable` | GitHub rate limiting, transport failures, or other upstream errors. |
| 500 | — | Database, encryption, or configuration failure. |
| 405 | — | Any method other than POST. |

Error JSON contains `success: false`, a fixed `error` message, and `code` only
where listed. Rejected authority, ownership conflicts, and failed transactions
preserve existing connections. Ownership conflicts leave the session unused;
reusing a successfully consumed session returns 403. All responses include
`Cache-Control: no-store` and `Referrer-Policy: no-referrer`, and neither logs nor
responses contain the reference, encrypted token, or encryption key.
The shared client's `confirmGitHubConnection` method calls this endpoint. The
Dashboard selection UI remains follow-up work.

## Verified team connection storage

Schema version 28 adds `github_connections`. Each row records the team, the
operator's GitHub API base URL and App ID, installation ID, stable account ID,
account type/login, the verifying Firebase UID and GitHub user ID, verification
time, and an explicit `active`, `suspended`, or `removed` status. Account types use
`GitHubAccountType.user` / `.organization` in Dart and retain `User` /
`Organization` in database rows and JSON. Unknown stored account types are
rejected. It stores no OAuth tokens. The URL identifies the operator's
configuration; it is not a team-editable endpoint.

`saveGitHubConnection` saves one freshly verified installation and returns
the stored row. It generates a UUID for a new connection, sets the status to
`active`, and normalizes the operator's API URL with `parseGitHubApiBaseUri`,
preserving the GHES API path.
The caller must provide server-verified installation metadata, the authorized
team, the verifying Firebase UID and GitHub user ID, and the verification time.
The helper rejects suspended installations and unsupported account types.
For an existing connection on the same team, it preserves the record ID and
owner while refreshing verified metadata, the verifier, the verification time,
and the active status. An installation reserved by another team returns `null`
without modifying or exposing that team's record, including suspended or removed
connections. A conditional database upsert makes this decision and write in one
statement, including concurrent saves. Database failures throw a sanitized error
instead of returning a conflict. It participates in the caller's transaction.

`saveGitHubConnectionAndConsumeSession` combines that save with session
consumption in one transaction. A conflict returns `null` without consuming the
session. After a successful save, it checks and consumes the session at the
current time; an invalid session throws `InvalidGitHubConnectionSessionException`
and rolls back the insert or refresh. Database failures also roll back and throw
a sanitized error. On success, the session's temporary token is cleared.

`persistGitHubConnection` connects these helpers: it reads an unused, unexpired
session for the initiating Firebase UID and team, decrypts its temporary token,
and calls `verifyGitHubInstallation` with the session's GitHub user ID and the
selected installation ID. GitHub supplies the account metadata and authority;
the operator's configuration supplies the API endpoint and App ID. GitHub calls
run before the transaction, and the final save/consume rechecks expiry, team
membership, and concurrent session use before committing. Rejected authority or
an invalid session prevents saving; an ownership conflict returns `null` without
consuming the session. Decryption and database errors expose no credentials.
The HTTP confirmation endpoint above calls this helper.

`readActiveGitHubConnections` reads a team's `active` connections for the
operator's `GITHUB_API_BASE_URL` and `GITHUB_APP_ID`. It normalizes the API URL
using the same parser as saving, preserving its path and port. No matching rows
returns an empty list; invalid configuration and database failures throw errors.
It does not use `Teams.installationIds`. Callers are responsible for authorizing
access to the team; this helper does not call GitHub to recheck live permissions.
`GET /teams/:id/github/repositories` uses this reader after checking team
membership. It returns 400 when no active connection matches, including teams
with only legacy installation IDs. It lists repositories using installation
tokens for the verified connections and returns an error if any GitHub request
fails, rather than returning a partially successful list. The same normalized
operator API URL is used for both connection lookup and GitHub requests.

`GET /teams/:id/github/repositories/:owner/:repo/branches` also requires team
membership and active connections for the operator's API URL and App ID. It
resolves the repository's installation through GitHub and returns 403 if that
installation is not among the team's active connections, before issuing an
installation token. It fetches branches with only the matching connection.
Legacy IDs cannot authorize the request, and GitHub lookup, token, or branch
failures return an error without trying another connection. No active connection
returns 400 before contacting GitHub.

`GET /teams/:id/repositories/:repo/openci-files` applies the same connection
checks to both team members and callers with a valid internal API key. The
requested installation must be an active verified connection for the team and
the operator's API URL/App ID; legacy installation IDs cannot authorize access.
It also checks that GitHub resolves the repository to the requested installation
before issuing a token. No active connection returns 400, and a mismatched
connection returns 403. GitHub lookup, token, and permission failures return an
error instead of falling back to another connection. The requested commit/ref is
preserved when reading the files.

`GET /teams/by-installation/:installationId` resolves the owning team through
`TeamDao.getTeamByInstallationId`. The lookup joins the team to an active
verified connection matching the installation ID and the operator's API URL/App
ID. The endpoint normalizes and validates the operator settings before the
query. It returns 404 when no active connection matches and 500 for configuration
or database failures. Legacy `Teams.installationIds` never determine ownership,
so webhook planning can resolve teams that only have a new verified connection.
The existing authentication rules and Team response format are preserved.

`GET /teams/:id/workflows` checks team membership and active connections for the
operator's API URL/App ID before contacting GitHub. It resolves the repository's
installation and requires that exact connection before issuing a token and
querying `.openci` through GraphQL. No active connection returns 400; a different
installation returns 403. Legacy IDs and other connections cannot be used as a
fallback after a GitHub failure. The requested branch and YAML file response
format are preserved. A missing workflow tree still returns an empty list, but
GraphQL responses containing permission errors are rejected.

`GET /builds/:id/token` applies the connection checks to saved jobs, including
calls authenticated with the internal API key. The job's installation ID must
belong to an active connection for its team and the operator's API URL/App ID.
GitHub must also resolve the job's repository to that installation before token
issuance. Missing or invalid installation IDs return 400, and unverified or
mismatched connections return 403. Configuration, database, and GitHub failures
return errors; the endpoint never substitutes a dummy token. Successful token
responses use `Cache-Control: no-store`. GitHub requests use the operator's
normalized API URL, not the URL stored in the job.

`GET /builds/:id/secrets` performs the same checks before issuing a token,
fetching workflow files, or reading team secrets. Internal API key callers also
require an active verified connection and a matching repository installation.
Legacy, missing, suspended, removed, or mismatched connections cannot authorize
secret access. Configuration, database, and GitHub failures return errors without
dummy credentials; empty GitHub tokens are rejected. Responses containing
credentials use `Cache-Control: no-store`. Workflow refs, Dart secret definitions,
and YAML secret extraction keep their existing behavior.

`POST /builds/:id/check-run` checks the saved job's active verified connection
and repository installation before issuing a token and updating its GitHub
check. This also applies to internal API key callers. Missing or invalid
installation/check IDs return 400, and unverified or mismatched connections
return 403. The update uses the operator's normalized API URL. GitHub lookup,
token, and update failures return errors instead of success. The shared check
update method no longer skips installation ID `12345678` or uses dummy tokens;
it rejects empty tokens before sending an update.

`POST /builds/:id/runs` also requires the saved job's active verified connection
and matching repository installation before starting or restarting a GitHub
check. Missing/invalid installation IDs, invalid saved check IDs, and a missing
commit SHA for a new check return 400. Connection mismatches return 403, including
internal API key requests. GitHub failures return an error and roll back the new build run,
run count, and saved check ID. Duplicate run IDs still return 409 without
creating another check. Check creation uses explicit operator settings and
rejects empty tokens. Check creation/update has a 10-second timeout so a stalled
GitHub request releases the database transaction. The transaction cannot undo a
GitHub check that was already created if a later database write fails.

Queued check creation also requires the job's active verified connection and
matching repository installation. It uses the same normalized operator API URL
for connection lookup and GitHub requests, and no longer skips installation ID
`12345678`. Missing job metadata, unverified connections, GitHub errors, and
timeouts propagate to the caller. In webhook completion, the existing
transaction rolls back the task's completion and all newly inserted jobs if any
check fails. Repository lookup and check creation each have a 10-second timeout.
Checks already created on GitHub cannot be rolled back with the database, so a
failed batch or lost response can leave a GitHub check without a saved job.
An existing saved check is left unchanged by this creation helper.

`POST /builds/:id/status-change` verifies each affected job's active connection
and repository installation before automatically cancelling or skipping its
GitHub check. Matrix and dependency queries are limited to the source job's
team. GitHub requests use the operator's normalized API URL/App, not the source
job's installation, legacy team IDs, or a saved job URL. An existing check with
missing or invalid metadata is an error; a job without a check needs no GitHub
request. Failed verification or GitHub requests return a generic 500 after local
cancellation and recursive skipping finish. These local state changes are kept
so an external failure does not allow dependent jobs to run. Failed GitHub check
updates are not automatically retried or rolled back with local state.

`POST /builds` still requires a valid internal API key. Before registering a
job, it requires a team and an active verified connection for the operator's
normalized API URL/App. It asks GitHub for the repository's installation and
requires a matching connection, then saves that installation ID with the job.
Caller-supplied installation/check IDs and legacy team IDs do not authorize
registration. The saved repository URL also comes from the operator's settings.
A missing team returns 400; no active connection or an installation mismatch
returns 403. Configuration, database, and GitHub failures return a generic 500
without registering the job. This endpoint does not create a queued check;
the existing build-start path verifies the saved connection again.

`GET /webhooks/tasks/:id/changed-files` still requires a valid internal API key.
It resolves the stored webhook's installation to a team through an active
verified connection for the operator's normalized API URL/App, then checks that
GitHub reports the same installation for the repository before issuing a token
or fetching the diff. Legacy team IDs alone cannot authorize this request.
Missing/inactive connections and repository installation mismatches return 403.
Invalid stored repository/installation metadata, configuration or database
failures, and GitHub request failures return a generic 500. Authentication,
permission, timeout, and malformed-response errors do not become successful
indeterminate results. Legitimate diff limitations, such as a new branch or
file-count limits, still return an indeterminate result for a verified
repository. The task state is not changed by this read endpoint.

`GitHubService` no longer manufactures tokens or sample workflows/files for
installation ID `12345678`, the placeholder App ID, or `mock-` tokens. Token
issuance requires the configured GitHub App credentials and propagates GitHub
failures. Workflow and OpenCI file reads contact GitHub even for those former
test values, so they cannot bypass file-access errors. Tests supply mock HTTP
responses explicitly; these shortcuts are not part of runtime behavior.

Other API and CI consumers will switch in follow-up changes. Production cutover
still requires existing teams to reconnect (G-1379).

A unique constraint on `(github_api_base_url, github_app_id, installation_id)`
reserves an installation for one team, including suspended or removed rows.
Renaming an account does not change that identity. A team can have multiple
connections, and deleting the team cascades to its connection rows.

The migration creates an empty table and leaves `Teams.installationIds` intact.
Legacy IDs, including duplicates across teams, are not evidence of verified
connections and are not copied into the new table. G-1379/G-1380 will migrate
legacy links and finish switching the remaining API and CI consumers.

Run the SQLite storage and migration tests with:

```sh
dart test test/lib/github/github_connection_table_test.dart \
  test/lib/github/read_active_github_connections_test.dart \
  test/lib/github/persist_github_connection_test.dart \
  test/lib/github/save_github_connection_and_consume_session_test.dart \
  test/lib/github/save_github_connection_test.dart test/lib/database_test.dart
```

The PostgreSQL integration test runs the same table constraints plus a v27 → v28
migration, the fresh verification/persistence flow, and the save helper tests
with concurrent saves over independent database connections, plus active
connection reads. GitHub responses are mocked for both database suites;
these do not replace live GitHub.com/GHES
validation. It creates and removes a unique schema for each test.
Use a disposable local PostgreSQL database, for example:

```sh
docker run --rm -d --name openci-github-db-test \
  -e POSTGRES_PASSWORD=openci-test -e POSTGRES_DB=openci_test \
  -p 127.0.0.1:55432:5432 postgres:16-alpine
OPENCI_TEST_DATABASE_URL='postgresql://postgres:openci-test@127.0.0.1:55432/openci_test?sslmode=disable' \
  dart test integration_test/github_connection_database_test.dart
docker stop openci-github-db-test
```

Wait until PostgreSQL is ready before running the test. Without
`OPENCI_TEST_DATABASE_URL`, the integration test is skipped.
