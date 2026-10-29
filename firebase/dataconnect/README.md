# Firebase SQL Connect schemas

This directory has its own Firebase configuration, separate from Hosting.

- `schema/schema.gql` maps the existing `teams` and `team_members` tables.
- `teams/queries.gql` defines `GetMyTeams`. It requires a non-anonymous Firebase
  user and filters membership by `auth.uid`.
- `teams/mutations.gql` adds `CreateTeam` (team and own membership in one
  transaction) and `RenameTeam` (members only).
- Text IDs, Unix-second timestamps (`bigint`), and membership IDs (`bigserial`)
  retain their existing storage types. GitHub installations belong to
  `github_connections`; `Team` no longer exposes `installationIds`.
- Explicit `limit: null` preserves the existing API's full team/member lists.

All 19 migration-target tables are now defined, including the pending skipped
workflow reporting table, plus two new build log/step tables. See
[the schema inventory](SCHEMA.md) for source mappings, Secret Manager references,
billing uniqueness keys, and the write rules required before switching the
servers to SQL Connect. Connector operations
cover `GetMyTeams`, `CreateBillingPeriod`, Stripe Customer/Checkout/state/event
operations, and CI admission/execution operations described below.

## Generated SDKs

`teams/connector.yaml` generates all six team operations, including
`GetTeamMembers`, `AddTeamMember`, and `RemoveTeamMember`, into:

- Flutter: `apps/dashboard/lib/generated/teams` (`TeamsConnector`).
- Node.js Admin: `firebase/generated/teams-admin` (`@openci/teams-admin`), linked
  from the `firebase` npm workspace.

`AddTeamMember` is server-only (`NO_ACCESS`), even though it is included in the
Flutter SDK. Its `actorUid` must come from the server's verified caller identity.
Member Functions and Dashboard integration remain separate follow-up work.

Dashboard uses `firebase_data_connect`
`0.4.1`. Team lists use `GetMyTeams` through the generated SDK, with the selected
connection's Firebase app and authentication. Local development uses the Auth
Emulator host and SQL Connect port `9399` configured in `firebase.json`.

New account registration uses the generated `CreateTeam` mutation to create the
initial team and its membership. The user's UID remains the team's ID and name.
Dashboard no longer offers manual creation of additional teams.

Team renaming uses the generated `RenameTeam` mutation and refreshes the team
list after a successful update. Member management still uses the existing REST
API and must move before production cutover so reads and writes use the same
database. Team deletion remains part of the billing migration.

`logs/connector.yaml` generates all seven log/step operations into:

- Flutter: `apps/dashboard/lib/generated/logs` (`LogsConnector`).
- Node.js Admin: `firebase/generated/logs-admin` (`@openci/logs-admin`), linked
  from the `firebase` npm workspace and used with `firebase-admin`.

The Flutter SDK includes the server-only operations, but `NO_ACCESS` still
rejects client calls. Dashboard should use `GetBuildLogs` and `GetBuildSteps`;
Functions use the Admin SDK for writes and recovery reads. Connecting the SDKs
to the UI and Functions remains follow-up work.

`builds/connector.yaml` generates `GetBuildJobs` into:

- Flutter: `apps/dashboard/lib/generated/builds` (`BuildsConnector`).
- Node.js Admin: `firebase/generated/builds-admin` (`@openci/builds-admin`), linked
  from the `firebase` npm workspace.

Admin callers must impersonate the verified user because the query checks team
membership. Dashboard integration and production cutover remain follow-up work.

`secrets/connector.yaml` generates all five secret-reference operations into:

- Flutter: `apps/dashboard/lib/generated/secrets` (`SecretsConnector`).
- Node.js Admin: `firebase/generated/secrets-admin` (`@openci/secrets-admin`),
  linked from the `firebase` npm workspace.

Dashboard uses `GetSecrets` for metadata only. The other four operations are
server-only, even though their methods also appear in the Flutter SDK. Admin
calls to `GetSecrets` must impersonate the verified user for the membership check.

`github/connector.yaml` generates all ten GitHub connection operations into:

