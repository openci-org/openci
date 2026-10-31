# Firebase SQL Connect

SQL Connect is the production store for team, build, billing, log and credential
metadata. The service has 23 tables and eight connectors. See [the schema
inventory](SCHEMA.md) for relationships, timestamp units and retention rules.
The legacy servers and their one-time data import tools have been retired.

## Connectors and callers

| Connector  | Current callers                     | Client access                                                                               |
| ---------- | ----------------------------------- | ------------------------------------------------------------------------------------------- |
| `teams`    | Dashboard and team-member Functions | `GetMyTeams`, `GetTeamMembers`, `CreateTeam`, `RenameTeam`; member writes use Functions     |
| `builds`   | Dashboard                           | `GetBuildJobs` and `GetBuildJob`, scoped to the authenticated member                        |
| `logs`     | Dashboard and Cloud Run executor    | `GetBuildLogState` and `GetBuildLogs`; writes, retention and recovery reads are server-only |
| `secrets`  | Dashboard and Secrets Functions     | `GetSecrets` exposes names and timestamps only; values and writes use Functions             |
| `github`   | GitHub Functions and Dart planner   | All operations are server-only                                                              |
| `billing`  | Billing Functions and executor      | All operations are server-only                                                              |
| `webhooks` | Webhook receiver and Dart planner   | All operations are server-only                                                              |
| `dispatch` | Dispatch Functions and executor     | All operations are server-only                                                              |

Client operations require a non-anonymous Firebase user and check team membership
or the relationship between the requested team, job and run. `NO_ACCESS`
operations require Admin access; their presence in a generated SDK does not grant
client permission. Functions derive actor IDs from verified Firebase identities.

## Generated SDKs

`teams`, `builds`, `logs` and `secrets` generate Dart SDKs under
`apps/dashboard/lib/generated`. All eight connectors generate Node Admin SDKs
under `firebase/generated`, linked from the Firebase npm workspace.
Billing and GitHub use callable Functions and do not generate Dashboard SDKs.

From the repository root, with Node.js 22:

```sh
env -u DEBUG npx --yes firebase-tools@15.34.1 dataconnect:sdk:generate \
  --config firebase/dataconnect/firebase.json --project demo-openci
dart format apps/dashboard/lib/generated
vp fmt firebase/generated
```

Generation compiles the local schema without deploying it. Connector singletons
use the selected Firebase app's project. The emulator regenerates SDKs on startup;
run the formatters again afterward.

## Team and GitHub access

New account registration creates the initial team and membership in one
transaction with `CreateTeam`. The Dashboard uses `RenameTeam` for team names
and callable Functions for adding/removing members. Team deletion belongs to the
billing flow because it must reconcile Stripe and credential cleanup.

GitHub OAuth requests store hashes and Secret Manager references. Functions
verify the GitHub user, installation, App ID and host before confirming a
connection. Confirmation checks current team membership, prevents cross-team
installation takeover, and consumes the OAuth session atomically.
`GetActiveGitHubConnection` provides the planner's verified installation lookup.

See [team-member Functions](../functions/TEAMS.md) and
[GitHub connection Functions](../functions/GITHUB_CONNECTION.md).

## Billing and build execution

`GetBillingContext` returns membership-checked Customer intent, open Checkout,
Stripe state and its period. Individual purchase/period reads support retries
and webhook processing, including records retained after team deletion.
Creation intents are insert-only; conditional writes preserve Stripe idempotency
keys and original purchase parameters. Revisions serialize Stripe observations.

Billing periods retain immutable allowances. Every admission/execution write
advances the account usage revision transactionally. `BillingUsageSnapshot` and
`BillingUsageGuard` keep quota checks consistent with concurrent reservations,
heartbeats and terminal writes. Required composite foreign keys prevent using
another team's period. A stale heartbeat must expire rather than extend an
unobserved interval.

Job mutations trigger dispatch Functions. Cloud Tasks retry unavailable capacity;
Orchard and active dispatch reservations determine capacity. The executor reads
`GetBuildExecution`, reserves paid or configured complimentary usage, runs the VM,
and persists logs and final status. Recovery enumerates
`GetRecoverableBuildExecutions`; it reads and closes the associated billing work.
`GetBillingJob` remains necessary to reconcile an individual admission.

`CompleteBuildExecution` releases a dispatch only after the current cleanup owner
has completed VM, billing and GitHub finalization. The old worker polling and
standalone dispatch completion operations are removed.

See [billing](../functions/BILLING.md), [dispatch](../functions/BUILD_DISPATCH.md)
and [executor](../functions/BUILD_EXECUTOR.md) for runtime and recovery contracts.

## Logs and Secrets

The Dashboard subscribes to `GetBuildLogState` for run status, the last log
sequence and all step summaries. It fetches only unseen log pages with
`GetBuildLogs`. Step ordering is stable by order and ID. Log pages are bounded
and run-scoped sequences support incremental reads.

Executor log writes are insert-only. A transaction advances the expected sequence
and writes the log entry. Ambiguous writes are resolved against the saved log ID
and payload. `GetBuildLogWriteState` and `GetBuildStepWriteState` support recovery.
`expireBuildLogs` removes expired log bodies in bounded batches, retaining run and
step summaries.

`GetSecrets` exposes metadata to members. `GetManagedSecretContext` is server-only;
`CommitManagedSecret`, `RenameManagedSecret` and `DeleteManagedSecret` lock the team,
recheck membership and compare the previous version before changing references.
Functions validate secret names and derive numeric version paths from Secret
Manager, create a version before publishing it, and reconcile ambiguous writes.

Unused versions are queued for delayed cleanup. The cleanup Function checks that
no active reference remains before destroying a version. The same cleanup policy
covers team deletion. The old encrypted database and import utilities are retired.

See [Logs and Secrets](../functions/LOGS_AND_SECRETS.md).

## Local validation

Use the isolated demo project; fixture mutations must never run against production.
From the repository root:

```sh
npm run build --workspace firebase
env -u DEBUG npx --yes firebase-tools@15.34.1 emulators:exec \
  --config firebase/dataconnect/firebase.json --only dataconnect --project demo-openci \
  'node --test --test-concurrency=1 firebase/dataconnect/test/*.test.mjs'
```

The suite covers current Admin SDK operations, member isolation, denied direct
client writes, concurrent purchase/execution changes, dispatch cleanup, log
idempotency and managed Secrets. Functions and Dashboard have separate unit tests.

## Deployment and retirement

The production service is `openci-b1b91-service` in `asia-northeast1`, backed by
`openci-b1b91-instance` / `openci-b1b91-database`. Review the database diff before
schema deployment. `COMPATIBLE` leaves obsolete physical columns/tables in place;
retiring them requires an explicit reviewed SQL migration after connector cleanup.

Unused trial and skipped-workflow storage, legacy reference CRUD, migration-only
operations, and unused build artifact/summary metadata are removed. Existing
billing periods, purchases, consumed usage and build history remain supported.
See [the storage cleanup record](migrations/README.md),
[production deployment](../functions/DEPLOYMENT.md) and
[legacy retirement](../functions/LEGACY_RETIREMENT.md) for the cutover record.
