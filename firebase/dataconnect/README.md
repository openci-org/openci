# Firebase SQL Connect schemas

This directory has its own Firebase configuration, separate from Hosting.

- `schema/schema.gql` maps the existing `teams` and `team_members` tables.
- `teams/queries.gql` defines `GetMyTeams`. It requires a non-anonymous Firebase
  user and filters membership by `auth.uid`. There are no client mutations.
- Text IDs, JSON-encoded `installation_ids`, Unix-second timestamps (`bigint`),
  and membership IDs (`bigserial`) retain their existing storage types.
- Explicit `limit: null` preserves the existing API's full team/member lists.

All 19 migration-target tables are now defined, including the pending skipped
workflow reporting table. See [the schema inventory](SCHEMA.md) for source
mappings, Secret Manager references, billing uniqueness keys, and the write
rules required before switching the servers to SQL Connect. Connector operations
cover `GetMyTeams`, `CreateBillingPeriod`, and the Stripe Customer, Checkout, and
state/event operations described below.

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
No account/period update or delete operation is exposed. Do not physically delete billing
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

Dashboard still uses the existing server. The provisioned service contains an
older server's team-data snapshot; current production data has not been migrated
or synchronized to it.
