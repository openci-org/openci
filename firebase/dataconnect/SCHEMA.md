# Schema migration inventory

These definitions cover 23 destination tables: the 19 migration-target tables
(the active Dart tables, all seven Go-owned billing tables, and the pending
skipped-workflow report table), plus two new build log/step tables and two
dispatch reservation/lease tables.
They do not switch any application traffic or migrate existing rows.

| Table                        | GraphQL type              | Schema file             |
| ---------------------------- | ------------------------- | ----------------------- |
| `teams`                      | `Team`                    | `schema.gql`            |
| `team_members`               | `TeamMember`              | `schema.gql`            |
| `secret_references`          | `SecretReference`         | `secret.gql`            |
| `github_connections`         | `GitHubConnection`        | `github.gql`            |
| `github_connection_requests` | `GitHubConnectionRequest` | `github.gql`            |
| `github_connection_sessions` | `GitHubConnectionSession` | `github.gql`            |
| `build_jobs`                 | `BuildJob`                | `build.gql`             |
| `build_runs`                 | `BuildRun`                | `build.gql`             |
| `build_steps`                | `BuildStep`               | `build_log.gql`         |
| `build_logs`                 | `BuildLog`                | `build_log.gql`         |
| `build_dispatch_schedulers`  | `BuildDispatchScheduler`  | `build_dispatch.gql`    |
| `build_job_dispatches`       | `BuildJobDispatch`        | `build_dispatch.gql`    |
| `webhook_tasks`              | `WebhookTask`             | `webhook.gql`           |
| `skipped_workflow_reports`   | `SkippedWorkflowReport`   | `webhook.gql`           |
| `billing_accounts`           | `BillingAccount`          | `billing.gql`           |
| `billing_periods`            | `BillingPeriod`           | `billing.gql`           |
| `billing_trial_claims`       | `BillingTrialClaim`       | `billing.gql`           |
| `billing_customer_creations` | `BillingCustomerCreation` | `billing_stripe.gql`    |
| `billing_checkout_creations` | `BillingCheckoutCreation` | `billing_stripe.gql`    |
| `billing_stripe_state`       | `BillingStripeState`      | `billing_stripe.gql`    |
| `billing_stripe_events`      | `BillingStripeEvent`      | `billing_stripe.gql`    |
| `billing_admissions`         | `BillingAdmission`        | `billing_execution.gql` |
| `billing_executions`         | `BillingExecution`        | `billing_execution.gql` |

