# Logs and Secrets migration

The dashboard reads build jobs, steps and logs from Firebase SQL Connect (FSC).
Secret values live in Secret Manager; FSC stores names and numeric version paths.
Neither feature requires `openci_server` after this cutover. Past Loki logs are
not imported. Keep the legacy SQL `secrets` table until migration is verified.
Keep `SECRET_ENCRYPTION_KEY` through the import and rollback window. Legacy
GitHub token rows may also need it; the new [GitHub connection flow](GITHUB_CONNECTION.md)
uses Secret Manager and does not require that key.

## Runtime

- `GetBuildJobs` and `GetBuildJob` authorize the signed-in user's team membership.
  The dashboard subscribes through the Firebase app of the selected connection.
- `GetBuildLogState` subscribes to one team/job/run. The log reader fetches pages
  of 200 entries after the last sequence, retains identical messages, drains the
  final page on completion, and retries transient page failures. It stops and
  cancels its subscription when the run completes or the screen is disposed.
- The executor continues capturing Orchard stdout/stderr and writing logs with
  the existing redaction and sequence handling. Workflow commands print to these
  streams; they no longer send requests to Loki. Steps are the executor's
  `prepare_vm`, `checkout` and `run_workflow` steps; this change does not add
  per-command workflow steps.
- `expireBuildLogs` runs every five minutes. It deletes at most 500 log bodies
  from each of 20 completed, expired runs. It preserves job/run/step metadata.
  The executor already sets a 14-day expiry. The next sweep resumes the backlog.
- `teamSecrets` is a Gen2 callable in `asia-northeast1`, with 256 MiB, 1 CPU and
  concurrency 1. It requires a non-anonymous Firebase ID token and membership in
  the requested team. Mutations recheck membership inside their FSC transaction.
  All team members retain the same management access as the old API.
- Supported actions: `list`, `read`, `save`, `rename`, `delete`, and
  `generateCertificateKey`. `rename` can include `value` to update both atomically.
  Clients supply names/values, never Secret Manager resource paths.
- Each new value creates an owned Secret Manager resource/version. A transaction
  swaps the metadata reference only if the previous reference still matches.
  Creation is limited to 100 names per team; values are exact UTF-8, at most
  64 KiB each, without NUL. The executor additionally enforces 512 KiB total per
  build; the import tool validates that aggregate limit before any writes.
- `OPENCI_*`, `LOKI_*`, and shell/runtime environment names are reserved, except
  the four existing generated iOS/ASC names. iOS key generation reuses a saved key.
- Superseded/deleted versions and uncommitted candidates enter a cleanup queue.
  `cleanSecretVersions` waits at least 24 hours and checks references again before
  requesting destruction. Owned resources use Secret Manager's seven-day delayed
  destruction. Versions still referenced in FSC are deferred; unowned resources
  are not destroyed. Secret Manager creation and the queue are separate services:
  a crash between them can leave an orphan, so inspect resources labelled
  `openci-managed=true` during operational cleanup before deleting anything.

## Deploy and migrate in order

Do not deploy the server endpoint removal or distribute the new clients before
steps 1–4. Existing deployed clients continue using the old API during preparation.
The old Loki volume/database are not deleted by this source change.

1. Deploy the FSC schema and connectors from `firebase/`. This adds
   `SecretVersionCleanup` and the new queries/mutations; it does not drop the old
   SQL secrets table. Confirm all source teams exist in FSC with the same IDs.
2. Set `SECRET_MANAGER_PROJECT` for Functions to the same project used by the
   executor (otherwise the function defaults to its Firebase project). Grant the
   Functions runtime identity FSC admin access, Secret Manager create/add/access,
   get metadata/version, and destroy-version permissions. Keep the executor's
   existing read access. The operator running the import also needs FSC admin,
   Secret Manager create/add/access and source PostgreSQL read access.
3. Deploy `teamSecrets`, `cleanSecretVersions`, and `expireBuildLogs`. Deploy the
   executor image containing the four generated-name exceptions. Verify team
   membership checks with two test accounts before switching clients.
4. Run the dry run below. Pause writes to the old Secrets API during the apply
   run, run the import, then run apply a second time: `imported` must be zero and
   `unchanged` must equal `validated`. The tool verifies the exact value and
   reference after each new import. It never overwrites a differing destination.
5. Release the dashboard and CLI. Verify list/read/save/rename/delete, iOS key
   reuse, one real build using an imported multiline secret, repeated log lines,
   live updates and final output. Verify that no secret values appear in logs.
6. Deploy the server version without the old log/Secrets routes and remove Loki
   from the running Compose stack. Retain the legacy database backup and key for
   the rollback window. No historical log transfer is needed.

For rollback before retiring the old service, restore the old client/server
release. Secrets created or changed after cutover only exist in Secret Manager;
reconcile those explicitly before restoring an old Secrets writer. An apply run
with conflicting values stops rather than silently choosing a source.

## Secret import tool

Build from the repository root:

```sh
npm run build --workspace firebase
```

Provide these through the operator's secure environment; do not paste their
contents into logs or command arguments:

- `LEGACY_DATABASE_URL`: read access to the old PostgreSQL database.
- `LEGACY_SECRET_ENCRYPTION_KEY`: the existing base64 AES-256 key.
- `SECRET_MANAGER_PROJECT`: the executor's Secret Manager project ID.
- Application Default Credentials for the destination Firebase/GCP project.

```sh
# Read-only by default; decrypts and validates the entire stable source snapshot.
node firebase/lib/functions/secrets/migrate.js

# Creates missing destination values, verifies them, and skips exact matches.
node firebase/lib/functions/secrets/migrate.js --apply
```

The tool reads a repeatable-read, read-only PostgreSQL snapshot, pages by
`(team_id, name)`, and validates all names/counts/sizes before creating any values.
It prints counts, never plaintext, encrypted values, or credentials. A failed
apply may leave already imported entries; rerunning is safe while old writes are
paused. Invalid legacy names must be corrected before migration. Metadata
creation/update timestamps in the destination reflect the import time.

## Client configuration and local validation

The dashboard uses the active connection's Firebase app, with Functions in
`asia-northeast1`. Local mode uses FSC port 9399 and Functions port 5001.
The CLI infers the Firebase project from the ID token's `aud`; existing Firebase
login profiles remain usable. A legacy static API key needs a new Firebase login.
Optional profile keys are `firebase_project_id`, `functions_region`, and
`functions_emulator_host`. Auth Emulator profiles default to Functions on the
same loopback host, port 5001. Non-loopback emulator endpoints are rejected.

Secret Manager has no local emulator in this setup. Local unit tests inject a
vault implementation; live callable/Secret Manager/IAM tests require a test GCP
project. The FSC integration suite refuses non-loopback emulator targets.

```sh
env -u DEBUG firebase emulators:start --only dataconnect \
  --config firebase/dataconnect/firebase.json --project demo-openci
DATA_CONNECT_EMULATOR_HOST=127.0.0.1:9399 node --test --test-concurrency=1 firebase/dataconnect/test/*.test.mjs
npm run test --workspace firebase
```

Also run Dashboard, CLI, shared package, workflow SDK and server Dart tests and
analysis. SDKs must be regenerated after changing connector operations.
