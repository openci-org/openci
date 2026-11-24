# Cloud Run build executor (G-1605)

The entry point is `executor/main.ts`. One Cloud Run Job task handles one FSC
reservation, from VM creation through cleanup. Build commands still run on the
selected Orchard VM. Cloud Run holds the WebSocket and persists output to FSC.
It does not run Flutter or parse Dart workflows locally.

```text
dispatchBuildJob -> Cloud Run Job
  claim reservation with queued check ID -> resolve checkout commit -> billing admission -> create numbered run
  update the queued GitHub Check to in_progress
  prepare_vm -> checkout exact commit -> run_workflow
  persist result -> delete VM -> close billing -> complete GitHub Check
  -> complete job/run and release reservation

recoverBuildExecutions (every minute)
  find stale/finishing executions -> acquire cleanup lease
  confirm Cloud Run has terminated -> same cleanup path
```

## Execution and retries

The dispatcher supplies only `BUILD_JOB_ID` and `BUILD_DISPATCH_ID`. The executor
reads VM size/image/name and repository metadata from FSC. A fresh process UUID
must win `ClaimBuildJobExecution`; duplicate containers exit without allocating
a VM. A lost claim acknowledgement also exits and leaves recovery to the sweep.
Older unclaimed reservations without `teamId` expire at their startup deadline.

The run and admission IDs derive from the dispatch ID. In Cloud, the executor
calls the private `ciCardEligibility` Function before VM creation. A confirmed
billing card admits the team to its Japan calendar month postpaid period. A
missing card leaves the GitHub check queued with a link to the team's billing
page. The dispatcher resumes the same job once the card is confirmed. The
complimentary allowlist retains its 360,000-second UTC monthly allowance.
Admissions, run binding, usage revisions and log IDs are re-read after ambiguous
responses. The run count increments once.

Every 15 seconds the executor checks cancellation/ownership and renews the
billing observation. Any failure interrupts the command. A workflow deadline,
nonzero exit, missing exit frame or disconnect terminates this attempt; commands
with uncertain outcomes are never replayed. SIGTERM/SIGINT also interrupt it.
The three pipeline stages and stdout/stderr are saved using the existing logs
connector, with 14-day retention and sequential, bounded log writes. Known
tokens/secrets are masked across WebSocket frame boundaries. This is accidental
disclosure protection, not isolation from a workflow intentionally exfiltrating
its own secrets.

