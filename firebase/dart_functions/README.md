# Dart build job planner Functions

The private Firebase HTTP Function `process-webhook-task` receives only a task
ID. It reads the saved webhook from FSC, validates GitHub metadata, resolves the
active GitHub connection, obtains a repository-scoped installation token, fetches
`openci/*.dart` at the webhook SHA, and applies the migrated Dart AST parser.
It atomically inserts the matching `QUEUED` jobs and completes the task through
the privileged FSC connector operations. Source code is never executed.

The Node `createBuildJobs` mutation trigger only invokes this Function with an
ID token and awaits completion. It owns Eventarc retries. Transient GitHub/FSC
failures leave the task pending; invalid payloads and workflow configurations
are marked failed. Concurrent calls and lost completion responses are reconciled
without inserting duplicate jobs or resetting existing jobs.

`planJobs` and the parser/payload tests cover the workflow planning rules.
PRs match the base branch
and use the head SHA/branch for checkout. `whenChanged` validation and path
matching helpers are retained; evaluating changed paths remains separate work.
Execution-slot reservation belongs to the [dispatcher](../functions/BUILD_DISPATCH.md).
The [Cloud Run executor](../functions/BUILD_EXECUTOR.md) runs builds and updates
GitHub Checks.

## Runtime configuration

The Function uses Tokyo, 1 CPU, 128 MiB, concurrency 1, minimum instances 0,
a 480-second timeout and private invocation. Configure these in this codebase:

- `GITHUB_APP_ID` and Secret Manager `GITHUB_APP_PRIVATE_KEY`.
- `GITHUB_API_BASE_URL` (default `https://api.github.com`) and `GITHUB_BASE_URL`
  (default `https://github.com`); the host/App must match the FSC connection.
- The Firebase CLI supplies `GCLOUD_PROJECT`. FSC service/location are
  `openci-b1b91-service` / `asia-northeast1`.

FSC access uses `googleapis_auth` Application Default Credentials with the
runtime service account, calling `impersonateQuery` / `impersonateMutation`
without user impersonation, as the Node Admin SDK does. Grant that account
permission to execute privileged operations on the `webhooks` and `github`
connectors. Grant the calling Node Function's service account `roles/run.invoker`
on this Function and set its URL as `PROCESS_WEBHOOK_TASK_URL` in the Node codebase.
Only a loopback SQL emulator with a `demo-*` project and `FUNCTIONS_EMULATOR=true`
can bypass Google authentication. GitHub HTTP is also limited to loopback in
emulator mode. Requests, error responses and logs exclude source and tokens.

Dart Functions are [experimental](https://firebase.google.com/docs/functions/start-dart).
`firebase_functions` is pinned to 0.6.0 for the existing analyzer 12 parser;
0.8 requires analyzer 13+. SDK 0.6 emits a secret's variable identifier as its
Secret Manager name, so the binding in `bin/server.dart` deliberately matches
`GITHUB_APP_PRIVATE_KEY`. Verify the generated manifest when upgrading.

## Local validation

From the repository root, run `flutter pub get`. Then from this directory:

```sh
dart analyze --fatal-infos
dart test
dart run build_runner build --build-filter=functions.yaml
dart format --output=none --set-exit-if-changed .
dart compile exe bin/server.dart -o bin/server --target-os=linux --target-arch=x64
```

The FSC integration test runs this actual Dart Function against the SQL Connect
emulator and a local GitHub HTTP fixture. It covers token scope, commit selection,
AST matching, atomic inserts, concurrent deliveries, retries and permanent
failures. See [the Node Functions README](../functions/README.md) for commands.
The pinned CLI does not emulate FSC mutation-event delivery, so Eventarc/IAM
and 128 MiB memory headroom still require deployed validation.

## Deployment

From the repository root, after deploying the `webhooks` and `github` connectors:

```sh
FIREBASE_CLI_EXPERIMENTS=dartfunctions npx --yes firebase-tools@15.34.2 deploy \
  --config firebase/firebase.json --project openci-b1b91 \
  --only functions:openci-planner
```

The CLI generates the manifest and compiles the Linux binary locally. No custom
Docker image or separate Cloud Run definition is needed for this Function.
Local tests do not deploy it.

The legacy polling launcher and its API adapters have been removed. This package
plans FSC webhook tasks through the Firebase Function entry point only.
