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
GitHub API failures, including 403/404 membership responses, throw sanitized
exceptions instead of authorizing a connection. Each API operation is bounded by
a 10-second timeout; installation pagination shares its own 10-second budget.

Call this immediately before saving a connection. It does not persist a team
connection or replace OpenCI authentication, team membership checks, or binding
the completion session to the user who initiated it.

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

This implements the server's success redirect. The Dashboard receiver and
redirects for denied or failed authorization are follow-up work. The receiver
must read and remove the fragment before login redirects or analytics run, then
authenticate the initiating user through the server before continuing. Do not
use a route that copies the reference into a login redirect's query string.
