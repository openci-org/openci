# FSC deployment

The deployment target is `openci-b1b91`, `asia-northeast1`. The Node codebase is
`openci`; the Dart codebase is `openci-planner`. Deploying either is separate from
migrating production data and changing GitHub/Stripe endpoints.

## Runtime configuration

| Runtime                                             | Identity parameter                | Default account    | Resources                            |
| --------------------------------------------------- | --------------------------------- | ------------------ | ------------------------------------ |
| Webhook, planning trigger and API/cleanup Functions | `OPENCI_API_SERVICE_ACCOUNT`      | `openci-functions` | 256 MiB, 1 CPU, min 0                |
| Build queue and dispatcher Functions                | `OPENCI_DISPATCH_SERVICE_ACCOUNT` | `openci-dispatch`  | 256 MiB, 1 CPU, min 0                |
| Execution recovery Function                         | `OPENCI_RECOVERY_SERVICE_ACCOUNT` | `openci-recovery`  | 256 MiB, 1 CPU, min 0                |
| Dart `process-webhook-task`                         | `OPENCI_PLANNER_SERVICE_ACCOUNT`  | `openci-planner`   | 128 MiB, 1 CPU, min 0                |
| Cloud Run Job `openci-build-executor`               | Job configuration                 | `openci-executor`  | 512 MiB, 1 CPU, one task, no retries |

Account emails end in `@openci-b1b91.iam.gserviceaccount.com`. Keep parameter
overrides and IAM bindings consistent when using another project. Store local
nonsecret configuration in the ignored `.env.PROJECT` files in `firebase/` and
`firebase/dart_functions/`. Use Secret Manager bindings for credentials.

128 MiB was insufficient for the Node bundle: the production cold start reached
135 MiB and failed before serving a request. Node Functions now use 256 MiB;
Dart retains 128 MiB. The executor Job has a 3900-second task timeout around its
3600-second build deadline.

`githubWebhookFsc` coexists with the older `githubWebhook` deployment. Its URL is
`https://asia-northeast1-openci-b1b91.cloudfunctions.net/githubWebhookFsc`.
`PROCESS_WEBHOOK_TASK_URL` is the private Dart service URL,
`https://process-webhook-task-zmg24bcsaq-an.a.run.app`.

## Runtime IAM

The project custom role `openciConnectorRuntime` contains only
`firebasedataconnect.connectors.impersonateQuery` and
`firebasedataconnect.connectors.impersonateMutation`. Each of the five runtime
accounts has this role. It permits predefined connector operations across the
project, including admin-only operations; it does not permit arbitrary GraphQL
or schema changes. Do not describe these identities as isolated by connector.

