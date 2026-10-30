# GitHub connection migration

`githubConnection` is a Gen2 callable Function in `asia-northeast1`. The
Dashboard uses the Firebase app for the active connection, a Firebase ID token,
and a team ID. Anonymous users are rejected. The old server's OAuth endpoints
are removed in this release.

## Flow

1. `start`: check FSC membership before creating credentials; generate a random
   state and PKCE verifier. Store the state hash and a Secret Manager version
   reference in `GitHubConnectionRequest` for ten minutes. Return the configured
   GitHub authorization URL with the S256 challenge.
2. `githubConnectionCallback`: accept GET, validate nonduplicate callback
   parameters, and consume state atomically before exchanging the code. Recheck
   team membership, exchange through Octokit with `code_verifier`, verify the
   GitHub user, and create a ten-minute FSC session. The token stays in Secret
   Manager. Redirect to the fixed Dashboard return URL with only an opaque
   reference in the fragment; the Dashboard scrubs it before routing/analytics.
3. `session` / `candidates`: bind the reference to the initiating Firebase user
   and team. Re-read the GitHub user and installations, and show only installations
   of the configured App that are not suspended. A personal account must belong
   to the user; an organization requires active admin membership. Recheck the
   FSC session after fetching candidates.
4. `confirm`: repeat live GitHub verification. FSC then rechecks membership,
   session ownership and expiry, consumes the session, and saves the connection
   atomically. Another team cannot take an existing host/App/installation key.
   A same-team reconnection preserves its connection ID. UI selection supplies
   only an installation ID; the host, App and account facts come from the server.

The Dashboard binds calls to the initiating profile, account and team, and
rejects stale calls/results after a context change. Callable errors contain no
SDK exception bodies, access tokens, authorization codes or references. Redirects
use the existing `access_denied`, `invalid_callback`, `invalid_state`, `forbidden`
and `connection_failed` error codes. Configuration errors return a generic 503.

GitHub requests use the existing `@octokit/request` dependency with per-request
ten-second timeouts and redirects disabled. Page URLs are constructed from the
operator's API URL, never from GitHub Link headers. Up to 1,000 installations are
enumerated; rate limits and incomplete/changing pages fail without returning a
partial list. `@octokit/oauth-methods` does not currently forward `code_verifier`,
so the token exchange uses Octokit's request API directly.

## Temporary credentials

The GitHub vault creates only `openci-github-<uuid>` secrets, labelled
`openci-purpose=github-oauth`, with a 30-minute Secret Manager TTL. Request and
session lifetimes are ten minutes each. Credentials are deleted immediately
after consumption/confirmation where possible; Secret Manager's automatic
expiration also covers a process death or a lost FSC/Secret Manager response.
These are separate from team Secrets and their retention policy.

`cleanGitHubConnectionCredentials` runs every five minutes, processes up to ten
expired requests and ten expired sessions with four concurrent cleanup calls,
and removes each row only after credential deletion succeeds. Missing secrets
are already cleaned. Resource-name and ownership checks prevent cleanup from
deleting team Secrets or another integration's resources. Older credential
references without this prefix/label require operator cleanup; errors retain
those rows for inspection.

## Configuration and deployment

Set these server-controlled variables for the Functions codebase:

| Setting                        | Value                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------ |
| `GITHUB_APP_ID`                | Numeric GitHub App ID, matching the planner/executor                           |
| `GITHUB_APP_CLIENT_ID`         | OAuth client ID of that App                                                    |
| `GITHUB_APP_CLIENT_SECRET`     | Firebase-bound Secret Manager secret                                           |
| `GITHUB_API_BASE_URL`          | Defaults to `https://api.github.com`; GHES uses `https://host[/prefix]/api/v3` |
| `GITHUB_OAUTH_REDIRECT_URI`    | Exact deployed `githubConnectionCallback` URL registered in the GitHub App     |
| `GITHUB_CONNECTION_RETURN_URL` | Dashboard `/github/connection` URL, without query or fragment                  |
| `GITHUB_APP_INSTALLATION_URL`  | Optional App installation URL on the configured GitHub host                    |
| `SECRET_MANAGER_PROJECT`       | Defaults to `GCLOUD_PROJECT`; owns temporary OAuth credentials                 |

Endpoints require HTTPS, except loopback HTTP for emulators. Match the executor's
configured API and checkout hosts when using GHES. Clients cannot override them.
Functions use 128 MiB, 1 CPU, concurrency 1, min instances 0 and a five-minute
timeout. The callback is publicly invokable; callable requests require Firebase
authentication. Local Dashboard mode uses the Functions emulator on port 5001.

Deploy in this order:

1. Deploy the FSC GitHub connector (including `GetGitHubConnectionContext`) and
   confirm the destination has the correct teams/members.
2. Configure the App client secret and variables. Give the runtime identity FSC
   admin access and Secret Manager create, add-version, access, get and delete
   permissions. The vault uses Secret Manager resource expiration, not delayed
   version destruction. Secret Manager does not have a local emulator here.
3. Deploy `githubConnection`, `githubConnectionCallback` and
   `cleanGitHubConnectionCredentials`. Register the new callback URL in the App.
   Keep the old callback registered while the old client/server release is used.
4. Release the Dashboard and verify sign-in → authorization → account selection
   → confirmation against a test team. Verify the saved FSC row creates a build
   through the new webhook/planner/executor path. Test cancellation, replay,
   removal of membership, a suspended installation and a cross-team conflict.
5. Retire the old server OAuth routes and remove its callback URL after in-flight
   authorizations expire. Existing SQL-only connections require reconnection
   through the new flow unless their verified metadata was already migrated to
   FSC. Do not import arbitrary legacy installation IDs as verified connections.

The legacy schema/helper code remains for old data and tests, and the remaining
server repository/branch/workflow APIs still use its database. This change does
not move billing, team management or those legacy browsing APIs. No live
deployment, GitHub App configuration change or data import is performed by the
source change. For rollback, restore the matching client/server release and
callback configuration; connections saved only in FSC are not copied back.

## Validation

Run Firebase formatting/lint/type checking and Functions tests, the FSC GitHub
emulator suite, Dashboard analysis/tests and the two GitHub browser tests, plus
the shared/server suites after removing the old endpoints. Local tests mock
GitHub and Secret Manager; production IAM/OAuth and native browser-return
behavior need separate live verification.

References: [GitHub user access token flow](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app),
[Secret Manager expiration](https://docs.cloud.google.com/secret-manager/docs/creating-and-managing-expiring-secrets).
