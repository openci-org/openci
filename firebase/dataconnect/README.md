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
workflow reporting table. See [the schema inventory](SCHEMA.md) for source
mappings, Secret Manager references, billing uniqueness keys, and the write
rules required before switching the servers to SQL Connect. Connector operations
cover `GetMyTeams`, `CreateBillingPeriod`, Stripe Customer/Checkout/state/event
operations, and CI admission/execution operations described below.

## Flutter SDK

`teams/connector.yaml` generates the three team operations into
`apps/dashboard/lib/generated/teams`. Dashboard uses `firebase_data_connect`
`0.4.1`. Team lists use `GetMyTeams` through the generated SDK, with the selected
connection's Firebase app and authentication. Local development uses the Auth
Emulator host and SQL Connect port `9399` configured in `firebase.json`.

Team creation and renaming still use the existing REST API. Switch those writes
to SQL Connect before releasing the new list reader, so reads and writes use
the same database. Team deletion remains part of the billing migration.

Regenerate from the repository root with Firebase CLI 15.25.0:

```sh
cd firebase/dataconnect
firebase dataconnect:sdk:generate --project demo-openci
cd ../..
dart format apps/dashboard/lib/generated/teams
```

Generation uses the local schema and does not deploy it. The generated
`TeamsConnector.instance` uses the default Firebase app's project at runtime.

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
Stripe API calls and Functions integration remain follow-up work. The team
existence check is not a replacement for the legacy team/account row locks;
coordinate team deletion when implementing that workflow.

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
does not close the intent. Functions/Stripe integration and team-deletion
coordination are pending; the new operations do not switch production billing
traffic.

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

Functions integration remains pending: authenticate workers; select the verified
paid or complimentary period and Stripe mode; choose server timestamps and IDs;
select jobs with worker-capacity/queue ordering; assign run display numbers; and
coordinate team deletion, job completion, GitHub status updates, and recovery
scheduling. The selected-job claim is atomic, but a fleet-wide scheduler is not
implemented here. Trial claims and their activation routes remain untouched.

## Secrets

`schema/secret.gql` defines `secret_references`: team, name, timestamps, and
`secretVersionPath` (`projects/{project}/secrets/{secret}/versions/{number}`).
The value belongs in Secret Manager. Numeric versions let the server publish a
new value by updating the reference after the version has been created.

Only the server will write these references and access values after checking
team/build permissions. No connector operations expose this table yet.
The existing encrypted `secrets` table remains separate; switching the server,
copying existing values, and cleaning up Secret Manager versions on update or
team/secret deletion are follow-up work.

GitHub OAuth requests and sessions follow the same policy: PKCE verifiers and
access tokens live in Secret Manager. `schema/github.gql` stores version paths
and state/reference hashes, with no plaintext or encrypted token columns.

## Local validation

Use Firebase CLI 15.25.0. From the repository root:

```sh
cd firebase/dataconnect
firebase emulators:exec --only dataconnect --project demo-openci 'true'
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
