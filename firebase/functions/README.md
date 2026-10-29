# GitHub webhook receiver

`githubWebhook` is a second-generation HTTPS Function in `asia-northeast1`.
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

This is the intake portion of the migration. Workflow discovery, BuildJob
creation, execution-slot reservation, Cloud Run Jobs, and completion handling
are subsequent work. The current Dart planner reads the existing server's
database, so it does not automatically consume these FSC tasks. Keep the
production webhook URL on the existing receiver until the FSC consumer is ready.

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
  'node --test firebase/dataconnect/test/webhooks.test.mjs'
```

`dataconnect:compile` reads the deployed schema, so this read-only check uses
the real project and requires Google credentials. Fixture-writing emulator tests
always use `demo-openci`.

Regenerate the connector SDK with `dataconnect:sdk:generate` using the same
configuration and `--project demo-openci`. Emulator startup also regenerates SDKs; apply the repository's
generated-code formatting described in `../dataconnect/README.md` afterward.

For an HTTP smoke test, set a dummy `GITHUB_WEBHOOK_SECRET` in the ignored file
`firebase/.secret.local`, build the Functions, and run:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.2 emulators:start \
  --config firebase/firebase.json --only functions,dataconnect --project demo-openci
```

Send signed JSON to
`http://127.0.0.1:5001/demo-openci/asia-northeast1/githubWebhook` with the
`X-GitHub-Delivery`, `X-GitHub-Event`, and `X-Hub-Signature-256` headers.
Use only the `demo-openci` project for fixture-writing tests.

To run the HTTP integration tests automatically, set
`GITHUB_WEBHOOK_TEST_SECRET` to the same dummy value and use
`emulators:exec` with the same configuration and emulator selection, passing
`node --test firebase/functions/integration_test/github_webhook.test.mjs` as
the command.

## Deployment configuration

The receiver uses 128 MiB (the smallest supported memory setting), the standard
Gen2 allocation of 1 CPU, concurrency 1, minimum instances 0, and a 60-second
timeout. See the [Firebase runtime options](https://firebase.google.com/docs/functions/manage-functions#override_cpu_defaults).
The endpoint is publicly invokable because GitHub uses
the webhook signature, not a Google identity token, to authenticate deliveries.
Only the bound `GITHUB_WEBHOOK_SECRET` Secret Manager secret is read at runtime.
Its value must match the GitHub App webhook secret.

Deploy the `webhooks` connector before the Function, and grant the runtime
service account permission to execute its privileged FSC operations. The
Function codebase is `openci` in `firebase/firebase.json`; its predeploy hook
builds the TypeScript. Build and deploy are separate actions.

Before routing production traffic here, verify the complete consumer path and
cold-start response latency. GitHub expects a response within 10 seconds and
does not automatically redeliver failed deliveries; use GitHub redelivery for
failed or timed-out requests. See the official
[webhook best practices](https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks)
and [webhook documentation](https://docs.github.com/en/webhooks/using-webhooks).
