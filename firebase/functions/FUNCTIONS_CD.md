# Production Functions CD

`openci/firebase/functions_cd.dart` runs when a GitHub Release is published.
The Dart workflow lists dependency installation, formatting, analysis and tests.
It checks the TypeScript Functions and runs Dart analysis and tests
in `firebase/dart_functions` against the same commit. Firebase CLI 15.37.0
then deploys the TypeScript `openci` and Dart `openci-planner` codebases to
`openci-b1b91` under one lock. The CLI uses its `dartfunctions` experiment
to generate the planner manifest and compile the Linux executable.

The job builds and tests the tagged commit. After obtaining the shared lock,
it checks GitHub's latest stable release and verifies that its tag still resolves
to the tested commit. Jobs for other tags skip deployment. A newer release waits
for any deployment already in progress.

## Authentication and one-time activation

Use the dedicated service account
`openci-functions-cd@openci-b1b91.iam.gserviceaccount.com`. The script writes its
JSON key to a mode-0600 file outside the source tree and sets
`GOOGLE_APPLICATION_CREDENTIALS` for the Firebase CLI process. This is
[Application Default Credentials](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems).
The CLI uses an isolated configuration directory, with `FIREBASE_TOKEN` removed.
It sets `FIREBASE_SKIP_INFORMATIONAL_IAM=true` because the CLI otherwise requires
access to the default App Engine account during its preliminary check. Google
Cloud authorizes each deployment using the configured runtime and build identities.
Temporary files are deleted on normal exit or failure; executor VM destruction
removes them after an abrupt interruption.

Provision these resources before enabling the workflow:

