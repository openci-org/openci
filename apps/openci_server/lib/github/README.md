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

`fetchGitHubConnectionCandidates`, in the same library, fetches the current user
and installation list once per call, then applies the same connection rules to
every installation. It returns an immutable list of eligible installations;
an empty list means no eligible candidates were found. Each organization
membership request has its own 10-second timeout. If any GitHub request or
verification fails, the call throws a sanitized exception instead of returning
partial results. User and installation-list fetches retain their separate
10-second limits.

This helper does not read a connection session or expose an HTTP endpoint yet.
The candidates API must authenticate and bind the session before using its
decrypted token, and return only the fields needed for selection. Selecting a
candidate still requires fresh `verifyGitHubInstallation` checks immediately
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
`Referrer-Policy: no-referrer`. The Dashboard receiver, installation candidates,
and explicit connection confirmation remain follow-up work.
