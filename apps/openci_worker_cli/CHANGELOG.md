## 0.4.34 - 2026-02-23

- fix: bump version to 0.4.34

## 0.4.31 - 2026-02-19

- feat: auto-provision distribution certificate secrets for `ios-sign` steps
  - Automatically creates GCP Secret Manager secrets and Firestore `secrets_v0` entries when missing
  - Updates workflow `requiredSecrets` so subsequent builds reuse existing secrets
- feat: pass `{KEY}_SECRET_PATH` env var for each secret to enable in-VM secret updates
- feat: gracefully handle empty or missing secrets (return empty string instead of crashing)
- change: add `OPENCI_` prefix to distribution certificate env vars

## 0.4.30 - 2026-02-19

- feat: support build cancellation from dashboard
- Worker checks Firestore status before each step and aborts if cancelled
- GitHub Check Run is marked as `cancelled` instead of `failure`

## 0.4.29 - 2026-02-19

- feat: add `$OPENCI_RUN_NUMBER` built-in environment variable (auto-incremented per team)
- remove: per-variable `autoIncrement` flag (replaced by team-level `runNumber`)

## 0.4.28 - 2026-02-18

- fix: version constant was not updated before publish, causing update loop

## 0.4.27 - 2026-02-18

- fix: remove unused comments

## 0.4.26 - 2026-02-18

- feat: auto-update via Firestore version check
- Workers automatically detect new versions from `worker_config_v0/latest_version` and self-update + restart

## 0.4.25 - 2026-02-18

- feat: auto-increment support for environment variables
- Environment variables with auto-increment enabled are atomically incremented via Firestore transaction after each build

## 0.4.24 - 2026-02-18

- feat: support team environment variables from dashboard
- Environment variables set in the "Env Vars" tab are now automatically injected into every workflow step

## 0.4.23 - 2026-02-17

- feat: remove `--project-id` option; project ID is now auto-read from service account JSON
- fix: improve `--update` command reliability

## 0.4.22 - 2026-02-17

- feat: rename executable from `openci_worker_cli` to `openci_worker`
- feat: add `--update` (`-u`) flag for self-update via `dart pub global activate`

## 0.4.21 - 2026-02-17

- fix: `tart run` failure (e.g., VM not found) no longer crashes the entire worker process
- fix: VM startup errors are now caught and properly reported as job failure

## 0.4.20 - 2026-02-17

- fix: prevent race condition where multiple workers on the same machine could delete each other's VMs
- add: `--worker-id` option to isolate VM management per worker
- add: startup cleanup of orphaned VMs belonging to this worker
- add: worker ID is now displayed in the waiting spinner log

## 0.4.19 - 2026-02-11

- add: built-in environment variables: #OPENCI_TAG & #OPENCI_TAG_VERSION

## 0.4.18 - 2026-02-10

- fix: CLI checkouts

## 0.4.17 - 2026-02-10

- fix: flutter path

## 0.4.16 - 2026-02-05

- fix: OpenCI Worker CLI doesn't get the correct workflow

## 0.4.15 - 2026-02-05

- fix

## 0.4.14 - 2026-02-05

- update tart VM base image name

## 0.4.13 - 2026-02-03

- fix: Worker CLI now checkout the assigned commit SHA.

## 0.4.12 - 2026-02-03

- fix: Worker CLI now checkout the assigned commit SHA.

## 0.4.11 - 2026-02-03

- feat: throw exception when command fails

## 0.4.10 - 2026-02-01

- fix: Worker CLI now processes jobs in ascending order (oldest first).

## 0.4.9 - 2026-01-31

- Update build job and run logging to use Firestore subcollections.

## 0.4.8 - 2026-01-31

- Fix missing executable in pubspec.yaml

## 0.4.7

- Reduce polling interval.
- Improve logging.

## 0.4.6

- Add support for multiple commands in a step.

## 0.4.5

- Support dynamic VM cloning and cleanup per job.
- Support custom working directories.

## 0.4.4

- Support multiple commands in a step.

## 0.4.3

- Update README.

## 0.4.2

- Add continuous job polling with atomic job claiming via Firestore transactions and explicit status updates.

## 0.4.1

- Add Firebase Admin SDK support.

## 0.4.0

- Initial version.
