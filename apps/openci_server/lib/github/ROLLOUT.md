# GitHub connection cutover

G-1379 prepares existing teams for G-1380's verified-connection checks. Complete
this before deploying those checks to a server that still uses legacy
`Teams.installationIds`. G-1381 records Web/GitHub.com validation; G-1379 and the
production release work record the shared-server cutover decision. GHES
validation is pending separately in G-1392.

The [2026-10-19 validation record](#5-validation-record-2026-10-19) covers an
isolated GitHub.com environment. Client-team migration, GHES, and native clients
are deferred. This validation does not authorize the shared production cutover.

## 1. Inventory the running server

Use the running server's normalized `GITHUB_API_BASE_URL` and `GITHUB_APP_ID`,
not settings from a developer's checkout. Inspect its PostgreSQL database inside
a `BEGIN READ ONLY` transaction and finish with `ROLLBACK`.

For every team, record privately:

- Whether legacy installation IDs are missing, malformed, duplicated within the
  team, or shared with another team.
- Whether each expected installation has an `active` row in `github_connections`
  for this team and the operator's API URL/App ID. A row for another App or host
  does not count.
- Whether a current team member can complete GitHub Connect for the intended
  GitHub account.
- Recent CI use and `WAITING`, `QUEUED`, or `IN_PROGRESS` jobs whose saved team and
  installation lack a matching active connection. Include teams without legacy
  IDs: they may still have saved jobs or retries.
- Pending/processing webhook tasks that could resume after the cutover.

Keep team/account identifiers and operational details in the restricted
operator record. Put only aggregate counts, readiness, and blockers in Linear.
Do not query temporary OAuth tokens or secrets for this inventory.

## 2. Reconnect through the Dashboard

Keep the connection-capable release available while existing teams reconnect.
For each team needing a connection, a legitimate team member who owns the
personal GitHub account or administers the organization must:

1. Select the intended OpenCI team and click **Connect GitHub** on Web.
2. Complete GitHub authorization and return to the Dashboard.
3. Select the intended GitHub account and explicitly confirm the connection.
4. Check that the matching active row was saved for the team's operator API URL
   and App ID, then verify repository access.

If the intended account is absent, stop that team's reconnection. Check the
signed-in GitHub account, App installation, organization ownership, and approval
of the App's **Members: read** permission. A different candidate is not a
substitute. Resolve any installation ownership conflict through the responsible
team; do not delete or transfer the connection to bypass it.

Never copy legacy IDs into `github_connections` or edit verification metadata
to mark a team ready. A saved row alone is not proof of live CI compatibility.

## 3. Cut over and verify

G-1380 applies to the whole server; there is no per-team compatibility switch.
Do not deploy it while an actively used team's reconnection is incomplete.
Teams intentionally left unconnected cannot use GitHub-backed operations or
retry their old jobs; explicitly record that decision with the operator.

Before deployment, record the reviewed release/image, operator configuration,
database backup and restore procedure, and rollback target. Pause new CI intake
and drain or explicitly account for queued/running work and pending webhooks.
Deploy only after the required teams have reconnected and release checks pass.

At deployment, repeat G-1381's Web authorization/confirmation and
repository/branch/workflow checks using the deployed release. Resume CI
processing for a controlled PR and push validation, and pause it again if
validation fails. Verify that unconnected or mismatched teams are denied.
Record results per rollout team; successful CI
on the old release does not validate the new checks. Resume normal operation
after validation. Keep legacy columns intact; deleting them is not a cutover
requirement.

## 4. Recover without restoring legacy trust

If validation fails, pause affected GitHub/CI operations and retain the database
and sanitized failure evidence. Correct the configuration/connection or deploy
a tested release that retains the verified-connection checks. An older image
that trusts legacy IDs is not a safe rollback target. If no compatible release
is available, keep those operations paused while preparing a fix.

Do not clear verified rows or restore a pre-reconnection database just to make
requests succeed. If database recovery is necessary, restore to an isolated
database first, reconcile connections and work created since the backup, and
revalidate access before resuming traffic. Never add a legacy-ID or dummy-token
fallback during recovery.

## 5. Validation record: 2026-10-19

G-1381's current scope is Web and GitHub.com using an operator-owned test team
and repository. GHES (G-1392), iOS/macOS (G-1391), and client-team migration
(G-1379) remain separate. No client organization, production database, or
production GitHub App webhook configuration was changed for this validation.

### Real GitHub and CI verification

The live flow used source `b312df5728e7fd2f835b17aab89fb6da911b2892`, a local Web
Dashboard/server, a fresh PostgreSQL database, and Firebase Auth Emulator.
GitHub OAuth, installation access, and Checks API calls used the real GitHub.com
App. A dedicated planner/worker and Orchard controller ran real macOS VMs.

- Web authorization, return, candidate selection, explicit confirmation, and
  the completion message succeeded for an operator-owned organization.
- Repository access returned 400 before connecting and 200 afterward. Branch
  and workflow-file retrieval also succeeded.
- The connection was `active`, legacy `installationIds` stayed empty, and
  confirmation consumed the pending session and cleared its temporary token.
- The controlled [verification PR #3339](https://github.com/openci-org/openci/pull/3339)
  and push used commit `7e4edb2eab766760f38705e116b1e6e5c5a748a4`.
  Both CI runs finished successfully; each VM passed the 18 shared GitHub
  connection API tests. GitHub check `external_id` values matched the isolated
  database's job IDs.

| Trigger | GitHub result |
| --- | --- |
| Pull request | [Successful check](https://github.com/openci-org/openci/runs/117808187541) |
| Push | [Successful check](https://github.com/openci-org/openci/runs/117808201368) |

Real webhook payloads were retrieved from GitHub and replayed into the isolated
receiver with a temporary signing secret. This verifies processing through the
planner, worker, token/secrets APIs, and GitHub check completion. It does **not**
verify direct GitHub delivery to a newly deployed public endpoint.

The verification PR was closed without merging. Temporary branches, VMs,
database/auth containers, and dedicated processes were removed. The original
local server was restored. The check results remain available at the links above.

### Existing tests and privacy review

The following checks passed on merged develop commit
`7c3993179062662a8fa684fc7753e25dc78c7de0`. Its only tracked difference from the
live-verification source is the server CI command change from `flutter test` to
`dart test`. No new integration-test framework or test files were added.

| Area | Evidence and result |
| --- | --- |
| Server: 788 tests | GitHub helpers, callback, connection APIs, middleware, build token/secrets, and OpenCI files passed. Covers cancellation, expiry, replay, wrong user/team, revoked authority, suspended/removed connections, GitHub failures, and preservation of an existing connection after failure. |
| Web: 106 tests in Chrome | GitHub connection tests and router tests passed. Covers starting/returning, identity/profile changes, empty candidates, installation guidance, retry, explicit confirmation, duplicate-click prevention, and completion. |
| Shared API: 18 tests | Typed session/candidates/confirmation responses and error propagation passed; reference is sent in the JSON body. |
| Static analysis | `dart analyze --fatal-infos apps/openci_server apps/dashboard packages/openci_shared` reported no issues. |

The existing HTTP callback test confirms that the Dashboard request receives no
reference query/fragment and that responses use `no-store` and `no-referrer`.
Middleware and failure tests check that callback code/state and credentials are
not logged. Chrome tests confirm that the browser URL/history entry is cleared
and the login redirect contains only the return path. Source review confirms
that capture runs before routing/Sentry initialization; the Web entry HTML does
not initialize a separate analytics SDK. Browser storage retains only initiating
context, not the reference or GitHub token.

Reproduce the focused checks after resolving the workspace with `flutter pub get`:

```sh
# From apps/openci_server
dart test test/lib/github test/routes/github \
  'test/routes/teams/[id]/github' test/routes/_middleware_test.dart \
  'test/routes/builds/[id]/token_test.dart' \
  'test/routes/builds/[id]/secrets_test.dart' \
  'test/routes/teams/[id]/repositories/[repo]/openci-files_test.dart'

# From apps/dashboard
flutter test --no-pub --platform chrome test/team/*github*test.dart \
  test/router/router_test.dart

# From packages/openci_shared
dart test test/api/github_connection_api_test.dart
```

### Configuration and deployment boundary

Configuration names and wiring were checked against the server helpers and
root `docker-compose.yml`. The real OAuth/CI flow above exercised the isolated
environment's settings. Production values must be checked at deployment.

| Setting | Required configuration |
| --- | --- |
| `GITHUB_API_BASE_URL`, `GITHUB_APP_ID` | GitHub.com API (`https://api.github.com`) and the same App used for authorization and installation access. |
| `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET` | OAuth credentials for that App; keep the secret on the server. |
| `GITHUB_OAUTH_REDIRECT_URI` | Server `/github/callback`, registered in the App's callback URLs. |
| `GITHUB_CONNECTION_RETURN_URL` | Web Dashboard `/github/connection`; fixed server setting without query/fragment. This is distinct from the OAuth callback. |
| `GITHUB_APP_INSTALLATION_URL` | Optional App installation page used by empty-candidate guidance. |
| `GITHUB_PRIVATE_KEY_PATH`, `GITHUB_WEBHOOK_SECRET` | App signing key mounted in the server and the webhook signature secret. |
| `SECRET_ENCRYPTION_KEY` | Server encryption key used to save/read temporary OAuth tokens. |
| App permissions | Organization **Members: read** for owner verification; repository **Contents: read**, **Pull requests: read**, and **Checks: write** for CI. Existing installations must approve added permissions. |

Repository permissions correspond to GitHub's
[contents](https://docs.github.com/en/rest/repos/contents#get-repository-content),
[pull-request files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files),
and [check-run](https://docs.github.com/en/rest/checks/runs#create-a-check-run)
endpoints. Organization membership verification is described in the
[authorization README](README.md#github-installation-authorization).

Use HTTPS outside localhost. Check the Dashboard origin against the server CORS
policy. Client-side profiles must point to the same server/Firebase project that
started the connection.

The remaining release checks are specific to the deployed environment:

- Direct webhook delivery to the public server, followed by one controlled
  PR/push CI run on that release.
- Public proxy/access logs and deployed telemetry must not retain callback
  queries or credential-bearing bodies. The app tests above do not inspect
  external proxy or telemetry storage.
- Shared-server cutover still requires section 3's inventory, reconnection,
  drain/backup, and recovery decision. Deferring client migration does not make
  the whole server ready for enforcement.

GHES and native-client behavior are unverified and excluded from this record.