FSC connector resource-name conditions did not grant access in production.
Firebase Data Connect is not listed among the services supporting IAM resource
attributes. Use the operation-limited custom role at project scope; use separate
projects if IAM isolation between connector data is required. See
[IAM resource attributes](https://docs.cloud.google.com/iam/docs/conditions-resource-attributes).

Additional access is scoped as follows:

- API identity: Firebase Auth `firebaseauth.users.get`; declared GitHub/Stripe
  secrets; `secretmanager.secrets.create`; get/delete/add/access/get-version/
  destroy-version for managed `openci-*` secrets only.
- Planner: the GitHub App private key only.
- Dispatcher: Orchard service token, Cloud Tasks enqueue on `dispatchBuildJob`,
  act-as on itself, and `roles/run.jobsExecutorWithOverrides` on the executor Job.
- Executor: GitHub App key, Orchard token/CA, and read-only access to managed team
  secrets (`openci-*`, excluding `openci-github-*` OAuth credentials).
- Recovery: GitHub App key and Orchard token; `run.executions.get` and
  `run.executions.cancel` on the executor Job through `openciBuildRecovery`.

Secret Manager conditions must cover both project ID and project number resource
names. The API's project-level create permission does not grant access to
existing unrelated secrets. API/dispatch trigger identities also have
`roles/eventarc.eventReceiver`.

After Functions deployment, apply the target-specific invocation bindings:

```sh
bash infra/orchard/grant-runtime-callers.sh
```

This covers Eventarc to the Node Functions, Node to Dart, and Cloud Tasks to the
dispatcher. Firebase CLI replaces task queue enqueuers and Run invokers when
`onTaskDispatched` declares `invoker: "private"`. The dispatcher deliberately
omits that option so updates preserve these bindings; a newly created task
Function is private until its bindings are granted. Check policies after deploy.
The Dart Function's explicitly private declaration also requires reapplying its
caller binding after deployment. No public caller is granted to the planner or
dispatcher.

For Orchard connectivity, see [the controller deployment](../../infra/orchard/README.md).
Only dispatcher, recovery and the Job use Direct VPC egress. All three retain
TLS verification with the configured public CA.

## Verified deployment on 2026-10-30

All 15 Node Functions, the Dart Function and `openci-build-executor` were deployed.
This staging verification used executor image digest
`sha256:8c8dc243b79132b63460f592507ec710271f0eb5035324abed58c04605733af1`.

- A signed webhook reached `githubWebhookFsc`, Eventarc and the Dart Function,
  then completed its FSC task. A separate push on a branch without matching
  triggers exercised GitHub workflow fetching and Dart AST parsing, completing
  without creating a job. The Dart cold start succeeded at 128 MiB.
- A controlled `CompleteWebhookTask` mutation created a temporary team's job.
  Eventarc and Cloud Tasks dispatched Cloud Run execution
  `openci-build-executor-fgk69`, which created a VM on `genuineci-worker-dokyo`,
  checked out commit `4e30fe567c1b4e047040028f957fa32c626568f9` and ran
  `dart_functions_ci.dart`. Static analysis and all 131 tests passed.
- FSC stored 544 log entries and three successful steps. The
  [GitHub Check](https://github.com/openci-org/openci/runs/124127048446) completed
  successfully. The usage ledger closed with 88,133 ms measured, and Orchard
  deleted the VM. A dummy multiline team secret was read through Secret Manager
  and was absent from the saved logs.
- Anonymous planner/dispatcher calls returned 403; unauthenticated callable
  requests returned 401. Local TypeScript lint/build and 88 Node tests passed.

The temporary team, connection, secret, jobs, logs and billing records were
removed after verification; the Job's original complimentary-team setting was
restored. `dokyo` remains on the new controller. Its old controller record is
paused, and its previous launchd configuration and bootstrap file are backed up
on that Mac under `/Library/Application Support/GenuineCI/gcp-deploy-backup-20261030`.
The remaining workers were moved during the production cutover below.

This staging verification did not exercise a real subscription change, browser
OAuth flow, capacity exhaustion or an intentionally crashed executor.

## Production cutover on 2026-10-31 JST

Legacy API, Go billing server, planner and build worker were drained and stopped;
their Docker restart policies are now `no`. PostgreSQL, Loki and the old Orchard
controller remain available for rollback investigation. The source backup is
`/home/ubuntu/openci/backups/fsc-cutover-20261031` on `openci-worker-01`.
It contains the container configuration, environment files and a PostgreSQL
custom-format dump, verified with `pg_restore --list`. The dump SHA-256 is
`4cd93edf8ca21ed41f1c4aa8d973b31886b1271e25cc9525f84785e0264492ce`.
The directory is private to the operator account.

The insert-only migration verified all source records after copying:

- 3 teams, 5 memberships and 2 verified GitHub connections.
- 23 Secrets, verified against the decrypted source after writing Secret Manager.
- 1,175 billing records, preserving Stripe identities and consumed usage.
- 6,897 terminal build jobs, 6,637 completed runs and 3,257 webhook tasks.

Existing destination records were preserved. Historical Loki log bodies were
excluded; imported runs have expired logs and retain their history. One webhook
task was already stuck in `processing` before cutover; its source record was
preserved without replaying an old build.

GitHub App `4553272` now sends webhooks to `githubWebhookFsc`. Its exact OAuth
callback includes
`https://asia-northeast1-openci-b1b91.cloudfunctions.net/githubConnectionCallback`,
with wildcard matching disabled. Seven deliveries that received 502 while the
legacy server was stopped were requested again at the new destination; all seven
returned 200. Chrome completed an OAuth reconnection for the existing `openci-org`
connection through the new callback.

`teamBilling` and `stripeWebhook` now use `BILLING_ENABLED=true`. The new Stripe
endpoint `we_1UWHWBIclI20UB7MsRC8gkjm` is enabled and binds
`STRIPE_WEBHOOK_SECRET:2`; the old endpoint `we_1UTHUXIclI20UB7MTdDVlbtj` is
disabled. No relevant Stripe events occurred during the cutover interval.
Replaying an already-processed, genuine Stripe event with the new signing secret
returned 204. Existing purchases were preserved; no purchase or subscription
change was made for testing.

Dashboard Hosting version `5ca49fa1318a0528` was promoted from the preview channel
to `dashboard-openci:live`. The previous version is `aace2372bef5818a`.
Chrome confirmed build history, Secrets metadata, the complimentary Pro team and
the existing paid Light subscription through the new APIs. Dashboard static
analysis, 289 VM tests and 53 browser tests passed before promotion.

All six online Mac workers now use the GCP controller. `dokyo` retains its
2026-10-30 backup; the other five have root-only backups under
`/Library/Application Support/GenuineCI/gcp-deploy-backup-20261031`.
Their existing worker names, resource limits and labels were preserved. All old
controller worker registrations are paused. Cloud Tasks and the three credential
cleanup Scheduler jobs were resumed after migration.

Live GitHub pushes have completed builds on the new execution path, including
[this build](https://github.com/letter-fan/sakuticket_app_fan/runs/124154488328).
FSC recorded logs and completed usage, GitHub Checks succeeded, and Orchard
deleted the finished VMs. Dispatcher retries occurred during cutover; the
dispatcher was redeployed with fixed, sanitized failure diagnostics and normal
parallel execution resumed. Error messages and SDK request payloads are never
logged by those diagnostics.

The six workers provide ten VM slots. Live traffic exercised ten simultaneous
builds and queued additional jobs until capacity was released. One attempt failed
between run configuration and billing start, before requesting a VM or writing
an execution charge. The raw exception was not logged, so the precise cause
could not be recovered. The shared team usage revision can exhaust immediate
CAS retries during a burst; billing admission, start, heartbeat and closure now
retry up to twelve times with 50–250 ms jitter and fresh reads, preserving all
identity, quota and lease checks. Tests cover contention, lost acknowledgements,
bounded retries and expired execution rejection.

The updated executor image is
`sha256:9e3d0c0812d7d2c147d47eacc5faacb6748ad7664e7e58dd7786abe9b910e160`;
the recovery Function uses the same billing retry changes. Node lint, TypeScript
analysis and all 91 tests passed. No existing running execution was cancelled
during this update.

The failed job was requeued only after confirming its previous dispatch was
finished, no VM had been requested and no billing execution existed. Its second
attempt [succeeded](https://github.com/letter-fan/sakuticket_app_fan/runs/124165969635),
writing 1,827 logs and closing 213,286 ms of measured execution before releasing
the VM slot. All 18 jobs created after cutover had succeeded at the final check.
The original failed attempt remains in history and has no execution charge.

Before rolling traffic back, stop new admissions and billing writers, drain
executions and reconcile the new FSC writes with the legacy database. The
pre-cutover dump alone does not include builds or billing changes made afterward.

## CI environment corrections on 2026-10-31 JST

PR #3756's Go workflows failed with `go: command not found` and
`gofmt: command not found`. The new executor omitted `/usr/local/bin`, which
the legacy worker included and the VM image uses for its Go executable links.
The workflow environment now restores that directory while preserving Flutter,
pub-cache, Homebrew and inherited system paths. A shell-level regression test
reproduced the failure; Functions formatting, lint, TypeScript and all 92 tests
passed after the fix. The executor was deployed as
`sha256:97683d55528f7671426e8d6a947dbd9e3c02cd0c93ff73dc4fb1661749c8bb13`.

During remote verification, dispatcher requests also repeatedly timed out
connecting to Orchard while the Controller itself remained healthy. Its ingress
firewall rule used a Cloud Run source tag, which Direct VPC does not support.
The rule now permits only TCP 443 from `10.77.0.0/24` to the Controller target
tag, as described in the [Orchard runbook](../../infra/orchard/README.md).
The public HTTPS rule stays disabled; TLS and Orchard token authentication
remain required. The dispatcher was also redeployed during diagnosis.

## Stripe Sandbox verification on 2026-10-31 JST

The real Stripe Sandbox `acct_1StPaWIoRC3DAU5M` was used with test cards and the
unchanged `teamBilling`/`stripeWebhook` handlers. Firebase Auth, Functions and FSC
ran locally under `demo-openci`. A temporary Flutter entry point used the actual
Dashboard billing page, providers and API, with test authentication/connection
overrides. This did not change live subscriptions or production configuration.

Verified through Chrome, the Stripe API and the FSC ledger:

- Light Checkout completed at USD 10/month, granting one immutable 36,000-second
  paid period; Pro purchase after ending Light granted 360,000 seconds. Dashboard
  displayed the matching plan and CI eligibility.
- A declined test card showed a payment error and granted no CI access.
- Repeated Checkout requests reused the same session/customer. Switching plans
  before payment expired the prior session and left only one open session.
- Active subscriptions rejected a second purchase and team deletion.
- Customer Portal changed the default payment method, scheduled cancellation at
  period end and undid that cancellation. Raw FSC reads before a status refresh
  confirmed the cancellation webhooks updated state while preserving the paid
  period and CI eligibility.
- Ending the test subscription through the Sandbox API blocked new CI starts.
  Reopening Checkout then allowed a Pro purchase with the same customer, one
  active subscription and both historical paid periods intact. This simulated
  terminal state; it did not wait for a real monthly renewal.
- Replaying a genuine paid-invoice webhook twice retained one event and one paid
  period. Replaying the old Light cancellation after Pro purchase did not revoke
  the new entitlement. Observed Stripe deliveries returned 204.
- After the final test subscription ended, team deletion succeeded on retry and
  remained idempotent; the billing identities and both paid periods survived.

The first simultaneous Checkout attempt returned one 503; retry reused the
existing session without duplication. An immediate team deletion during webhook
processing initially returned 400 and succeeded on retry. The precise original
failure reasons were not captured; no duplicate subscription or lost ledger
record was observed. The UI already prevents repeated actions while pending.

The CLI initially forwarded `2026-09-30.endive` snapshots; after reconnecting it
used `2026-10-28.endive` for the Portal changes and Pro purchase. Both were
accepted by the installed SDK. The FSC billing emulator suite passed all 22 tests,
including mocked paid/failed renewal, access control and ledger concurrency.
Functions formatting, lint, TypeScript analysis and all 91 unit tests also passed.
The billing verification required no production implementation changes.

Active Light-to-Pro/Pro-to-Light switching remains disabled by design in both the
backend and Portal configuration. These checks cover payment-method changes,
cancellation/reinstatement and a new purchase after termination; they do not
establish support for upgrades, downgrades or proration. Real monthly renewals,
3-D Secure challenges and real-money payments were not exercised.

Both test subscriptions were canceled and the two test products/prices archived.
The Sandbox customer, invoices and default Portal configuration remain as test
history; Stripe does not allow deactivating the default Portal configuration.
Local test credentials and services were removed after verification.

The production cutover is complete for the migrated build and Dashboard paths.
Remaining follow-up work is to commit/review the deployment changes, retire the
retained legacy code/infrastructure after the rollback window, and configure
Controller data-disk backups and Tailscale key renewal as described in
[the Controller runbook](../../infra/orchard/README.md).

## Cutover

Keep `BILLING_ENABLED=false` while staging. Keep `cleanSecretVersions`,
`cleanGitHubConnectionCredentials` and `cleanDeletedTeamCredentials` Scheduler
jobs paused until data migration is complete. Deployment can create schedules;
check their state afterward.

1. Verify signed webhook receipt, Eventarc delivery, planning, Cloud Tasks, VM
   execution, logs, Checks, usage closure and VM cleanup with controlled data.
2. Stop legacy billing/team/secret writers and build admission, drain running
   work, and preserve durable pending webhook deliveries. Import teams and
   memberships, verified GitHub connection metadata, Secrets and billing.
   Preserve all consumed usage; do not merge independently active ledgers.
3. Re-run migration verification. Configure the new GitHub OAuth callback and
   Stripe endpoint with its matching webhook secret. Deploy compatible clients,
   enable billing and switch the GitHub App webhook. Reconcile missed Stripe
   events and GitHub deliveries before resuming normal work.
4. Resume credential cleanup, move the remaining drained workers, and retire
   legacy writers. Retain the source database and rollback configuration.

The migration preserves Firebase user IDs and verified installation ownership.
Historical Loki logs are excluded by design.

See [billing migration](BILLING.md), [Secrets migration](LOGS_AND_SECRETS.md) and
[GitHub connection setup](GITHUB_CONNECTION.md) for the individual procedures.
