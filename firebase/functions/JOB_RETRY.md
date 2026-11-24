# Job retry API

`RetryBuildJob` is an authenticated SQL Connect mutation on the existing `builds`
connector. A non-anonymous Firebase user must still belong to the job's team.
The repository's GitHub connection must be active.

Read `GetBuildJob` or `GetBuildJobs`, then send the observed `retryCount`:

```dart
final response = await BuildsConnector.instance
    .getBuildJob(id: jobId)
    .execute(fetchPolicy: QueryFetchPolicy.serverOnly);
final job = response.data.job!;
final retry = await BuildsConnector.instance
    .retryBuildJob(id: job.id, expectedRetryCount: job.retryCount)
    .execute();
// retry.data.result?.job contains id, status, retryCount, runCount, latestRunId.
```

The generated Node Admin SDK also exposes `retryBuildJob`. When acting for a
user, pass `{ impersonate: { authClaims } }` so the same authorization applies.
This is a SQL Connect API, not a new callable Function or REST router.

## Contract

- Jobs using `macos-latest` or `linux-latest` can be retried after `SUCCESS`,
  `FAILURE`, `CANCELLED` or `TIMED_OUT`. Retried Linux jobs retain their
  machine and follow the [pilot repository setting](BUILD_DISPATCH.md#configuration-and-rollout).
- The transaction changes the job to `QUEUED` and increments `retryCount` once.
  Its response is `{ retried: 1, result: { job: ... } }`. Acceptance means queued;
  capacity, current GitHub checkout validation and normal billing admission still
  apply before a build starts.
- Concurrent requests using the same counter have exactly one winner. A stale
  counter is rejected even if the accepted attempt has already failed before
  allocating a run. After a lost response, refetch the job to reconcile the
  counter; do not automatically submit another retry with the new counter.
- The job ID, pinned commit, workflow configuration, webhook deduplication key,
  creation time and previous runs/logs remain intact. `latestRunId` continues to
  identify the previous run until the executor starts the new one. `runCount`
  and the team's run number advance through the normal executor path.
- Terminal failure details, completion time, worker/VM assignment, supersession
  marker and Check publication state are cleared. An unfinished dispatch or live
  Check publication lease rejects the transaction without changing the job.
- Each retry gets a fresh GitHub Check, including jobs cancelled before their
  first run. Queued Check identities include `retryCount`; normal initial jobs
  retain their existing identities.

`queueRetriedBuildJob` listens only to `builds/RetryBuildJob`. It accepts successful
user/Admin events and durably enqueues the normal dispatcher with a task ID derived
from `(jobId, retryCount)`. Event redelivery and ambiguous Cloud Tasks responses
reuse that ID. The dispatcher publishes the queued Check and uses the existing
capacity, recovery and execution machinery.

## Deployment

1. Apply the additive `build_jobs.retry_count` integer column with non-null default
   `0` through the schema migration. Existing jobs start at zero.
2. Deploy the updated `dispatch` connector, executor image, `queueBuildJobs`,
   `dispatchBuildJob` and `recoverBuildExecutions` so all Check writers understand
   retry identities. Deploy `queueRetriedBuildJob` with the existing dispatch
   service account and Cloud Tasks permissions, then reconcile its invocation
   grant from `infra/orchard/runtime_iam.tf` before exposing the mutation.
3. Deploy the `builds` connector, then consumers of its regenerated SDK. Deploying
   the retry trigger before exposing the mutation avoids accepted but unnotified
   work. The Dashboard SDK is included; a retry button is separate UI work.

## Validation

Functions tests cover event redelivery, task identity, queue outages and sanitized
errors. SQL Connect emulator tests exercise real authorization, concurrent writes,
rollback during cleanup, history preservation, Check publication and new run
allocation through the existing executor. These local tests do not launch a real
Cloud Run build or call GitHub/Orchard/Stripe.
