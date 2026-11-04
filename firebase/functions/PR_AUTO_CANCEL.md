# PR auto cancellation

`OpenCI.init(cancelPreviousRuns: true)` opts a workflow into superseding older
commits on the same pull request. Both the newly scheduled job and the old job
must opt in. The default is false, including pre-existing jobs. The scope is
team, GitHub host, installation, owner/repository, PR number and workflow file.
Only `QUEUED` and `IN_PROGRESS` jobs at a different SHA are cancelled. Push runs,
same-SHA reruns, terminal jobs, unmatched workflows and path-skipped plans are
unchanged.

## Planning and concurrency

Every connected PR planning attempt calls `BeginPullRequestPlanning` before
fetching workflows or observing GitHub. A random token replaces the fence for
that connection/repository/PR; there is no dependency on delivery time, commit
timestamps, ancestry or the ordering of force pushes. The token is supplied by
the caller so a post-write query cannot read an earlier database snapshot.

For selected opted-in workflows the planner verifies the live PR using a
repository-scoped, PR-read-only installation token, then revokes it. The head
SHA and target branch must match the event and the PR must be open. Stale events
complete without creating their opted-in jobs. API failures leave the task
pending and retryable; repository provenance failures remain terminal.

`CompleteWebhookTask` locks the same fence with a conditional write, then
atomically inserts new jobs, cancels matching old jobs and completes the task.
A newer concurrent planning attempt invalidates the old observation. A failed
fence check rolls back the whole transaction and the old task retries against
the live PR. All PR attempts acquire a fence, including plans that disable this
option or select no jobs.

Cancelled rows persist `supersededByTaskId`. The mutation event contains only
the cancellation count; `queueBuildJobs` pages `GetSupersededBuildJobs` and
enqueues stable per-job notifications. A lost or partial enqueue response is
safe to retry. The dispatcher releases unclaimed reservations and finalizes
queued Checks. Running executors observe `CANCELLED` through their existing
15-second heartbeat and retain responsibility for VM deletion, billing closure,
Check completion and capacity release. Conditional admission and terminal
writes prevent execution startup from restoring a cancelled job.

Cancellation locks active dispatches before jobs, in the executor's lock order.
If a terminal execution result has already been recorded, that execution keeps
its original result while cleanup finishes. This prevents the database,
billing ledger and GitHub Check from disagreeing during completion. A blocked
attempt that would requeue its job can still be cancelled.

## Rollout

1. Deploy the additive schema (`pull_request_planning`, two BuildJob columns and
   indexes) and the `webhooks` / `dispatch` connector operations.
2. Deploy the updated `queueBuildJobs` Function and Dart planner, using the
   regenerated SDKs. The existing executor cancellation protocol is reused.
3. Publish `openci_workflow` 0.2.3, update consuming workflow dependencies and
   enable the option on selected PR workflows.

Keep the option disabled until both server components are deployed. Existing
planners may still use the connector without a fence only for non-opted-in jobs;
the connector rejects opted-in jobs without a PR identity and valid fence.
Rolling back the planner is safe after removing the option from workflows;
keep cancellation notification handling until queued notifications are drained.

## Validation

The Dart tests cover literal configuration, PR-only selection, scoped live-head
verification and API failures. SQL emulator tests exercise delayed delivery,
an in-flight old response overtaken by a new plan, force pushes, same-SHA reruns,
scope isolation, transaction rollback, denied client access, startup races and
running command interruption with billing/VM/Check cleanup. Function tests cover
paginated notifications and partial enqueue failures. These use mocked GitHub
and Orchard; deployment and live Mac verification are separate rollout checks.
