# Legacy server retirement (G-1607)

The legacy services on `openci-worker-01` were retired on 2026-10-31 JST after
the [FSC production cutover](DEPLOYMENT.md). Production now uses Firebase
Functions, Data Connect, Cloud Run and the GCP Orchard controller.

## Resources removed

The following seven containers were removed after confirming the legacy writers
were stopped and the old controller had no VMs:

- `openci-server`
- `openci-genuineci-server-1`
- `openci-build-job-planner`
- `openci-build-job-worker`
- `openci-db`
- `openci-loki`
- `openci-orchard-controller`

The named volumes `openci_postgres_data`, `openci_loki_data` and
`openci_orchard_data`, and the empty Compose network `openci_default`, were
removed after backup verification. The old checkout's five Compose files,
`.env`, Firebase service-account file and GitHub private key were archived and
removed from their deployment locations. `RETIRED.md` marks the old checkout.

The host itself, Docker images/cache, SSH, Tailscale and the SSH-only Cloudflare
tunnel remain. There are no remaining Docker containers or volumes on that host;
ports 8080, 8081, 5432, 3100 and 6120 are no longer listening. This retirement does
not delete the host VM or stop its management access.

## Backup and recovery evidence

Two private copies are retained:

- Old host: `/home/ubuntu/openci/backups/fsc-retirement-20261031`.
- Operator Mac: `~/Backups/openci/fsc-retirement-20261031`.

The off-host copy contains 16 manifest-listed files, totaling 210,930,076 bytes.
All file sizes and SHA-256 hashes matched after copying. Directories are private
to the operator; the archives contain credentials and are not committed to Git.

The backup includes a final PostgreSQL custom-format dump and role definitions,
all three stopped data volumes, container/image metadata, the deployment files,
the original cutover backup, and a verified Git bundle of the old checkout at
`dd865bbf221c3ebf4f9fcaff097cf91028a6c0ee`.

`source.dump` has SHA-256
`5e45be86fd37615fc53bacb5f23fba72eb8c04f06deb077c1e469bc5d3622330`.
It was restored into an isolated PostgreSQL 16 container with no network and
temporary in-memory storage using `pg_restore --exit-on-error --no-owner
--no-acl`. Row counts and SHA-256 hashes of sorted row JSON matched for all 22
public tables. The verification container was then removed. Compressed archives
also passed integrity checks.

`manifest.json`, `restore-verification.json`, `off-host-verification.json` and
`retirement-verification.json` record the checks and removed resources. Recover
data into an isolated PostgreSQL 16 instance first. The legacy snapshot predates
ongoing FSC writes: restoring it does not restore the current production ledger.
Do not restart legacy writers without reconciling subsequent FSC changes and
explicitly planning another cutover. Historical Loki logs were not imported into
FSC, as agreed for the migration.

## Code and client cleanup

The `apps/openci_server` and `apps/genuineci_server` packages, their CI workflows,
Compose stack, shared REST client and unused Dashboard client providers were
removed. `genuineci dev start` was tied to that stack and was removed; standalone
Firebase Auth emulator development remains available through
[`firebase/README.md`](../README.md).

The old server's macOS download links were removed from the landing page.
Dashboard's updater now requires an explicit `OPENCI_MACOS_UPDATE_FEED_URL`
instead of deriving a legacy `/updates` endpoint. Existing connection profile
identities and preference migration remain supported.

## Verification and remaining operations

Before stopping the old controller, its six worker registrations were paused and
it had no VMs. The new GCP controller reported all six workers recently seen and
no VMs. After retirement, its certificate-verified HTTPS endpoint still rejected
anonymous requests with 401. Dashboard returned 200, the GitHub webhook rejected
a request missing required headers with 400, and `teamBilling` rejected an
unauthenticated callable request with 401.

Fresh authenticated GCP/Data Connect reads could not be repeated after retirement
because the local gcloud/Firebase credentials required reauthentication. These
availability checks are not a new end-to-end build or payment verification;
the earlier production checks are recorded in [DEPLOYMENT.md](DEPLOYMENT.md).

GCP Controller data-disk backups and Tailscale key renewal remain separate
operational follow-ups in [the Controller runbook](../../infra/orchard/README.md).