1. The dedicated deployment service account. Grant the permissions required for
   [Firebase Functions deployment](https://firebase.google.com/docs/projects/iam/permissions),
   including Functions administration and `iam.serviceAccounts.actAs` on the
   Functions' runtime/build service accounts, including the planner identity.
   The deployment account needs permission to update the planner Cloud Run
   service and read and set its invocation policy. Scope access to existing runtime
   Secret Manager metadata and any trigger/build services as required by the
   current deployment. Do not give it Owner or Editor. Verify these permissions
   with a supervised deployment before enabling automatic production changes.
2. A private bucket named `openci-b1b91-functions-cd`, with uniform bucket-level
   access and public access prevention enforced. Grant the deployment account
   `roles/storage.objectAdmin` on this bucket only. Do not configure lifecycle
   deletion of the lock object. The bucket stores deployment metadata, not keys.
3. Two infrastructure-owned Secret Manager secrets containing, respectively,
   the Base64-encoded SA JSON and the Base64-encoded complete production dotenv
   configuration for `firebase/.env.openci-b1b91`. Encode without line wrapping.
   Keep runtime secrets such as GitHub private keys in their existing bindings;
   the dotenv file contains the reviewed runtime configuration and parameter
   values. The Dart dotenv receives the shared GitHub App ID and any configured
   GitHub URLs, Data Connect service ID or planner runtime account.
   `OPENCI_PLANNER_INVOKER` is set to the Node API service account from
   `OPENCI_API_SERVICE_ACCOUNT` (default `openci-functions` in this project).
   The planner continues to read its GitHub private key from Secret Manager.
4. Grant the executor's service account access to those two secret versions and
   configure the following **executor Cloud Run Job** environment variables:

   | Variable                            | Value                                                       |
   | ----------------------------------- | ----------------------------------------------------------- |
   | `OPENCI_FUNCTIONS_CD_TEAM_ID`       | The verified OpenCI team's ID                               |
   | `OPENCI_FUNCTIONS_CD_REPOSITORY_ID` | The numeric GitHub ID of `openci-org/openci`                |
   | `OPENCI_FUNCTIONS_CD_SA_VERSION`    | `projects/openci-b1b91/secrets/SECRET_NAME/versions/NUMBER` |
   | `OPENCI_FUNCTIONS_CD_ENV_VERSION`   | `projects/openci-b1b91/secrets/SECRET_NAME/versions/NUMBER` |

   Use numeric secret versions, not `latest`. Rotate keys/configuration by
   publishing a new version and updating the corresponding executor setting.

5. Deploy the `webhooks` and `dispatch` SQL Connect connectors so release jobs
   carry their verified tag into the executor. Then deploy the updated executor
   image before publishing a release with this workflow. Require CI on PRs and
   restrict direct pushes to `develop`.

Do **not** register either CD credential in the team's ordinary OpenCI Secrets.
The executor filters `FIREBASE_FUNCTIONS_CD_SERVICE_ACCOUNT_JSON_BASE64` and
`FIREBASE_FUNCTIONS_CD_ENV_BASE64` out of ordinary secrets, even when CD is disabled.
It loads the infrastructure versions only for the configured team/repository,
GitHub.com and the exact workflow path `firebase/functions_cd.dart` or its
original path `firebase_functions_cd.dart`. The executor requires a tag recorded
from the Release webhook and checks that the tagged commit is in `develop` history
before loading either secret.

## Deployment coordination and completion

The script atomically creates `production/openci/lock.json` using Cloud Storage's
`ifGenerationMatch=0`. A waiting job retries for up to 20 minutes. The lock has
no automatic expiration: a stopped Firebase CLI may still have cloud operations
in progress. Unlocking uses the acquired object's exact generation.

The single deployment helper, `firebase/scripts/deploy-functions.mjs`, handles
ADC files, the shared lock, Firebase CLI execution and the smoke check. The
workflow selects the Node version in `.node-version` using
`openci/tool/with_node.sh`. On `base-macos` it can use the existing mise
installation even when the initial workflow PATH has no Node or npm. The
helper verifies the Node distribution checksum when a download is needed.
The selected Node installation's npm runs the version in `package.json`'s
`packageManager`. The workspace scripts use the lockfile's Vite+ for formatting,
lint and Vitest. At deployment time, npm runs the `firebase` executable from the
pinned `firebase-tools` package.

The script passes `--non-interactive` and never passes `--force`. Removed or
renamed Functions that require deletion must be handled in a separate reviewed
rollout. It refuses to overwrite existing local dotenv or generated config files;
run it in a clean checkout. Node, npm and Firebase CLI versions are pinned.

After deployment, a GET to `githubWebhookFsc` must return 405. An anonymous
GET to the configured planner URL must return 403, and the planner service's
invocation policy must grant the Node API account access. Both probes use GET
to avoid creating a task or build. Once these checks pass, CD records the
tag, commit and run identity in `production/openci/last-success.json` and releases
the lock.

Deploy any required SQL Connect schema and connector changes before publishing
the release. Keep them compatible with both current and next Functions.
Keep Node and planner interface changes compatible during the rollout. Firebase
can update the two codebases at different times within one deployment.

## Failure and recovery

A failure before starting Firebase CLI releases the lock. Once CLI execution
starts, any deploy, probe or success-record failure retains the lock and blocks
later production updates. A multi-function deployment can be partially applied;
failure does not mean the previous version is still serving everywhere.

1. Inspect the failed run and Google Cloud Functions build/update operations.
   Confirm the old CLI/VM has stopped and all cloud operations have completed.
2. Inspect `last-success.json` and the deployed revisions. Repair forward or
   revert the change through a PR, then publish a new release with the repair.
3. Only after reconciling the actual deployment, remove the lock with an object
   generation precondition. Rerun the job for GitHub's latest stable release if needed.

If OpenCI itself cannot start builds, use a clean checkout of the known-good
commit and the same SA/ADC. Prepare both project dotenv files, including the
Node caller in `firebase/dart_functions/.env.openci-b1b91`. Run the Functions
checks, then run Firebase CLI 15.37.0 with `FIREBASE_CLI_EXPERIMENTS=dartfunctions`
and `FIREBASE_SKIP_INFORMATIONAL_IAM=true`,
`--config firebase/firebase.json --project openci-b1b91
--only functions:openci,functions:openci-planner --non-interactive`. Keep the
shared lock held during recovery and confirm the cloud operations and both
services' checks before releasing it. Restoring Functions does
not revert database migrations or application data.

## Local verification

From the repository root, using Flutter 3.47.8:

```sh
flutter pub get
bash openci/tool/with_node.sh bash firebase/scripts/ci.sh
```

From both `firebase/dart_functions/` and `openci/`, run `dart analyze --fatal-infos`
and `dart test`. The deployment tests cover codebase selection, planner access,
superseded releases, moved tags, lock contention, partial failures and
credential-file cleanup using fake cloud responses.
