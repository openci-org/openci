# GitHub webhook receiver

GitHub App authorization and team connection are implemented separately by
[`githubConnection` and `githubConnectionCallback`](GITHUB_CONNECTION.md).

Team and member management use the [FSC teams connector and `teamManagement`
callable](TEAMS.md). [Billing and team deletion](BILLING.md) use `teamBilling`,
`stripeWebhook` and the shared FSC billing ledger.

`githubWebhookFsc` is a second-generation HTTPS Function in `asia-northeast1`.
The distinct name allows validation before switching an existing GitHub webhook.
The Firebase npm workspace is its deployment source; TypeScript in this
directory compiles to `firebase/lib/functions` and uses the generated Admin SDK
in `firebase/generated/webhooks-admin`.

The receiver uses [`@octokit/webhooks`](https://github.com/octokit/webhooks.js)
for signature verification, JSON parsing, and event dispatch.
`webhooks.on()` selects `push` and `pull_request.opened`,
`pull_request.synchronize`, and `pull_request.reopened`, matching the existing
server's trigger selection. Other signed JSON events, including `ping`, are
acknowledged without creating a task. Firebase's parsed body is checked for an
object and a string action; signature verification and storage use the strictly
decoded original UTF-8 body, without JSON reserialization.

Accepted JSON objects are saved unchanged to FSC's existing `WebhookTask`
table with `pending` status. A success response is sent only after persistence.
The HTTP handler awaits `verifyAndReceive()` directly: Octokit's Node middleware
would return 202 after its default nine-second timeout even before a task is
saved. Successful requests, including duplicates and ignored events, return
plain-text HTTP 200. Invalid signatures or payloads and missing delivery/event
headers return 400.
The unique delivery ID prevents concurrent redeliveries from creating multiple
tasks. Duplicate requests never reset task status; conflicting reuse of a
delivery ID returns 409. Storage failures return 503 without logging the raw
payload, secret, or SDK error (which can include operation variables).

After persistence, the receiver awaits `RequestWebhookTaskPlanning`, a privileged
mutation carrying only the task ID. This keeps raw webhook bodies out of the
planning event and below [Eventarc's event-size limit](https://cloud.google.com/eventarc/quotas).
A failed dispatch returns 503; redelivery reuses the saved task and signals it
again. Completed and failed tasks are never reset.

`createBuildJobs` listens only to that mutation and forwards the task ID to
[`process-webhook-task`](../dart_functions/README.md), a private Dart HTTP
Function. Node awaits completion and retries transient failures through Eventarc.
`PROCESS_WEBHOOK_TASK_URL` points to this Dart Function; the legacy polling
service has been removed.
The Dart Function owns the full planner: it reads the durable task, validates
GitHub metadata, resolves the active connection, obtains a repository-scoped
read-only installation token, fetches `openci/*.dart` at the webhook SHA, applies
the migrated AST parser, and saves the matching BuildJobs. Repository identity
and commit access are verified before source is fetched; source is never run.

`CompleteWebhookTask` atomically inserts all matching `QUEUED` BuildJobs and
completes the pending task. It supplies the team/installation from the stored
connection, server timestamps, `runCount: 0`, and `runsOn: macos-latest`.
Stable task/file IDs, a conditional task transition and one transaction prevent
duplicate batches, partial inserts and retries resetting existing jobs. This
mutation's returned `jobs` IDs trigger `queueBuildJobs`, which enqueues Cloud
Tasks for the [capacity dispatcher](BUILD_DISPATCH.md). The generated SDK does
not support bulk `_Data` inputs, so the bulk insert uses a parameterized
`jsonb_to_recordset` SQL statement inside the GraphQL transaction.

Deleted refs, unmatched workflows and installations without an active connection
complete with zero jobs. Invalid payloads/workflow configuration fail with a
sanitized reason. GitHub, parser and database outages leave tasks pending and
are retried by the mutation trigger. A received failure never logs private
source, raw payloads, tokens or SDK operation variables.

This preserves the existing planner's event/branch matching (PR base branch,
head SHA/branch for checkout). `whenChanged` evaluation and queued GitHub Checks
remain separate work. The [Cloud Run executor](BUILD_EXECUTOR.md) now handles
claimed FSC jobs through Orchard, including logs, billing, checks and crash
recovery. Validate deployment before switching the production webhook URL.
The local Compose stack no longer includes a build planner or executor; it does
not consume FSC jobs. Drain previously deployed polling containers before
upgrading the stack or switching execution paths.

## Local checks

From the repository root, using Node.js 22:

```sh
npm ci
npm run check --workspace firebase
npm test --workspace firebase
env -u DEBUG npx --yes firebase-tools@15.34.2 dataconnect:compile \
  --config firebase/dataconnect/firebase.json --project openci-b1b91
env -u DEBUG npx --yes firebase-tools@15.34.2 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test --test-concurrency=1 firebase/dataconnect/test/webhooks.test.mjs firebase/dataconnect/test/build_job_planning.test.mjs firebase/dataconnect/test/build_dispatch.test.mjs firebase/dataconnect/test/build_execution.test.mjs firebase/dataconnect/test/billing.test.mjs firebase/dataconnect/test/logs.test.mjs'
```

`dataconnect:compile` reads the deployed schema, so this read-only check uses
the real project and requires Google credentials. Fixture-writing emulator tests
always use `demo-openci`.

The pinned CLI does not emulate FSC mutation-event delivery. The planning tests
invoke the consumer directly, using the real SQL Connect emulator and Dart HTTP
Function; the production Eventarc handoff remains a deployment check.

Regenerate the connector SDK with `dataconnect:sdk:generate` using the same
configuration and `--project demo-openci`. Emulator startup also regenerates SDKs; apply the repository's
generated-code formatting described in `../dataconnect/README.md` afterward.

For an HTTP smoke test, build the Node Functions and configure dummy local values:

- `firebase/.secret.local`: dummy `GITHUB_WEBHOOK_SECRET` and `ORCHARD_SERVICE_ACCOUNT_TOKEN`.
- `firebase/.env.local`: `PROCESS_WEBHOOK_TASK_URL=http://127.0.0.1:5001/demo-openci/asia-northeast1/process-webhook-task`, `ORCHARD_API_URL=http://127.0.0.1:18080`, `ORCHARD_SERVICE_ACCOUNT_NAME=test`, and `BUILD_EXECUTOR_JOB=projects/demo-openci/locations/asia-northeast1/jobs/build-executor` (unused by the receiver smoke test).
- `firebase/dart_functions/.env.local`: `GITHUB_APP_ID=1`.
- `firebase/dart_functions/.secret.local`: `GITHUB_APP_PRIVATE_KEY` (unused by the receiver smoke test).

Then run:

```sh
env -u DEBUG FIREBASE_CLI_EXPERIMENTS=dartfunctions npx --yes firebase-tools@15.34.2 emulators:start \
  --config firebase/firebase.json --only functions,dataconnect --project demo-openci
```

Send signed JSON to
`http://127.0.0.1:5001/demo-openci/asia-northeast1/githubWebhookFsc` with the
`X-GitHub-Delivery`, `X-GitHub-Event`, and `X-Hub-Signature-256` headers.
Use only the `demo-openci` project for fixture-writing tests.

To run the HTTP integration tests automatically, set
`GITHUB_WEBHOOK_TEST_SECRET` to the same dummy value and use
`emulators:exec` with the same configuration and emulator selection, passing
`node --test firebase/functions/integration_test/github_webhook.test.mjs` as
the command.

## Deployment configuration

The receiver uses 256 MiB (128 MiB exceeded its limit during a production cold
start), the standard Gen2 allocation of 1 CPU, concurrency 1, minimum instances
0, and a 60-second
timeout. See the [Firebase runtime options](https://firebase.google.com/docs/functions/manage-functions#override_cpu_defaults).
The endpoint is publicly invokable because GitHub uses
the webhook signature, not a Google identity token, to authenticate deliveries.
Only the bound `GITHUB_WEBHOOK_SECRET` Secret Manager secret is read by the receiver.
Its value must match the GitHub App webhook secret.

Deploy the `webhooks` connector before the Function, and grant the runtime
service account permission to execute its privileged FSC operations. The
Function codebase is `openci` in `firebase/firebase.json`; its predeploy hook
builds the TypeScript. Build and deploy are separate actions.

The Node consumer needs `PROCESS_WEBHOOK_TASK_URL`, the full deployed Dart Function
URL. Grant its runtime service account `roles/run.invoker` on that Function;
invocation uses an ID token with that URL as its audience. Only an explicitly
local Functions emulator may use HTTP without a token. The consumer keeps 1 CPU,
256 MiB, concurrency 1, minimum instances 0, a 540-second timeout and retries.

GitHub App configuration and `GITHUB_APP_PRIVATE_KEY` now belong to the Dart
codebase. Its runtime service account needs permission to execute privileged
operations on the `github` and `webhooks` connectors. Deploy those connectors,
then the Dart planner, configure IAM and the URL, and deploy the Node dispatcher.
The Dart planner has a 480-second timeout and accepts up to 100 Dart files
totaling 1 MiB. See its README for configuration and the transitional Compose
launcher. Verify production Eventarc delivery, IAM, GitHub credentials and memory
headroom (256 MiB for Node, 128 MiB for Dart) before routing real webhook traffic.

See [deployment identities and rollout](DEPLOYMENT.md) for the runtime accounts,
IAM setup and production cutover requirements.

Before routing production traffic here, verify the complete consumer path and
cold-start response latency. GitHub expects a response within 10 seconds and
does not automatically redeliver failed deliveries; use GitHub redelivery for
failed or timed-out requests. See the official
[webhook best practices](https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks)
and [webhook documentation](https://docs.github.com/en/webhooks/using-webhooks).

Logs and Secrets now use FSC and Secret Manager. See [deployment and import order](LOGS_AND_SECRETS.md) before releasing the migrated clients or removing the old APIs.