The executor uses Orchard's `interactive=true` exec protocol: the URL contains
only `/bin/bash -s`; the script and EOF travel in stdin frames. No runner script
is installed in the VM. Require an Orchard release implementing this protocol;
see the [Orchard API](https://github.com/cirruslabs/orchard/blob/22bd63c34674a1422896aa208a464f4340cdb0b8/api/openapi.yaml).
HTTPS/WSS certificate verification remains enabled, including custom CA support.

GitHub App authentication uses Octokit. Checkout receives a repository-scoped
contents-read token, revoked after checkout. A separate checks-write token stays
in Cloud Run. Repository ownership must match the active FSC GitHub connection.
Before billing admission or VM creation, PR jobs are rechecked against GitHub:
head and base repository IDs must both match the connected repository, and the
head SHA must match the saved job. This protects queued jobs and reruns created
before the planner's fork restriction. Unknown/deleted heads, API failures, and
superseded PR commits fail the attempt without fetching team secrets or handing
a checkout token to the VM. Rerun the latest PR commit after a new push. A separate
repository-scoped token with `pull_requests: read` and `contents: read` stays in
Cloud Run and is revoked after resolving the checkout commit, including cancellation.
The GitHub App must have both read permissions.
The executor pins REST API version `2022-11-28`: version `2026-03-10`
[removes `merge_commit_sha` from PR responses](https://docs.github.com/en/rest/about-the-rest-api/breaking-changes#version-2026-03-10).

For an open PR, the executor checks GitHub's test merge commit against the current
`refs/heads/<base branch>` fetched from the verified repository, rather than
`pr.base.sha`, which can retain an older PR snapshot. Its parents must match that base SHA
and the job's saved head SHA. A current candidate is used immediately. The
execution pins the resolved merge SHA for checkout
and writes the full checked-out SHA to its checkout log. GitHub Checks use the
job's saved head SHA. Push builds check out their saved commit SHA.

If the candidate is stale or unavailable (including HTTP 404), or GitHub has not
finished calculating mergeability, the executor immediately rereads the PR,
current base ref and any available candidate without polling or sleeping. All
source, state and saved-head checks apply again. A now-current GitHub merge is
used normally. Otherwise, the actual head branch ref must still equal the saved
head before a local merge is selected using the freshly verified base and head.
The obsolete candidate's ancestry is not required: the local merge validates
the pinned source commits directly. Known conflicts, closed PRs, changed heads,
invalid source refs, other API failures and cancellation stop checkout. The
entire verification has a 30-second limit, including API time, and interrupts
in-flight reads; the overall execution deadline also applies. This limit bounds
network calls, rather than waiting for GitHub to generate a merge commit.

The fallback fetches the full ancestry of the pinned base and head into the
disposable VM and uses `git merge-tree --write-tree` and `git commit-tree` to
create a two-parent test merge. VM images need Git 2.38 or later. Conflicts stop
checkout before workflow execution or team-secret reads. The generated commit
exists only in that VM: nothing is pushed and no PR or branch is modified. GitHub
Checks still attach to the saved head. Full-history fetch and merge happen during
the ordinary billed checkout step, including an attempt that finds conflicts;
the source verification happens before billing admission.

Operator logs record `pull_request_checkout_stale_merge` or
`pull_request_checkout_not_ready`, with attempt count, elapsed time, the latest
validated head/base/candidate SHAs and the last PR response's GitHub request ID
when available. `pull_request_checkout_local_merge_selected` records the same
diagnostics when the fallback is chosen; `pull_request_checkout_local_merge_completed`
also records the generated checkout SHA. The checkout log identifies the fallback,
pinned base/head and final SHA. Keep these for GitHub Support investigations. Only the fixed
failure message is published to Checks and the dashboard; response bodies,
credentials and unvalidated identifiers are excluded.

The workflow receives `OPENCI_CONTEXT`, schema version 1 JSON containing the
resolved checkout/event metadata plus repository, job, and run identity. PR base
and head metadata come from the same validation that selected the merge commit.
For a local merge, `checkoutSha` is the generated commit actually checked out;
internal fallback diagnostics are excluded from the workflow context.
The Dart SDK reads this lazily as `OpenCI.context`; deploy the executor before
adopting that API. Context is a snapshot, not a check that a deployment is still
current. The protocol contains no credentials or raw webhook payload.

`npm run test:workflow-context --workspace firebase` executes the generated shell
exports and decodes them in the Dart SDK. Run `flutter pub get` at the repository
root first; the test requires Dart on PATH. The Functions CI runs this check after
the Node test suites.

Merge conflicts, closed or updated PRs, and unavailable test merge commits produce
fixed messages explaining how to retry. The executor persists the message on the
dispatch before cleanup so recovery can publish it to GitHub Checks and the job's
`failureSummary`. The dashboard shows and copies this summary even when checkout
failed before a run or log step existed. Raw API exceptions are never published.
Cancellation and later attempts clear the job summary, and an obsolete dispatch
cannot overwrite a newer attempt's summary. Deploy the additive schema and
updated `dispatch` connector before deploying the executor that writes the message.

By default, only the team's pinned Secret Manager versions are injected into the
workflow. The executor's Google credentials, Orchard credentials and GitHub App
key never enter the VM.

The opt-in [production Functions CD](FUNCTIONS_CD.md) additionally
receives a dedicated deployment SA and runtime configuration from pinned
infrastructure secrets. The executor verifies the saved release tag, its commit's
`develop` ancestry, and the team, repository and workflow identity before secret
access. It filters these credentials out of ordinary team-secret injection for
every other run.

`openCI.pullRequest.postQrCode` requests a QR code for a workflow-supplied URL.
After the workflow succeeds, Cloud Run validates the URLs, language, size, and
optional app version/build values and checks the current PR head. SDK 0.2.7 retains
Firebase App Distribution's `displayVersion` and `buildVersion` for each exact tester
URL and writes optional `metadata.json` alongside each completed QR request.
The bounded runner output frames URL records and metadata separately. Legacy URL
files remain supported, and older executors simply ignore the metadata file.
Comments display the registered workflow name and any known app version/build
number; the CI sequence stays in the ownership marker for update ordering only.
Missing app fields are omitted rather than replaced with the CI run number.
It renders the URLs locally, stores the images
on `openci/pr-qr` in the source repository, and updates its existing comment
for that PR and workflow file. A SQL Connect lease serializes comment creation
and edits. A newer run in the same team takes precedence over an earlier run.
The repository-scoped Contents and Pull requests write token stays in Cloud Run
and is revoked after publication. Deploy the additive `pull_request_qr_comment_leases`
table and `dispatch` connector before the executor.
Keep existing `genuineci/pr-qr` branches so that images in older PR comments remain available.

`reportPullRequestBuildResult` listens for committed `CompleteBuildExecution` events.
On an open PR, a failed or timed-out workflow gets a conversation comment with
its diagnostics and build log. A successful rerun folds the previous errors into
the same comment. Each workflow and matrix label has its own comment.
The reporter reads the failed step's masked log tail and links up to ten source
locations at the PR head. Ambiguous or generated paths are displayed as text.
GitHub delivery retries independently of the build result and queue.

Deploy the updated `dispatch` connector before the reporting Function. Its
installation token requests Pull requests write and Contents read on the source
repository. Set `OPENCI_DASHBOARD_ORIGIN` for a custom dashboard. Self-hosted
installations without a configured dashboard link to the GitHub Check.

Both hosted and self-hosted runs get `OPENCI_RUN_NUMBER` from the team's next
run number. The executor saves the assigned number on the run in the same
transaction that advances the team counter. Repeated requests for that run
return its stored number. GitHub Checks continue to use the per-job attempt count.

Deploy the additive `teams.run_number_reconciled` column before the `dispatch`
connector. On the first allocation for each team, the connector uses the greater
of its saved next number and one above its highest previously assigned run number.

The planner reads the `flutterVersion` argument to `OpenCI.init` and persists
the release string on each job. Pass a preset such as
`FlutterVersion.v3_47_8.value` or a literal release such as `'3.47.8'`.
Before dependency resolution, the executor validates the release,
runs `fvm install VERSION --skip-pub-get` and `fvm global VERSION` from the VM's
home directory, then starts `flutter pub get` and the workflow in the checkout.
This reuses the image cache without consulting checkout `.fvmrc` files. SDK
installation/selection failures stop execution. Existing jobs and workflows with
no version continue to use the image default. Selection changes only the job VM.

Deploy the nullable `build_jobs.flutter_version` column and the `webhooks` and
`dispatch` connectors before the executor and Dart planner.

Deploy the updated Dart planner before adopting `FlutterVersion` presets in
workflow files. Functions CD can deploy the planner while the workflow files
still use literal releases.

## Recovery

`recoverBuildExecutions` is a Gen2 scheduled Function (1 CPU, 256 MiB, one instance,
300-second timeout). It handles finishing runs, 90-second stale heartbeats and
expired build deadlines. Cleanup leases serialize the executor and the sweep;
failed items rotate through a bounded queue and retry after lease expiry.

Recovery checks the saved Cloud Run execution, requests cancellation if needed,
and waits for confirmed termination before deleting the VM. It never releases
capacity on a heartbeat timeout alone. Orchard DELETE must be followed by GET
404; billing must be closed before `CompleteBuildExecution` clears `activeJobId`.
Lost billing observations expire at the last observed time and set
`measurementIncomplete`, instead of charging through the outage. An unstarted
admission must expire before it can be closed. Interrupted steps become terminal.
Queued GitHub Checks are created by the mutation consumer and their IDs copied
into reservations. Execution and recovery update that same check, including
failures before BuildRun creation. An unnumbered billing-blocked attempt leaves
it queued. Legacy reservations without a check retain the fallback creation
path, reconciled by App ID and the stable run `external_id`.
The sweep also compares actual Orchard VM names with closed attempts, deleting
VMs whose creation was committed after the original request disconnected and
cleanup had already observed 404. Active attempts and unrelated VMs are excluded.

Controller, billing or GitHub outages leave the reservation in `finishing` for
another sweep. Inspect sanitized `execution_cleanup_pending` logs and old open
dispatches when diagnosing cleanup delays. Explicit retries use the
[`RetryBuildJob` API](JOB_RETRY.md); dependency/matrix scheduling remains separate.

## Configuration and deployment

Build from the repository root:

```sh
docker build --platform linux/amd64 -f firebase/Dockerfile.executor -t BUILD_EXECUTOR_IMAGE .
```

Use one task, one container, `--max-retries=0`, 1 CPU and 512 MiB (Cloud Run Jobs'
[minimum memory](https://docs.cloud.google.com/run/docs/configuring/jobs/memory-limits)).
Attach the Job to the controller VPC with `--network=orchard
--subnet=orchard-tokyo --network-tags=orchard-client
--vpc-egress=private-ranges-only`. Use `ORCHARD_API_URL=https://10.77.0.2:443`
and trust `ORCHARD_CA_CERT`. The recovery Function uses the same network settings
through `orchard_network.ts`. This keeps GitHub/Google API access on the normal
serverless route without adding a VPC connector or Cloud NAT.

Set the Job task timeout to **3900s** for the default 3600s build deadline,
leaving time for cleanup; recovery still handles a hard kill. No HTTP port or
public invoker is needed. The executor build uses
`firebase/Dockerfile.executor.dockerignore` to include the npm workspace
manifests, generated SDKs, and Functions source in the build context.

Set these values on the Job **and** recovery Function, keeping the identities
consistent with the dispatcher/planner:

| Environment                                       | Value                                                                                      |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `GOOGLE_CLOUD_PROJECT` / `GCLOUD_PROJECT`         | FSC project                                                                                |
| `BUILD_EXECUTOR_JOB`                              | `projects/PROJECT/locations/REGION/jobs/JOB`                                               |
| `BUILD_EXECUTOR_TIMEOUT_SECONDS`                  | Default 3600; 60–86400                                                                     |
| `ORCHARD_API_URL`, `ORCHARD_SERVICE_ACCOUNT_NAME` | Controller and service account                                                             |
| `ORCHARD_SERVICE_ACCOUNT_TOKEN`                   | Secret binding                                                                             |
| `ORCHARD_CA_CERT`                                 | Optional PEM CA                                                                            |
| `ORCHARD_USE_WORKER_MEMORY`                       | Optional `true` to use each worker's default VM memory; defaults to `false`                |
| `GITHUB_APP_ID`, `GITHUB_APP_PRIVATE_KEY`         | App ID and secret binding                                                                  |
| `GITHUB_API_BASE_URL`, `GITHUB_BASE_URL`          | Defaults `https://api.github.com`, `https://github.com`; no trailing slash                 |
| `BILLING_STRIPE_LIVEMODE`                         | Required `true` or `false`, matching the billing backend                                   |
| `BILLING_DASHBOARD_ORIGIN`                        | Optional Cloud billing link origin, defaults to `https://dashboard.openci.org`             |
| `BILLING_COMPLIMENTARY_PRO_TEAM_IDS`              | Optional comma-separated approved team IDs                                                 |
| `SECRET_MANAGER_PROJECT`                          | Project ID or number exactly matching stored secret version paths; defaults to FSC project |

The Linux pilot uses `base-linux` on Vetu/amd64 with the reservation's explicit
2 vCPUs and 8192 MiB. Checkout and workflow execution share
`/home/admin/openci-build`. The image supplies FVM, Java 17 and the Android SDK.
Hosted Linux pilot runs require a team in `BILLING_COMPLIMENTARY_PRO_TEAM_IDS`.
The executor supplies the workflow context and skips team secret retrieval for the pilot.

For macOS, `ORCHARD_USE_WORKER_MEMORY=true` lets Orchard choose the VM's
memory from the selected worker's `--default-memory`. For example, two slots on
an 8 GiB Mac can use 4096 MiB each, and two slots on a 24 GiB Mac can use 12288
MiB each. The dispatch memory remains the minimum admission reservation; existing
VM capacity accounting includes Orchard's actual `assignedMemory`.

Before enabling this mode, drain existing VMs and configure every eligible worker
so its default memory is at least the dispatch reservation and its slot count
times default memory does not exceed its physical memory. The executor checks
these conditions and rejects larger existing/manual VMs that would invalidate
the partition. Keep this fleet dedicated to these partitions. Assigning all
physical memory to guests leaves host memory pressure and swapping to be checked
under representative concurrent workloads. With the flag unset, explicit dispatch
memory continues to be used.

The Job runtime identity needs privileged FSC access to `dispatch`, `billing`
and `logs`, plus access to its bound credentials and team secrets. The recovery
identity needs privileged FSC access and its bound credentials, and
`run.executions.get` / `run.executions.cancel` on the configured Job to inspect/cancel it.
See [execution lookup](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs.executions/get)
and [cancellation](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs.executions/cancel).
Cloud Scheduler must invoke the private scheduled Function. Both runtimes need
controller network access; the Job also needs outbound GitHub/Google access.

Deploy the schema/connector, Job and recovery Function before enabling dispatch
and changing the GitHub webhook URL. Before switching traffic, a staging build
must prove real Orchard stdin/EOF, VM deletion, Cloud Run IAM/cancellation,
FSC event delivery, private checkout, secret access and billing/check completion.
Do not rename the configured Job while its dispatches remain active.
The legacy planner/worker source and Compose services have been removed. Drain
and stop any previously deployed polling containers before upgrading Compose
(which removes orphans) or enabling this dispatcher on the same job queue.
Cleanup fences older attempts and never overwrites a newer run. Removing source
does not stop existing containers, deploy infrastructure or switch production traffic.

Run the commands in [README.md](README.md#local-checks). The executor suite uses
real SQL Connect with fake Orchard/GitHub/Cloud Run boundaries; separate Node
tests exercise the actual Orchard HTTP/WebSocket client over loopback.
