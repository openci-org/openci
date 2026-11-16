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
   and team. Re-read the GitHub user and active installations of the configured App.
   Enumerate `GET /user/installations/{installation_id}/repositories` with the user
   token and retain repositories with `permissions.push === true` (Write, Maintain,
   or Admin). Read/Triage and missing permission metadata are excluded. Organization
   ownership is not required; outside collaborators and collaborators on personal
   repositories are supported. This endpoint intersects user and App access.
   `GetUnavailableGitHubRepositories` hides other teams' repository claims and
   legacy installation-wide claims, including suspended/removed claims. Recheck
   the FSC session after fetching and filtering candidates.
4. `confirm`: repeat live GitHub verification and match both installation and
   repository IDs. FSC rechecks membership, session ownership/expiry, and legacy
   installation claims, then consumes the session and saves the repository claim
   atomically. The unique host/App/repository key prevents competing teams from
   claiming the same repository, including after transfers. Distinct repositories
   in one installation can belong to different teams. Client-supplied names,
   account information, host, and App identifiers are never trusted.

The Dashboard lists `owner/repository` and connects only the selected repository.
New confirmations always require a positive repository ID. A cached old client
cannot create an installation-wide connection by omitting it.

Existing owner-verified connections retain a null `repositoryId` and their original
installation-wide scope. A Write user's confirmation creates/refreshes a separate
repository row without reactivating or modifying that legacy grant. A legacy
installation claimed by another team still blocks its repositories; migrating
existing organization-wide connections to individual repositories is separate work.

The planner resolves the repository claim before fetching workflow files and only
falls back to a legacy connection if no repository claim exists. Inactive or
transferred claims cannot fall back to broader access. FSC verifies the repository
again when creating jobs/PR planning fences. Jobs pin the repository ID; executor
and queued-check lookups match it and installation tokens are restricted to it.
Live metadata checks reject a different repository reusing an old name. Legacy
jobs without an ID can only use legacy installation-wide connections.

The Dashboard binds calls to the initiating profile, account and team, and
rejects stale calls/results after a context change. Callable errors contain no
SDK exception bodies, access tokens, authorization codes or references. Redirects
use the existing `access_denied`, `invalid_callback`, `invalid_state`, `forbidden`
and `connection_failed` error codes. Configuration errors return a generic 503.

GitHub requests use the existing `@octokit/request` dependency with per-request
ten-second timeouts and redirects disabled. Page URLs are constructed from the
operator's API URL, never from GitHub Link headers. Up to 1,000 installations and
1,000 repositories per installation (at most 1,000 eligible repositories overall) are enumerated; rate limits and
incomplete/changing pages fail without returning a partial list.
`@octokit/oauth-methods` does not currently forward `code_verifier`,
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
Functions use 256 MiB, 1 CPU, concurrency 1, min instances 0 and a five-minute
timeout. The callback is publicly invokable; callable requests require Firebase
authentication. Local Dashboard mode uses the Functions emulator on port 5001.

Deploy in this order:

1. Take a database backup and review the SQL diff. Add the nullable repository
   columns and host/App/repository unique key, then apply
   [the scoped SQL migration](../dataconnect/migrations/20261116_repository_connections.sql)
   to remove the superseded installation key. SQL Connect rejects additional
   unique indexes even in COMPATIBLE mode, so do not add a partial unique index
   for legacy rows. The migration also removes that index if an earlier attempt
   created it. Existing null-ID connections and job history are retained; no
   connection rows are modified. Validate the transaction with ROLLBACK before
   committing, then deploy the FSC schema and `github`, `webhooks`, and `dispatch`
   connectors. Confirmation requires a positive repository ID, so new callers
   cannot create installation-wide rows.
2. Deploy the Dart planner and the Node consumers/Cloud Run executor using the
   new connector operations, before enabling new repository confirmations.
3. Deploy the GitHub connection Functions and then the Dashboard. Existing
   configuration, App permissions, and callback URLs do not need to change.
4. Verify a non-owner with Write access can select and connect the intended
   repository and run its CI. Verify Read/Triage denial, revoked permissions
   between listing/confirmation, other-team conflicts, and a sibling repository
   remaining unconnected. Production IAM/OAuth and deployment need live checks.

Old installation-only planner/executor lookups explicitly exclude repository
rows, so mixed versions fail closed for new connections. Old confirmation
clients fail because repository identity is now required. Do not roll back the
connector scope guards while repository rows exist, or restore the former
installation-unique constraint without a reviewed data migration. This source
change performs no live deployment or GitHub App configuration changes.

## Validation

Run Firebase formatting/lint/type checking and Functions tests, FSC GitHub,
planning, execution and check emulator suites, Dart planner analysis/tests,
Dashboard analysis/tests and both GitHub browser tests, and shared-model checks. Local tests mock
GitHub and Secret Manager; production IAM/OAuth and native browser-return
behavior need separate live verification.

References: [GitHub user access token flow](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app),
[Secret Manager expiration](https://docs.cloud.google.com/secret-manager/docs/creating-and-managing-expiring-secrets).
