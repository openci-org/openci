# Build dispatch (G-1604)

`queueBuildJobs` listens to the successful admin `CompleteWebhookTask` mutation
and enqueues its returned BuildJob IDs. `dispatchBuildJob` is a private Gen2
task queue Function. Both use Tokyo, 1 CPU, 128 MiB, concurrency 1, minimum
instances 0, and a 60-second timeout.

```text
CompleteWebhookTask -> queueBuildJobs -> Cloud Tasks -> dispatchBuildJob
  -> read queued BuildJob + active reservations from FSC
  -> read Orchard workers/VMs and reserve an available slot in FSC
  -> schedule recovery task, then call Cloud Run Jobs.run
  -> Cloud Run executor (G-1605) claims the reservation and runs the build
```

The Function returns after the launch operation is accepted. It does not create
a VM, hold a WebSocket, stream logs, or wait for the workflow. The existing Dart
worker does not implement the new executor contract. Keep the existing production
webhook path until G-1605 and deployment validation are complete.

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

If no capacity exists, the job stays `QUEUED` and the Function fails the task
for retry after 30–60 seconds. Retries are unlimited within Cloud Tasks' maximum
retention period. Dispatch rate is capped at 5/second and 5 concurrent calls;
this is API throttling, not the VM capacity limit. Cloud Tasks does not guarantee
FIFO scheduling. See [queue retry configuration](https://docs.cloud.google.com/tasks/docs/configuring-queues#set_retry_parameters).

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

1. Read `GetBuildJobDispatch` from the privileged `dispatch` connector and verify
   the supplied job ID. Use its pinned `vmName`, `cpu`, `memoryMiB` and `image`.
2. Generate a fresh process UUID and call `ClaimBuildJobExecution` with that
   `executorId` and `CLOUD_RUN_EXECUTION`. Continue only when `acquired == 1`.
   A rejected claim, including a lost claim response, must not create a VM.
   Even restarted containers with the same execution name must claim separately.
3. Perform billing admission and the existing job/run transition, then create
   the VM through Orchard using the reservation's name and size. Retrieve
   credentials and workflow metadata server-side. This reservation alone does
   not authorize paid execution or increment the build's run count.
4. Own checkout, workflow execution, logs, cancellation, billing and GitHub
   Checks. Delete the VM and finalize the job before calling
   `FinishBuildJobDispatch` with the matching dispatch/job/executor IDs.

G-1605 must reconcile crashed executors and clean up their VMs before releasing
claimed reservations. Automatically expiring a running build here could allocate
its capacity twice. Billing integration, that reconciliation, and manual rerun
dispatch are follow-up work. `WAITING` and unknown job statuses are not terminal.

## Configuration and rollout

| Parameter                                  | Value                                                   |
| ------------------------------------------ | ------------------------------------------------------- |
| `ORCHARD_API_URL`                          | HTTPS controller base URL                               |
| `ORCHARD_SERVICE_ACCOUNT_NAME`             | Orchard account with workers/VMs read access            |
| `ORCHARD_SERVICE_ACCOUNT_TOKEN`            | Bound Secret Manager secret                             |
| `ORCHARD_CA_CERT`                          | Optional trusted PEM CA; TLS verification stays enabled |
| `ORCHARD_VM_CPU` / `ORCHARD_VM_MEMORY_MIB` | Positive integers, defaults 2 / 4096                    |
| `BASE_VM_NAME`                             | Orchard image, default `base-macos`                     |
| `BUILD_EXECUTOR_JOB`                       | `projects/PROJECT/locations/REGION/jobs/JOB`            |

Deploy the new schema tables and `dispatch` connector, then provision the G-1605
Cloud Run Job. Enable Cloud Tasks and Cloud Run APIs. Deploy `dispatchBuildJob`
before enabling `queueBuildJobs` so the task queue exists before events arrive.

The two Functions' runtime identities need `cloudtasks.tasks.create` on that
queue and `iam.serviceAccounts.actAs` on the identity used in their tasks (the
Firebase Admin SDK uses the runtime service account). Grant those task
identities `roles/run.invoker` on the private Gen2 dispatcher. Retain the Cloud
Tasks service agent role so authenticated task delivery can mint tokens. See
[task queue IAM](https://firebase.google.com/docs/functions/task-functions#iam_permissions).

The dispatcher needs privileged FSC access to `dispatch`, access to the bound
Orchard secret, network reachability to the controller, and
`roles/run.jobsExecutorWithOverrides` on the selected Job. The G-1605 executor
needs its own runtime IAM for FSC/billing/logs/secrets and its own Orchard
credentials. No user-supplied destination or workflow body is accepted by the
dispatcher. Use the [Cloud Run execution permissions](https://docs.cloud.google.com/run/docs/execute/jobs#required_roles).

This change does not deploy schema, Functions, queues, IAM, or a Cloud Run Job.
Before cutover, verify actual mutation delivery, task OIDC invocation, controller
TLS/networking, Job launch and claim, capacity exhaustion/retry, executor crash
cleanup, and memory headroom with the configured 128 MiB.

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