Source definitions are the table classes registered in
[`AppDatabase`](../../apps/openci_server/lib/database.dart) and the Go service's
[`billing/schema`](../../apps/genuineci_server/internal/billing/schema).
`SkippedWorkflowReport` follows the table introduced by
[G-1561](https://linear.app/genuineci/issue/G-1561), which is not yet registered
in this branch's legacy `AppDatabase`.

## Storage and relation rules

- Keep existing text IDs and text enum/status values. New log IDs use `UUID`.
  JSON encoded as text (`matrix`, `needs`, `provisioned_udids`, webhook `payload`)
  remains `String`, not `Any`.
- Drift integers and DateTime columns remain PostgreSQL `bigint` (`Int64`).
  DateTime values are Unix seconds. Admission/execution `*_ms` values and
  `reserved_millis` remain milliseconds; `allowance_seconds` remains seconds.
  New log/step timestamps and `BuildRun.logsExpireAt` use `Timestamp`
  (`timestamptz`); step durations and log sequence numbers use `Int64`.
- Team deletion removes members, secret references, GitHub connection metadata,
  and skipped reports. Build jobs and billing accounts have no Team foreign key,
  so their history survives. Build runs cascade with their owning job, and
  their steps/logs cascade when a run is deleted.
- Billing admissions/executions reference `(period_id, team_id)` together;
  referencing another team's period fails at the database layer.
- Dispatch reservations use timestamp leases and a nullable unique
  `active_job_id`. They retain historical job IDs without cascading deletion:
  deleting a job must not make its still-running VM disappear from capacity
  accounting. The executor cleans up the VM before closing its reservation.
- Required `@ref` relations cascade on delete; optional references use SET NULL.
  Billing accounts and periods must not be physically deleted. This differs
  from the legacy billing NO ACTION foreign keys. No delete operation is exposed.

## Intentional data conversions

| Legacy storage                                      | Destination                                                                                        |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `teams.ai_enabled`                                  | Omitted as previously agreed                                                                       |
| `teams.installation_ids`                            | Omitted; GitHub installations are managed in `github_connections`                                  |
| `secrets.encrypted_value`                           | Secret Manager value; `secret_references.secret_version_path` identifies a numeric version         |
| `github_connection_requests.code_verifier`          | Secret Manager value; `code_verifier_secret_version_path` is required                              |
| `github_connection_sessions.encrypted_access_token` | Secret Manager value; nullable `access_token_secret_version_path` is cleared on consumption/expiry |
| Open admission (`closed_at_ms IS NULL`)             | Set `open_job_id = job_id`; otherwise set it to NULL                                               |
| Open checkout (`closed_at IS NULL`)                 | Set `open_team_id = team_id`; otherwise set it to NULL                                             |
| Existing Stripe state                               | Initialize the new `revision` column to `0`                                                        |
| Existing billing account                            | Initialize the new `usage_revision` column to `0`                                                  |

The new open-key columns have ordinary nullable unique constraints. Two open
rows cannot reserve the same key, while closed rows can retain the same job/team
with NULL keys. SQL Connect's schema directives do not express the legacy
partial unique indexes. The remaining partial lookup indexes become ordinary
indexes that include the closed/finished timestamp.

An open-key column is not generated automatically. Imports and mutations
must derive it from the row's ID and closed timestamp, and update both fields in
the same transaction. A standalone `@check` that queries for an existing row is
not sufficient for concurrent requests; the unique key must arbitrate the write.
Checkout and admission operations enforce this rule.

`billing_stripe_state.revision` is a new non-null bigint with default `0`. The
event-recording mutation compares the expected revision in its UPDATE and
increments it atomically, so equal-second observations cannot silently overwrite
one another. Functions must re-fetch Stripe after a revision conflict.

`billing_accounts.usage_revision` is a separate non-null bigint with default `0`.
Every admission/execution writer increments it transactionally. A quota check
and its revision come from one SQL snapshot, followed by a conditional update;
other writes require an expected revision. This prevents simultaneous requests
from reserving the same remaining allowance and protects observation/expiry races.

OAuth request/session values must not be copied into SQL Connect. At cutover,
let short-lived flows expire and restart, or explicitly move the secrets to
Secret Manager. Deleting SQL references does not destroy Secret Manager versions;
the future Functions cleanup must do both.

## Build log storage

`BuildStep` stores the latest state of each `(runId, stepId)`. `BuildLog` stores
one log entry per row, with a run-scoped sequence for pagination and a sender's
stable UUID for retry detection. `occurredAt` is the sender's event time;
`createdAt` defaults to the server request time. Timestamp defaults apply only
on insertion; step updates must explicitly advance `updatedAt`.

The `logs` connector validates team membership, run/team ownership, supported
status/source/stream values, non-negative step order/duration, and bounded
message sizes. Worker/run assignment remains Functions work.
A non-null `stepId` must match a step in the same run. It is intentionally a scalar:
an optional composite `@ref` would SET NULL on both the step ID and the required
run ID when deleting a step.

Log writers must be insert-only. Resolve retried `logId` values against the saved
payload, then reserve positive consecutive sequences by conditionally advancing
`BuildRun.lastLogSequence` once per log. Commit that update and the log insert in
one transaction; a conflict requires a fresh read and retry. Earlier committed
logs remain saved if a later append fails. Guard step state
transitions so a late running event cannot overwrite a terminal state.

`logsExpireAt` is indexed for future cleanup of log bodies while retaining run
and step summaries. It starts unset; retention scheduling and deletion are not
implemented. See [Build logs](README.md#build-logs) for connector usage.

## Validation required in future write operations

`CreateBillingPeriod` and the operations in `billing/customers.gql`,
`billing/checkouts.gql`, `billing/stripe.gql`, `billing/trials.gql`,
`billing/deletion.gql`, `billing/admissions.gql`, and `billing/executions.gql`
have write validations implemented. Creation intents are insert-only; Customer/Session IDs use
conditional updates. Checkout operations derive/release the open key atomically.
Stripe state/event writes share a transaction, enforce period ownership and
retention, protect ended subscriptions, and reject stale revisions. Stripe
responses and membership must be verified by Functions. Admission/execution
operations enforce the following invariants through derived values, `@check`,
conditional updates, and transactions. Future writers must preserve them too:

| Table                | Required checks and atomic behavior                                                                                                                                                                                                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `billing_admissions` | Nonempty ID/job/worker/run IDs; positive reservation; `start_by_ms > claimed_at_ms`; closed time is NULL or at least the claim time; derive/release `open_job_id`                                                                                                                                                         |
| `billing_executions` | Nonempty run/job/worker IDs; `started_at_ms <= observed_at_ms <= lease_until_ms`; finished time is NULL or equals observed time; finished time and outcome are both NULL or both set; outcome is `success`, `failure`, `cancelled`, `timed_out`, or `abandoned`; `measurement_incomplete` is true exactly for `abandoned` |

`StartBillingTrial` atomically creates a seven-day Pro period and claim after
checking membership and absence of an active paid period. Trial claims retain
user-primary-key and team-unique protection and survive team deletion. Stripe
event IDs and customer/checkout idempotency keys remain unique. Coordinating these
records with Stripe, worker authorization/capacity, run display numbering, job
completion, and recovery scheduling remains Functions work. The billing connector
now claims a selected queued job atomically with its reservation, binds its run,
and measures/renews/finishes execution leases. It does not replace the queue's
worker-capacity advisory lock or expose general writes for the other tables.
Trial activation is not exposed to clients or wired to the execution flow.

`DeleteBillingTeam` verifies membership, expected Customer/Stripe state, and
absence of pending purchases under the same row locks used by billing writes.
It preserves billing/build history and returns Secret Manager references before
their SQL rows cascade. Functions must verify Stripe before calling it and
durably handle credential cleanup, including lost responses and concurrent
secret creation. See [Team deletion](README.md#team-deletion).

## Excluded storage

`invitations`, `user_devices`, and `udid_requests` are retired (G-1569). The old
`secrets` value table is replaced by `secret_references`. Previously removed
`processed_webhooks`, `build_step_logs`, and `worker_heartbeats` are not
reintroduced. `build_steps` and `build_logs` above are new definitions for the
current Loki-backed logs, not a copy of the removed legacy tables. Build artifact
metadata, including `provisioned_udids`, is retained independently of the retired
device registration tables.
