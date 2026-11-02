# Build dispatch (G-1604)

`queueBuildJobs` listens to the successful admin `CompleteWebhookTask` mutation,
publishes a queued GitHub Check for each returned BuildJob, then enqueues its ID.
`dispatchBuildJob` is a private Gen2
task queue Function. Both use Tokyo, 1 CPU, 256 MiB, concurrency 1, minimum
instances 0. The mutation consumer has a 540-second timeout for batches; the
dispatcher has a 60-second timeout.

```text
CompleteWebhookTask -> queueBuildJobs -> queued GitHub Check -> Cloud Tasks -> dispatchBuildJob
  -> acquire scheduler lease and recover unstarted reservations
  -> select the oldest eligible BuildJob from FSC and check Orchard capacity
  -> ensure the selected job's queued Check is durable, then reserve its slot
  -> schedule recovery task, then call Cloud Run Jobs.run
  -> Cloud Run executor (G-1605) claims the reservation and runs the build
```

The Function returns after the launch operation is accepted. It does not create
a VM, hold a WebSocket, stream logs, or wait for the workflow. The existing Dart
worker does not implement the new executor contract. The [Cloud Run executor](BUILD_EXECUTOR.md)
implements G-1605. Keep the existing production webhook path until deployment
validation is complete.

## GitHub Check lifecycle

Checks are visible while jobs wait for VM capacity. Publication saves the ID and
next run number on BuildJob. A five-minute per-job lease serializes publication
and prevents reservation creation while the GitHub request is in flight. GitHub
calls have a 20-second total budget. Ambiguous failures retain the lease; retries
reconcile the App ID and `build-job:JOB_ID:run:NUMBER` external ID before creating
another check. Queuing a retry never resets a running or completed check.

The reservation copies that ID, and the executor updates it to `in_progress`
and then `completed`. Each numbered run has its own check; replacement capacity
reservations before execution reuse the queued one. Cancellation while waiting
completes it as cancelled on the next dispatch task. Rejection before creating a
BuildRun also completes an existing check. A billing-blocked attempt without a
numbered run leaves its check queued for a later attempt.

The dispatcher also publishes missing checks for jobs queued before deployment.
Existing active reservations retain their original execution-owned checks.
Publishers validate the active team/installation/App connection and repository
owner before using a repository-scoped checks-write token.

## Queue order

Cloud Tasks deliveries wake the dispatcher. New reservations select eligible
`QUEUED` `macos-latest` jobs by `createdAt`, then `id`, regardless of the job ID
in the notification. The scheduler lease covers expiration, selection, capacity
checks and reservation. This orders capacity allocation; concurrent VMs can
start or finish their workflows in a different order.

Selection excludes open reservations, live queued-Check publication leases and
jobs whose last blocked attempt finished within 60 seconds. Their original
creation times are preserved, so they regain their position when eligible.
Cancelled and terminal jobs are never selected for a new reservation.

If a notification starts another job, its own queued job keeps a delayed retry
until it has a reservation or is no longer queued. This also preserves the last
notification when all remaining jobs are temporarily ineligible. Expected waits
do not keep completed or claimed jobs polling. Existing task payloads continue
to work without recreating the waiting queue.

Before creating a new reservation, any notification can resume an unstarted
reservation whose launch has not been recorded. Recovery tasks use the selected
reservation's job ID, while ordinary successors retain the notification's job
ID. The startup deadline and execution claim still fence ambiguous launches.

## Capacity and retries

Capacity includes Orchard VMs and FSC reservations whose stable VM names are
not yet visible in Orchard. Only online, unpaused Tart/arm64 workers count.
CPU, memory and Tart VM slots must fit on an individual worker; aggregate fleet
totals alone are insufficient. Unknown VM usage fails the check. Placement is
conservative and Orchard still owns final scheduling, including competition
from other Orchard clients.

`BuildDispatchScheduler` serializes capacity snapshots with a 90-second lease.
The reservation transaction verifies the current owner and lease, and requires
a `QUEUED` `macos-latest` job. `BuildJobDispatch.activeJobId` is unique while a
reservation is open. Closed attempts retain history and clear this key.

If no capacity exists, or the scheduler/launch lease is busy, the job stays
`QUEUED`. The Function enqueues a successor scheduled 60 seconds later before
acknowledging the current task with HTTP 204. These expected waits log at INFO,
so they do not trigger ERROR-log alerts. Each successor's ID is derived from the
source Cloud Tasks task ID and job ID, in a namespace distinct from initial and
recovery tasks. Redelivery or a lost enqueue response therefore reuses the same
successor; subsequent waits create distinct successors and continue checking
until the job is dispatched or no longer eligible.

