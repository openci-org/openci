# PR auto cancellation

`OpenCI.init(cancelPreviousRuns: true)` opts a workflow into superseding older
commits on the same pull request. Both the newly scheduled job and the old job
must opt in. The default is false, including pre-existing jobs. The scope is
team, GitHub host, installation, owner/repository, PR number and workflow file.
Only `QUEUED` and `IN_PROGRESS` jobs at a different SHA are cancelled. Push runs,
explicit same-SHA reruns, terminal jobs, unmatched workflows and path-skipped plans are
unchanged.

## Planning and concurrency

Every connected PR planning attempt calls `BeginPullRequestPlanning` before
fetching workflows or observing GitHub. A random token replaces the fence for
that connection/repository/PR; there is no dependency on delivery time, commit
timestamps, ancestry or the ordering of force pushes. The token is supplied by
the caller so a post-write query cannot read an earlier database snapshot.

For every connected PR event the planner verifies the live PR using a
repository-scoped, PR-read-only installation token, then revokes it. The head
SHA and target branch must match the event and the PR must be open. Stale events
complete without creating jobs or skipped Checks. API failures leave the task
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

## PR closure

Merge and close-without-merge events use the same planning fence and completion
transaction. The planner observes the current PR state without fetching workflow
source for a close notification. A closed PR cancels every remaining queued or
running job in the team, GitHub host, installation, owner/repository and PR scope,
regardless of workflow, SHA or `cancelPreviousRuns`. A delayed close after a
reopen completes without cancellation. Delayed update events also check the live
state, preventing new jobs or skipped Checks for a closed PR.

`cancelClosedPullRequest` requires an active connection, a valid PR fence and an
empty plan. The existing `cancelled` result and `supersededByTaskId` outbox notify
the dispatcher, which finalizes queued Checks and releases unstarted reservations.
Running jobs use the executor cancellation lifecycle described above. Repeated
close deliveries leave terminal results untouched. Concurrent reopen/close plans
invalidate older observations; a lost fence leaves the task retryable.

Deploy the regenerated `webhooks` connector before the Dart planner, then deploy
`githubWebhookFsc` so signed `pull_request.closed` deliveries enter the planning
queue. Both merged and unmerged closures use that event. No schema change or new
Function trigger is needed for closure cancellation. Historical backlog cleanup
and production verification are separate from this rollout.

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
an in-flight old response overtaken by a new plan, force pushes, duplicate same-SHA notifications, explicit reruns,
scope isolation, transaction rollback, denied client access, startup races and
running command interruption with billing/VM/Check cleanup. Function tests cover
paginated notifications and partial enqueue failures. These use mocked GitHub
and Orchard; deployment and live Mac verification are separate rollout checks.

Repeated PR webhook deliveries are independently coalesced by
[PR webhook deduplication](PR_WEBHOOK_DEDUPLICATION.md), even with cancellation
disabled. A new delivery ID is not an explicit user rerun.
