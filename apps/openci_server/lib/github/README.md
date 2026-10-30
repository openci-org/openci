# Legacy GitHub server support

The OAuth connection flow has moved to Firebase Functions and SQL Connect.
See [the active implementation and cutover guide](../../../../firebase/functions/GITHUB_CONNECTION.md).
The old `/github/callback` and `/teams/:id/github/{connect,session,candidates,confirm}`
endpoints are removed. Dashboard uses the `githubConnection` callable and the
`githubConnectionCallback` HTTP function.

The helpers and tables below remain for legacy data/test fixtures and the
server's remaining repository/branch/workflow APIs. Their direct database writes
are not the new connection path; new connections are verified and saved by the
FSC `ConfirmGitHubConnection` transaction.

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

`GET /builds/:id/secrets` has been removed. The Cloud Run executor obtains
team secret references from FSC and reads their values from Secret Manager.
Client management uses the authenticated `teamSecrets` callable. See the
[Logs and Secrets cutover guide](../../../../firebase/functions/LOGS_AND_SECRETS.md)
for deployment order and importing existing encrypted values.

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

Before production cutover, follow the [existing-team reconnection and rollout
procedure](ROLLOUT.md) (G-1379/G-1381).

A unique constraint on `(github_api_base_url, github_app_id, installation_id)`
reserves an installation for one team, including suspended or removed rows.
Renaming an account does not change that identity. A team can have multiple
connections, and deleting the team cascades to its connection rows.

The migration creates an empty table and leaves `Teams.installationIds` intact.
Legacy IDs, including duplicates across teams, are not evidence of verified
connections and are not copied into the new table. Existing teams reconnect
through GitHub Connect before G-1380's consumer checks are deployed.

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