Actual dispatch or enqueue failures still log sanitized ERRORs and fail the
current task for retry after 30–60 seconds. These retries are unlimited within
Cloud Tasks' maximum retention period. Dispatch rate is capped at 5/second and
5 concurrent calls; this is API throttling, not the VM capacity limit. Cloud
Tasks does not guarantee FIFO scheduling. See
[queue retry configuration](https://docs.cloud.google.com/tasks/docs/configuring-queues#set_retry_parameters).

Named initial tasks deduplicate mutation redelivery. Each reservation also has
a named recovery task at its ten-minute startup deadline, persisted before
launch. If the executor never claims it, that task expires the reservation and
tries again. Enqueue failures retain the reservation and retry the current task.
Cancellation releases unclaimed reservations. A claimed reservation never
expires merely because the startup deadline passed.

A separate 90-second lease serializes launch requests. An ambiguous Jobs.run
response retains that lease; a later retry uses the same dispatch ID. Jobs.run
has no request idempotency key, so more than one container can start. Only one
may acquire execution through the mutation below. The Function saves the
operation name without waiting for the execution. See the
[Jobs.run API](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs/run).

## G-1605 executor contract

Cloud Run receives only `BUILD_JOB_ID` and `BUILD_DISPATCH_ID` as overrides.
Use a single task and a single application container; configure task retries to
zero and choose the workflow timeout on the pre-created Job.

1. Read `GetBuildExecution` from the privileged `dispatch` connector and verify
   the supplied job ID. Use its pinned `vmName`, `cpu`, `memoryMiB` and `image`.
2. Generate a fresh process UUID and call `ClaimBuildJobExecution` with that
   `executorId` and the full Cloud Run execution resource name. Continue only when `acquired == 1`.
   A rejected claim, including a lost claim response, must not create a VM.
   Even restarted containers with the same execution name must claim separately.
3. Perform billing admission and the existing job/run transition, then create
   the VM through Orchard using the reservation's name and size. Retrieve
   credentials and workflow metadata server-side. This reservation alone does
   not authorize paid execution or increment the build's run count.
4. Own checkout, workflow execution, logs, cancellation, billing and GitHub
   Checks. Persist the result, acquire the cleanup lease, delete the VM and close
   billing, then call `CompleteBuildExecution` with the matching cleanup owner.

`recoverBuildExecutions` reconciles crashed executors and deletes their VMs before
releasing claimed reservations. Automatically expiring a running build here
could allocate its capacity twice. Manual rerun dispatch remains separate work.
`WAITING` and unknown job statuses are not terminal.

## Configuration and rollout

| Parameter                                  | Value                                                         |
| ------------------------------------------ | ------------------------------------------------------------- |
| `ORCHARD_API_URL`                          | Private HTTPS controller URL (`https://10.77.0.2:443` on GCP) |
| `ORCHARD_SERVICE_ACCOUNT_NAME`             | Orchard account with workers/VMs read access                  |
| `ORCHARD_SERVICE_ACCOUNT_TOKEN`            | Bound Secret Manager secret                                   |
| `ORCHARD_CA_CERT`                          | Optional trusted PEM CA; TLS verification stays enabled       |
| `ORCHARD_VM_CPU` / `ORCHARD_VM_MEMORY_MIB` | Positive integers, defaults 2 / 4096                          |
| `BASE_VM_NAME`                             | Orchard image, default `base-macos`                           |
| `BUILD_EXECUTOR_JOB`                       | `projects/PROJECT/locations/REGION/jobs/JOB`                  |
| `GITHUB_APP_ID` / `GITHUB_APP_PRIVATE_KEY` | CI App ID and bound private-key secret, on both Functions     |
| `GITHUB_API_BASE_URL` / `GITHUB_BASE_URL`  | Same GitHub host configuration as the executor                |

`dispatchBuildJob` and `recoverBuildExecutions` use Direct VPC egress from
`orchard_network.ts`. Set `ORCHARD_VPC_NETWORK` and `ORCHARD_VPC_SUBNETWORK` if
using a different network (defaults `orchard` / `orchard-tokyo`). Both carry the
`orchard-client` network tag and route only private ranges through VPC. Allow
that tag to reach the controller's TCP 443; retain certificate verification.
See [Orchard networking](../../infra/orchard/README.md).

Deploy the new schema tables and `dispatch` connector, then provision the G-1605
Cloud Run Job. Enable Cloud Tasks and Cloud Run APIs. Deploy `dispatchBuildJob`
before enabling `queueBuildJobs` so the task queue exists before events arrive.

The two Functions' runtime identities need `cloudtasks.tasks.create` on that
queue and `iam.serviceAccounts.actAs` on the identity used in their tasks (the
Firebase Admin SDK uses the runtime service account). Grant those task
identities `roles/run.invoker` on the private Gen2 dispatcher. Retain the Cloud
Tasks service agent role so authenticated task delivery can mint tokens. See
[task queue IAM](https://firebase.google.com/docs/functions/task-functions#iam_permissions).

Both Functions need privileged FSC access to `dispatch` and the bound GitHub App
private key. Deploy the additive BuildJob check columns and updated connector
before these Functions. Update the executor image and recovery Function as well
so early failures close queued checks. The dispatcher also needs access to the bound
Orchard secret, network reachability to the controller, and
`roles/run.jobsExecutorWithOverrides` on the selected Job. The G-1605 executor
needs its own runtime IAM for FSC/billing/logs/secrets and its own Orchard
credentials. No user-supplied destination or workflow body is accepted by the
dispatcher. Use the [Cloud Run execution permissions](https://docs.cloud.google.com/run/docs/execute/jobs#required_roles).

This change does not deploy schema, Functions, queues, IAM, or a Cloud Run Job.
Before cutover, verify actual mutation delivery, task OIDC invocation, controller
TLS/networking, Job launch and claim, capacity exhaustion/retry, executor crash
cleanup, and memory headroom with the configured 256 MiB.

## Local verification

Run the Node checks and SQL emulator tests from [README.md](README.md#local-checks).
Use `--test-concurrency=1` for the SQL suites: dispatch tests share the scheduler
row. Tests use the real SQL emulator with mock Orchard/Cloud Run boundaries and
exercise contention, ambiguous responses, retries, expiry and authorization.
The CLI does not emulate FSC Eventarc delivery or production Cloud Tasks IAM.

The dispatcher uses a dedicated Firebase app via `getDispatchDataConnect`.
Admin SDK 14.5.0 caches Data Connect by service/location, without the connector
ID, so sharing one app across webhook and dispatch connectors sends later
operations to the first connector. The combined planning/dispatch test covers
this boundary. Executors using several connectors must also isolate them.
