# Team management

Team membership is owned by Firebase SQL Connect (FSC). Dashboard team listing,
creation and rename already use the generated `teams` connector. This change
moves member profiles and additions to the `teamManagement` callable Function,
connects member removal to FSC, and moves CLI team listing to the callable.

| Operation             | Entry point                                        | Authorization                                                                                |
| --------------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Dashboard team list   | `GetMyTeams`                                       | Nonanonymous Firebase user, filtered by `auth.uid`                                           |
| Initial team creation | `CreateTeam`                                       | Creates the team and caller membership in one transaction; rejects reused billing identities |
| Rename                | `RenameTeam`                                       | Current team member                                                                          |
| CLI team list         | `teamManagement`, `action: list`                   | `GetMyTeams` with the verified caller's auth claims                                          |
| Member profiles       | `teamManagement`, `action: members`, `teamId`      | FSC membership before and after Firebase Auth lookup                                         |
| Add registered member | `teamManagement`, `action: add`, `teamId`, `email` | Email lookup after membership check; `AddTeamMember` rechecks membership atomically          |
| Remove another member | `RemoveTeamMember`                                 | Current member; self-removal rejected; team row serializes membership changes                |

The callable accepts neither a caller UID nor an arbitrary target UID for an
addition. It resolves a trimmed, lowercased email using Firebase Auth and rejects
missing or disabled accounts. Existing membership is reported as `already-exists`.
This is immediate addition of an already registered account, not an email
invitation; no email is sent and no Firebase Auth account is created.

Member profiles contain only UID, email, display name and photo URL. Missing Auth
accounts remain visible by UID so their stale membership can be removed. Lookups
use batches of at most 100 IDs, restore membership order, and omit removed members
after a fresh authorization check. Raw Auth/FSC errors and user records are never
returned. See [Firebase Admin user lookup](https://firebase.google.com/docs/auth/admin/manage-users#bulk_retrieve_user_data).

Dashboard calls use the active connection's Firebase app and reject stale calls
and results after authentication/connection changes. The removal dialog captures
the initiating client before confirmation. CLI `login`, `list teams`, `switch team`
and `status` use the selected profile's Firebase project, region and token; credential
refresh, sorting and profile-change checks remain in place. The HTTP callable
transport is shared with Secrets and never follows redirects.

## Deployment and remaining migration

Deploy the existing `teams` connector operations and the `teamManagement` Gen2
Function in `asia-northeast1`. No new schema or operation is required. The Function
uses 128 MiB, one CPU, concurrency one, min instances zero and a 60-second timeout.
Its runtime identity needs FSC execution/impersonation access and Firebase Auth
user read access. It does not need Secret Manager access. Local mode uses the
Functions emulator on port 5001 and FSC on port 9399.

**Team deletion remains with the billing migration**, including live Stripe
subscription/Checkout verification and credential cleanup. `DELETE /teams/:id`
and its shared client method are retained. This change removes legacy
`GET /teams`, `POST /teams`, `PATCH /teams/:id`, and member list/add endpoints.

The remaining legacy billing, repository and workflow endpoints still authorize
against their SQL membership tables. FSC membership changes are not mirrored
there. Therefore deploy the final client cutover together with migration or
retirement of those legacy authorization paths; otherwise adding/removing a
member can leave different permissions between old and new endpoints. The former
one-time team import is not continuous synchronization. Do not claim a production
cutover based only on this source change.

No production deployment, membership import or Auth/IAM validation has been
performed. Keep the old client/server release available until the remaining
consumers are ready. The legacy team tables/DAOs remain for those consumers.

## Validation

Run Firebase Functions lint/type checking and tests, then the FSC teams emulator
suite in `firebase/dataconnect/test/teams.test.mjs`. The latter covers real SDK
authorization, duplicate addition, lookup-time revocation, concurrent removals,
creation/rename and more than 100 members. Run Dashboard analysis, provider/API/
widget tests and web build, plus CLI, shared and server analysis/tests after
retiring the old endpoints. Firebase Auth calls are mocked in local tests;
deployment credentials and live Auth access need separate validation.