- Flutter: `apps/dashboard/lib/generated/github` (`GithubConnector`).
- Node.js Admin: `firebase/generated/github-admin` (`@openci/github-admin`),
  linked from the `firebase` npm workspace.

Only `GetGitHubConnections` is client-accessible, with a team-membership check.
The other nine generated methods require unrestricted Admin access. OAuth and
GitHub API calls belong in Functions, not in these generated SDKs.

`billing/connector.yaml` generates all 33 billing operations into:

- Flutter: `apps/dashboard/lib/generated/billing` (`BillingConnector`).
- Node.js Admin: `firebase/generated/billing-admin` (`@openci/billing-admin`),
  linked from the `firebase` npm workspace.

All billing operations are `NO_ACCESS`, including reads. Generating Flutter
methods does not allow clients to call them. Functions must authenticate the
caller and use the Admin SDK to compute billing status or perform writes.
Stripe calls, worker orchestration, and UI/API integration remain follow-up work.

Regenerate from the repository root with Node.js 22 and Firebase CLI 15.34.2:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.2 dataconnect:sdk:generate \
  --config firebase/dataconnect/firebase.json --project demo-openci
dart format apps/dashboard/lib/generated/teams apps/dashboard/lib/generated/logs apps/dashboard/lib/generated/builds apps/dashboard/lib/generated/secrets apps/dashboard/lib/generated/github apps/dashboard/lib/generated/billing
vp fmt firebase/generated/logs-admin firebase/generated/teams-admin firebase/generated/builds-admin firebase/generated/secrets-admin firebase/generated/github-admin firebase/generated/billing-admin
```

Generation uses the local schema and does not deploy it. The generated
connector singletons use the default Firebase app's project at runtime. The
emulator also regenerates SDKs on startup; run the formatters again afterward.

## Retired features

`invitations`, `user_devices`, and `udid_requests` are retired from the migration
scope. Their schemas, connector operations, and data will not be migrated to SQL
Connect. Cleanup of the existing server APIs, shared models, and legacy database
tables is tracked in [G-1569](https://linear.app/genuineci/issue/G-1569/retire-legacy-invitation-device-and-udid-request-storage)
and has not been implemented yet.

## Billing

`schema/billing.gql`, `schema/billing_stripe.gql`, and
`schema/billing_execution.gql` map all nine billing tables. Text IDs and bigint
allowances retain their existing types. Periods and Stripe timestamps use Unix
seconds; admission/execution timestamps retain milliseconds. Composite
admission/execution foreign keys enforce that the period belongs to the team.

`billing/mutations.gql` defines the server-only `CreateBillingPeriod` operation
(`@auth(level: NO_ACCESS)`). Its five `@check` directives validate the plan,
period type, time range, non-negative allowance, and required paid allowance.
`Int64` values are converted to integers in CEL before numeric comparisons.
The billing account is created if missing, and the period is inserted in the
same `@transaction`. Duplicate period IDs fail without overwriting the existing
period or leaving a newly created account behind.

`BillingPeriod.billingAccount` defines the foreign key using `@ref`. Billing
accounts have no foreign key to teams, so team deletion retains billing history.
Only the account's usage revision is updated; no account/period delete or period
update operation is exposed. Do not physically delete billing
accounts or periods: required `@ref` relations cascade to billing history, while
the optional Stripe paid-period reference would be set to null.

No supplemental SQL migration is required. These validations apply to this
connector operation, not direct SQL or ad hoc administrative mutations. Future
write operations must carry the same checks. The existing servers still use
their current database; routing billing writes through these operations is
follow-up work.

### Context and recovery reads

`billing/context.gql` supplies the reads needed by status, Checkout, Portal, and
webhook Functions:

- `GetBillingContext` verifies the supplied user's membership and returns the
  account revision, Customer intent, Stripe state with its full paid period,
  and open Checkout. Missing billing records are nullable.
- `GetBillingCustomerByStripeId` resolves the Customer in the specified Stripe
  mode. `GetBillingCheckoutCreation` reads an exact team/key/mode combination,
  including closed purchases. Both work after team deletion for webhook recovery.
- `GetBillingPeriod` returns all immutable period fields for the specified team.
  After a duplicate or ambiguous `CreateBillingPeriod`, compare every field
  before treating the operation as successful. This also supports configured
  monthly complimentary periods; Functions chooses their IDs and allowances.

Functions must supply the verified Firebase UID, check Stripe mode, and derive
entitlement and allowance policy from server configuration. These queries do not
call Stripe, compute the public billing-status response, or create Portal URLs.

### Trial persistence

`billing/trials.gql` adds `GetBillingTrialEligibility` and `StartBillingTrial` for
the existing dormant trial feature. The mutation checks membership, rejects an
active paid period, and inserts a seven-day Pro period and its claim in one
transaction. User-primary-key and team-unique constraints permit only one trial
per user and per team, even across concurrent requests. Claims survive deletion.
The nullable allowance must be non-negative when supplied.

On a duplicate or ambiguous response, reread eligibility and the requested
period before retrying. These Admin operations do not enable a trial route, UI,
or trial CI; admission and execution operations still require paid periods.

### Stripe Customer creation

`billing/customers.gql` adds three server-only operations:

- `CreateBillingCustomerCreation` requires an existing team, creates its billing
  account if needed, and inserts an immutable creation intent in one transaction.
  Empty/whitespace-only keys and negative creation times are rejected. Duplicate
  team/key attempts fail without changing the original intent.
- `GetBillingCustomerCreation` reads the stored key and Customer ID, returning
  null if there is no intent. It rejects a missing team or a Stripe mode mismatch.
- `RecordBillingCustomer` sets the Customer ID only when the team, stored key,
  and mode match. Repeating the same ID succeeds; replacing it or assigning a
  Customer already linked to another team fails.

Functions must verify membership and choose the mode, key, and timestamp. Before
calling Stripe, read or create the intent; after a duplicate create or ambiguous
timeout, read it again and use the stored key. Verify the returned Customer's
`metadata.team_id`, `livemode`, and non-deleted status before recording its ID.
Stripe API calls and Functions integration remain follow-up work. Customer
creation and recording share the team-row lock used by `DeleteBillingTeam`.

### Stripe Checkout creation

`billing/checkouts.gql` adds four server-only operations:

- `CreateBillingCheckoutCreation` requires an existing team and billing account.
  It validates the paid plan, nonblank key/Customer/Price/return URLs, and
  non-negative creation time. It derives `openTeamId` from `teamId`; its unique
  constraint allows only one unfinished intent per team, including concurrent
  requests. Duplicate keys or open intents fail without overwriting them.
- `GetOpenBillingCheckoutCreation` returns the unfinished intent, or null if
  absent, and rejects missing teams and Stripe mode mismatches. After a duplicate
  create or ambiguous timeout, use this lookup to recover the stored parameters.
- `RecordBillingCheckoutSession` matches every original parameter and the open
  state in the update itself. The same Session ID can be retried; changed/closed
  intents, replacing the Session ID, and reusing a Session from another intent
  (including closed history) are rejected.
- `CloseBillingCheckoutCreation` checks the recorded Session's identity and close
  time, then sets `closedAt` and clears `openTeamId` together. Retrying or closing
  concurrently preserves the first close time. The closed intent stays in history
  while a new Checkout can reserve the team's slot.

Functions must verify membership, Customer ownership, Price/plan compatibility,
and subscription state before creating a Checkout. Reuse the saved key, Price,
and return URLs when retrying, and resolve a different plan/Customer before
starting another purchase. Before recording a Session, verify its hosted
subscription mode, `livemode`, non-deleted Customer, team metadata/client
reference, and return URLs against that saved intent.

Before closing, Functions must verify an expired/unpaid Session, or a completed
Session whose Subscription is canceled/incomplete_expired. Recording a Session
does not close the intent. Checkout writes share the team-row lock used by
`DeleteBillingTeam`; an open intent prevents deletion. Functions/Stripe
integration remains pending, and these operations do not switch production
billing traffic.

### Stripe state and events

`billing/stripe.gql` adds four server-only operations:

- `InitializeBillingStripeState` inserts an initial `none` state only for the
  account's recorded Customer and mode. Duplicates never overwrite existing state.
- `GetBillingStripeState` returns the current state, paid-period end, and revision.
  `GetBillingStripeEvent` checks whether an event has already committed.
- `RecordBillingStripeEvent` updates the state and inserts the processed event in
  one transaction. Duplicate events or failed checks roll back both writes. The
  update must match `expectedRevision`; a successful update increments it once.

Functions must read the state revision **before** fetching the latest Stripe
data. On a revision conflict, read the new state and fetch Stripe again; do not
reuse an old observation with a new revision. After a duplicate delivery or an
ambiguous timeout, check the stored event before retrying. Event creation time is
not used to order subscriptions: delayed notifications still trigger a fresh
Stripe observation.

Checks reject invalid status/plan combinations, backwards sync times, reviving an
ended subscription, and discarding/shortening the same subscription's verified
paid period. A supplied period must already exist and belong to this team, paid
period type, and plan. Functions must verify Stripe payment evidence before
creating a period and merge retained plan/period or terminal state as the legacy
reconciliation does. This mutation does not create periods or call Stripe.

The new `revision` column starts at `0` for imported/initialized states and
protects simultaneous updates even within the same Unix second. These operations
can process billing history after team deletion. Webhook signature validation,
Customer/team resolution, Stripe verification, and Functions retry orchestration
remain follow-up work.

### Team deletion

`billing/deletion.gql` defines `DeleteBillingTeam`. Functions must read
`GetBillingContext` **before** verifying the Customer has no live Stripe
subscriptions, and resolve any open Checkout with Stripe before closing it.
Pass the observed Customer creation key/ID and Stripe revision to the mutation.

The mutation rechecks membership, Customer identity/mode, terminal subscription
state, and absence of an open Checkout under row locks. Pending Customer creation
or changed state rejects deletion; Functions must read and verify Stripe again.
Team deletion cascades to members, secret references, GitHub metadata, and
skipped reports, while billing and build history survive. Returned Secret
Manager references are cleanup inputs, not proof that credentials were destroyed.

Customer/Checkout creation, trials, CI admission, and deletion lock the Team row
before updating billing data. Stripe state writes lock the billing account;
deletion takes that lock after the Team lock. Explicit `response` bindings make
dependent writes and guard reads execute after acquiring those locks. Keep these
dependencies: independent mutation fields can otherwise share a SQL statement
and its earlier snapshot.

Functions must implement durable Secret Manager cleanup and reconciliation for
lost responses and concurrent secret creation before exposing deletion. This
mutation does not call Stripe or Secret Manager and is not a deletion endpoint.

### CI reservations and execution measurement

`billing/admissions.gql`, `billing/executions.gql`, and `billing/usage.gql` add
eleven server-only operations. This implements paid-period billing storage;
it does not enable a trial or switch the existing workers to SQL Connect.

| Operation                   | Behavior                                                                                                                                                    |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GetBillingPeriodUsage`     | Returns the account revision, allowance, measured/leased/reserved milliseconds, remaining allowance, and incomplete-measurement flag.                       |
| `CreateBillingAdmission`    | Claims a selected queued job and reserves `min(remainingMillis, 60000)` in one transaction. The reservation must start within two minutes.                  |
| `GetBillingAdmission`       | Reads an admission and the account revision for subsequent writes or recovery after an ambiguous response.                                                  |
| `BindBillingAdmissionRun`   | Creates a minimal `BuildRun` and binds both the admission and job to it atomically, before the reservation expires.                                         |
| `StartBillingExecution`     | Starts the bound current run with a one-minute lease. Its reservation is then excluded from pending usage, preventing double counting.                      |
| `GetBillingExecution`       | Reads the measurement and account revision, including an already committed final outcome.                                                                   |
| `HeartbeatBillingExecution` | Advances the observed time and extends the lease to at least one minute after the observation; rejects stale observations and expired leases.               |
| `FinishBillingExecution`    | Records `success`, `failure`, `cancelled`, or `timed_out` and closes the admission in one transaction. It preserves any later observation already recorded. |
| `ExpireBillingExecution`    | Marks an expired lease `abandoned`/incomplete at the last observed time. Unobserved time is not charged. Any open admission is closed.                      |
| `ExpireBillingAdmission`    | Releases an expired, unstarted reservation; requeues only its matching current job attempt and fails its bound unfinished run.                              |
| `GetExpiredBillingWork`     | Returns at most 100 expired executions and 100 unstarted expired admission identities for a recovery sweep.                                                 |

