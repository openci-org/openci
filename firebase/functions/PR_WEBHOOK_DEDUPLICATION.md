# PR webhook deduplication

PR webhook delivery IDs identify transport attempts. The Dart planner also
computes a versioned SHA-256 execution key from the GitHub App/API/base URL,
connection and team, installation, repository ID and normalized owner/name,
PR number, head SHA/branch, base SHA/branch, workflow file/name, requested Flutter
version, runner and cancellation setting. A different base or execution
configuration remains a separate validation. The head SHA identifies the
immutable workflow source and repository configuration.

`BuildJob.webhookExecutionKey` is nullable and unique. Only webhook PR planning
populates it; push runs and explicit jobs/reruns without the key remain independent.
Legacy payloads missing base SHA retain task-based identity because equivalence
cannot be established safely. No `cancelPreviousRuns` opt-in is required.

`CompleteWebhookTask` checks the PR fence and inserts with `ON CONFLICT` against
that key. A conflict returns the existing job ID without changing status, run
count, result, Check ID or timestamps. Concurrent deliveries therefore converge
on one job. A planner that loses its fence retries. The mutation notification
uses the returned ID, so queued-Check synchronization, stable dispatch task IDs
and conditional executor admission continue to refer to the same execution.

An automatically cancelled job releases its key only when a later valid plan
needs that exact context again. This permits force-pushing back to a superseded
revision and reopening a PR cancelled by the closure lifecycle. Historical jobs
and their cleanup remain intact. Manual cancellations (no `supersededByTaskId`)
and completed success/failure results stay deduplicated; duplicate webhook
notifications are not user rerun requests. Explicit new jobs must omit the key;
rerunning an existing job keeps its existing identity and run counter lifecycle.
The manual-rerun dispatch API remains separate work, as in BUILD_EXECUTOR.md.

Skipped PR workflows use the same scoped identity with a skipped discriminator
and comparison SHA. Conflict handling preserves the original outbox row, lease
and reported Check instead of publishing another skipped Check. Failed batch
validation rolls back deduplication, key release and task completion together.

Deploy the additive nullable column/unique constraint, then the webhooks
connector, then the Dart planner. Existing jobs have null keys and are not
backfilled or retroactively cancelled. Reverting the planner retains the old
behavior without removing the schema. Deploy G-1624 separately for PR closure;
this change does not enable that behavior or change cancellation opt-in.

Validation uses the real SQL emulator and Dart HTTP planner with mocked GitHub:
repeated and concurrent deliveries, queued/running/terminal/manual-cancelled
jobs, returned notification IDs, base/SDK changes, explicit jobs, force-push
return, scope isolation, skipped-Check preservation and rollback. Production
Eventarc and Orchard verification remain deployment checks.
