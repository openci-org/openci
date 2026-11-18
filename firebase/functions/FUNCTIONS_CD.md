# Production TypeScript Functions CD

`openci/firebase_functions_cd.dart` runs on every push to `develop`. Dependency
installation, formatting, analysis and tests are listed directly in the Dart
workflow, without shell-script wrappers. It runs the existing Functions checks
against the checked-out commit, then uses Firebase CLI
15.34.2 to deploy only the `openci` codebase to `openci-b1b91`. The temporary
Firebase configuration contains only that TypeScript codebase. Dart planner,
Hosting, Data Connect and the Cloud Run executor are separate deployments.

Every push gets a job, including changes unrelated to Functions. After obtaining
the shared lock, the job checks the live `develop` ref and skips if superseded.
This prevents an older queued job from overwriting a newer deployment. It also
ensures a newer documentation-only push still deploys preceding Functions
changes. No newer push cancels an in-progress deployment.

## Authentication and one-time activation

Use the dedicated service account
`openci-functions-cd@openci-b1b91.iam.gserviceaccount.com`. The script writes its
JSON key to a mode-0600 file outside the source tree and sets
`GOOGLE_APPLICATION_CREDENTIALS` for the Firebase CLI process. This is
[Application Default Credentials](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems).
The CLI uses an isolated configuration directory, with `FIREBASE_TOKEN` removed.
Temporary files are deleted on normal exit or failure; executor VM destruction
removes them after an abrupt interruption.

Provision these resources before enabling the workflow:

1. The dedicated deployment service account. Grant the permissions required for
   [Firebase Functions deployment](https://firebase.google.com/docs/projects/iam/permissions),
   including Functions administration and `iam.serviceAccounts.actAs` on the
   Functions' runtime/build service accounts. Scope access to existing runtime
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
   values. Missing required parameters fail the job before deployment.
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

5. Deploy the updated executor before merging/enabling the CD workflow. The
   Functions CD does not update the executor image, so this is a separate
   bootstrap step. Require CI on PRs and restrict direct pushes to `develop`.

Do **not** register either CD credential in the team's ordinary OpenCI Secrets.
The executor filters `FIREBASE_FUNCTIONS_CD_SERVICE_ACCOUNT_JSON_BASE64` and
`FIREBASE_FUNCTIONS_CD_ENV_BASE64` out of ordinary secrets, even when CD is disabled.
It loads the infrastructure versions only for the configured team/repository,
GitHub.com, a verified `develop` push, and `firebase_functions_cd.dart`. PRs,
other branches/workflows, other repositories/teams and self-hosted instances do
not receive them. A Dart `if` alone is not the credential access boundary.

## Deployment coordination and completion

The script atomically creates `production/openci/lock.json` using Cloud Storage's
`ifGenerationMatch=0`. A waiting job retries for up to 20 minutes. The lock has
no automatic expiration: a stopped Firebase CLI may still have cloud operations
in progress. Unlocking uses the acquired object's exact generation.

The single deployment helper, `firebase/scripts/deploy-functions.mjs`, handles
ADC files, the shared lock, Firebase CLI execution and the smoke check. The
workflow reads `.node-version` and `package.json`'s `packageManager`, and uses
`npx --package` to run every command with those pinned Node/npm versions. The
worker needs an existing `npx` executable to bootstrap them.

The script passes `--non-interactive` and never passes `--force`. Removed or
renamed Functions that require deletion must be handled in a separate reviewed
rollout. It refuses to overwrite existing local dotenv or generated config files;
run it in a clean checkout. Node, npm and Firebase CLI versions are pinned.

After deployment, a GET to `githubWebhookFsc` must return the handler's expected
405 response. This checks startup/routing without creating a webhook or build;
it is not an end-to-end test of planning, billing or dispatch. Only then does the
script write the commit/run identity to `production/openci/last-success.json`
and release the lock. GitHub Checks reports the workflow outcome as usual.

Data Connect schema/connector changes must be deployed and remain compatible
with both current and next Functions before the dependent Functions changes
reach `develop`. This workflow intentionally does not apply database migrations.
Likewise, coordinate interface changes with the separately deployed Dart planner.

## Failure and recovery

A failure before starting Firebase CLI releases the lock. Once CLI execution
starts, any deploy, probe or success-record failure retains the lock and blocks
later production updates. A multi-function deployment can be partially applied;
failure does not mean the previous version is still serving everywhere.

1. Inspect the failed run and Google Cloud Functions build/update operations.
   Confirm the old CLI/VM has stopped and all cloud operations have completed.
2. Inspect `last-success.json` and the deployed revisions. Repair forward or
   revert the change through a PR; a revert commit is a new `develop` commit and
   can pass the same checks. Re-running an older job intentionally skips it.
3. Only after reconciling the actual deployment, remove the lock with an object
   generation precondition. Rerun the newest `develop` CD job.

If OpenCI itself cannot start builds, use a clean checkout of the known-good
commit, the same SA/ADC and complete production dotenv configuration, run the
Functions checks, then run Firebase CLI 15.34.2 manually with
`--config firebase/firebase.json --project openci-b1b91 --only functions:openci
--non-interactive`. Keep the shared lock held during recovery and confirm the
cloud operations and smoke check before releasing it. Restoring Functions does
not revert database migrations or application data.

## Local verification

From the repository root, using Flutter 3.47.8:

```sh
flutter pub get
npx --yes --package=node@22.23.4 --package=npm@11.14.1 npm ci --workspace firebase --include-workspace-root
npx --yes --package=node@22.23.4 --package=npm@11.14.1 npm run fmt:check --workspace firebase -- healthcheck.ts functions scripts
npx --yes --package=node@22.23.4 --package=npm@11.14.1 npm run check --workspace firebase
npx --yes --package=node@22.23.4 --package=npm@11.14.1 npm test --workspace firebase
npx --yes --package=node@22.23.4 --package=npm@11.14.1 npm run test:workflow-context --workspace firebase
```

From `openci/`, run `dart analyze --fatal-infos` and `dart test`. The Functions
tests exercise denied credential scopes, TS-only CLI configuration, stale commits,
lock contention, partial failures and credential-file cleanup with fake cloud
responses; they do not deploy or require production credentials.