Remaining allowance is `max(0, allowance - measured - leased - reserved)`.
Measurements and leases are clipped to the requested period. Executions and
reservations that originated in another period still contribute when they
overlap. Expired leases/reservations stop reserving allowance. As in the existing
service, an admitted execution may keep renewing its lease after the remaining
allowance reaches zero; the budget controls admission of additional jobs.

The complex interval aggregation and recovery anti-join use
[native SQL](https://firebase.google.com/docs/sql-connect/native-sql) inside the
connector; no separate SQL migration is required. Their `Any` results require
runtime shape validation in Functions. Usage numeric fields are decimal strings
to preserve bigint precision; do not convert them to JavaScript `number`.
Recovery identities contain `id`, `teamId`, and nullable `runId`.

`billing_accounts.usage_revision` starts at `0` for imported accounts. Every
admission/execution mutation increments it in the same transaction as its writes.
Creation compares the revision from the same SQL snapshot as the remaining
allowance. Other mutations require `expectedUsageRevision`; read it before the
call. This serializes usage changes across different jobs of a team and rejects
stale snapshots. A failure rolls back the revision, job/run changes, and billing
writes together. Future usage writers must follow this protocol too.

On conflicts, read current records again and reconsider the action. Creates,
bindings, starts, and terminal transitions do not overwrite existing history;
after a duplicate or ambiguous response, read the saved admission/execution.
Expired heartbeats/finish reports must go through expiration instead of extending
the unobserved interval. Recovery must process executions first, then fetch fresh
revisions for unstarted admissions. It must not continuously retry already
closed/finished records. An already closed or historically absent admission does
not prevent execution expiration.

`billing/jobs.gql` supplies three Admin reads: `GetQueuedBillingJobs` returns
FIFO candidates with `(createdAt, id)` keyset pagination, an excluded-team list,
and pages of 1–100 jobs; `GetBillingWorkerJobs` returns the host's in-progress
jobs; `GetBillingJob` resolves a job's team, worker, and current run. These are
snapshots, not worker-capacity reservations. The scheduler must handle rejected
or already-reserved candidates and advance its cursor accordingly.

Functions integration remains pending: authenticate workers; select the verified
paid or complimentary period and Stripe mode; choose server timestamps and IDs;
select jobs with worker-capacity/queue ordering; assign run display numbers; and
coordinate team deletion, job completion, GitHub status updates, and recovery
scheduling. The selected-job claim is atomic, but a fleet-wide scheduler is not
implemented here. Trial activation routes remain disabled.

Run the billing operations, authorization/concurrency checks, and generated
Admin SDK tests against the local emulator:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.2 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test firebase/dataconnect/test/billing.test.mjs'
cd apps/dashboard
flutter test --no-pub test/generated/billing_sdk_test.dart
```

## Build logs

`schema/build_log.gql` adds `BuildStep` and `BuildLog`, both owned by a `BuildRun`.
Each log is a separate row. Senders may upload multiple logs to Functions in one
request; Functions persist them one at a time.
`(runId, sequence)` orders persisted logs, and `(runId, logId)` prevents duplicate
rows on retries. Step IDs are scoped to a run; logs without a step are allowed.

The `logs` connector provides:

- `GetBuildSteps` / `GetBuildLogs`: non-anonymous team members only. Pages default
  to 100 entries (maximum 200); steps use an offset, logs use the last returned
  entry's sequence as the next cursor, not the run's `lastLogSequence`.
- `CreateBuildStep` / `UpdateBuildStep`: server-only creation and updates.
  Completed steps cannot be overwritten and duration cannot decrease.
- `AppendBuildLog`: server-only insertion of one log with a conditional sequence
  update in the same transaction. A failure rolls back that log and the counter;
  earlier committed logs remain saved.
- `GetBuildLogWriteState` / `GetBuildStepWriteState`: server-only recovery reads.

Each append belongs to one run and one optional step. Sources are
`worker`/`workflow`, streams are `stdout`/`stderr`, and messages allow at most
16 KiB of UTF-8 (empty messages are valid). `occurredAt` comes from the sender;
`createdAt` is server-generated. Int64 values must retain their precision.

Functions must authenticate the worker and verify its run assignment. Before
appending, look up the stable sender-generated IDs with `GetBuildLogWriteState`
and compare saved step/source/stream/message/event-time values, normalizing UUIDs
and timestamps. Reject reused IDs with different payloads; acknowledge saved
entries and assign only missing entries consecutive sequences after
`lastLogSequence`. Append each missing entry with `expectedLastSequence` and
`sequence = expectedLastSequence + 1`. A conflict or ambiguous
response requires a fresh lookup; duplicate appends are not successful no-ops.
Use `GetBuildStepWriteState` to recover duplicate creates or terminal updates.

Expired `logsExpireAt` rejects writes but does not delete rows. Functions retry
orchestration, Functions/UI integration, realtime refresh, and retention cleanup are
follow-up work. Current applications still use Loki.

Run the operation and generated Admin SDK tests from the repository root
against the local emulator (Node.js 22):

```sh
npm ci
env -u DEBUG npx --yes firebase-tools@15.34.1 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test firebase/dataconnect/test/logs.test.mjs'
```

## Secrets

`schema/secret.gql` defines `secret_references`: team, name, timestamps, and
`secretVersionPath` (`projects/{project}/secrets/{secret}/versions/{number}`).
The value belongs in Secret Manager. Numeric versions let the server publish a
new value by updating the reference after the version has been created.

The `secrets` connector provides:

- `GetSecrets`: non-anonymous team members can list names, team IDs, and timestamps
  in name order. An explicit null limit preserves the full list beyond 100 rows.
  Neither values nor Secret Manager paths are returned.
- `GetSecretReference`: server-only lookup of the version path and metadata;
  returns null when the reference is absent.
- `CreateSecretReference`: server-only insert for an existing team. Duplicate
  names within a team fail; timestamps are server-generated Unix seconds.
- `UpdateSecretReference` / `DeleteSecretReference`: server-only writes that
  match `expectedSecretVersionPath` in the write itself. A missing or changed
  reference fails. Updates preserve `createdAt`.

Creation rejects blank names. Both create and update require a positive numeric
version path, not `latest` or another alias; global and regional Secret Manager
paths are supported. The operations store references only and do not call Secret
Manager.

Functions must authenticate callers, check team/build permissions, and derive
the path from the Secret Manager response for that team's secret. A path format
check does not prove resource ownership. Create the Secret Manager version before
publishing its reference. After a conflict or ambiguous response, reread the
reference and reconcile before retrying; never reuse a stale expected path.

The existing encrypted `secrets` table remains separate; switching the server,
copying existing values, and cleaning up Secret Manager versions on update or
team/secret deletion are follow-up work.

Run the operation and generated Admin SDK tests against the local emulator:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.2 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test firebase/dataconnect/test/secrets.test.mjs'
```

GitHub OAuth requests and sessions follow the same policy: PKCE verifiers and
access tokens live in Secret Manager. `schema/github.gql` stores version paths
and state/reference hashes, with no plaintext or encrypted token columns.

## GitHub connections

The `github` connector provides the persistence layer for the existing OAuth
and installation-confirmation flow. It does not call GitHub or Secret Manager.

| Operation                                                                       | Behavior                                                                                                                                                                                   |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GetGitHubConnections`                                                          | Members list their team's connection metadata, ordered by account login and ID, without the default 100-row limit. No credential paths or hashes are exposed.                              |
| `GetActiveGitHubConnection`                                                     | Admin lookup by the exact API host, App ID, and Installation ID. Suspended, removed, and missing connections return null.                                                                  |
| `CreateGitHubConnectionRequest`                                                 | Inserts a member's request with a SHA-256 state hash and numeric PKCE secret-version path. Server timestamps give it a ten-minute lifetime.                                                |
| `ConsumeGitHubConnectionRequest`                                                | Reads and deletes an unexpired request in one transaction; concurrent callbacks have one winner. Returns the verifier path to Functions.                                                   |
| `CreateGitHubConnectionSession`                                                 | Inserts a member's verified GitHub user and numeric token-version path with a SHA-256 reference hash and ten-minute lifetime.                                                              |
| `GetGitHubConnectionSession`                                                    | Admin read restricted to the supplied user/team/hash, current membership, and an unexpired, unconsumed session with a token reference.                                                     |
| `ConfirmGitHubConnection`                                                       | Atomically saves the verified installation and consumes its session, clearing the token reference. Same-team reconnection preserves the connection ID; another team cannot take ownership. |
| `GetExpiredGitHubConnectionCredentials`                                         | Reads the oldest 100 expired requests and 100 expired sessions, including remaining secret paths for cleanup.                                                                              |
| `DeleteExpiredGitHubConnectionRequest` / `DeleteExpiredGitHubConnectionSession` | Delete one expired row after Secret Manager cleanup; active rows and repeated deletes return zero.                                                                                         |

All operations except the member list are `NO_ACCESS`. Functions must derive
`userId` from verified Firebase identity (or the consumed OAuth request), hash
random state/reference values, and supply Secret Manager paths from actual
creation responses. The URL/App ID come from operator configuration, including
canonical URL normalization; syntax checks are not an endpoint allowlist.

Before confirmation, Functions must freshly verify the installation, its active
status, App ID, and the session GitHub user's authority. Account metadata comes
from that verification. The mutation rechecks membership under the same team-row
lock used by member removal and never allows a different team to overwrite the
unique host/App/Installation association. Repository, branch, workflow-file,
installation-token and Check Run API calls still require Functions and live
GitHub authorization; a stored connection is not sufficient by itself.

After a successful callback/confirmation, Functions must destroy the returned
PKCE/token secret version; for expired rows, destroy the secret before deleting
the row. Consumed sessions retain no token path. Secret deletion retries and
orphan cleanup after partial failures, lost responses, or team deletion must be
implemented with Functions. A lost consume/confirm response is not an invitation
to replay OAuth or reuse a session: reconcile the result or restart the flow.
The connector does not implement resource cleanup or deploy the new flow.

Run the generated Admin SDK and authorization/concurrency tests locally:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.2 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test firebase/dataconnect/test/github.test.mjs'
```

## Local validation

Use Firebase CLI 15.34.1. From the repository root:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.1 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci 'true'
```

The emulator uses ports `9399` (Data Connect) and `9939` (PostgreSQL).
Use `--project demo-openci` for local validation to override the cloud default.

## Provisioned service

The default project is `openci-b1b91`, with service `openci-b1b91-service` in
`asia-northeast1`. Its Cloud SQL instance is `openci-b1b91-instance` and database
is `openci-b1b91-database`.

`COMPATIBLE` allows unrelated tables but can still alter mapped tables. Review
`firebase dataconnect:sql:diff --project openci-b1b91` before deployment.

Removing `Team.installationIds` in `COMPATIBLE` mode keeps the legacy
`teams.installation_ids` column and its data, but removes its `NOT NULL`
constraint so `CreateTeam` can omit it. Deploy both the schema and `teams`
connector together. No supplemental SQL migration is needed; see the
[SQL Connect migration behavior](https://firebase.google.com/docs/sql-connect/manage-schemas-and-connectors#use-compatible-mode-when-you-have-production-data-in-your-database).

Dashboard still uses the existing server. The provisioned service contains an
older server's team-data snapshot; current production data has not been migrated
or synchronized to it.
