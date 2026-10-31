# Cloud Run build executor (G-1605)

The entry point is `executor/main.ts`. One Cloud Run Job task handles one FSC
reservation, from VM creation through cleanup. Build commands still run on the
Orchard macOS VM; Cloud Run holds the WebSocket and persists output to FSC.
It does not run Flutter or parse Dart workflows locally.

```text
dispatchBuildJob -> Cloud Run Job
  claim reservation -> verify PR source -> billing admission -> create numbered run
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

The run and admission IDs derive from the dispatch ID. Billing admission follows
the existing paid Stripe policy, or the explicit complimentary-Pro allowlist.
The complimentary period uses UTC calendar months and 360,000 seconds. A team
without entitlement/budget stays `QUEUED`, without a VM; the dispatcher's existing
delayed task can retry. Admissions, run binding, usage revisions and log IDs are
re-read after ambiguous responses. The run count increments once.

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
repository-scoped `pull_requests: read` token is revoked after verification and
never sent to the VM; the GitHub App must have that read permission.
Only the team's pinned Secret Manager versions are injected into the workflow.
Google credentials, Orchard credentials and the GitHub App key never enter the VM.

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
GitHub Check creation is reconciled by app ID and the stable run `external_id`.
The sweep also compares actual Orchard VM names with closed attempts, deleting
VMs whose creation was committed after the original request disconnected and
cleanup had already observed 404. Active attempts and unrelated VMs are excluded.

Controller, billing or GitHub outages leave the reservation in `finishing` for
another sweep. Inspect sanitized `execution_cleanup_pending` logs and old open
dispatches when diagnosing cleanup delays. Manual rerun and dependency/matrix
scheduling remain outside this change.

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
public invoker is needed. The Dockerfile-specific ignore file includes the npm
manifests/generated SDKs that the repository-wide `.dockerignore` excludes.

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
| `GITHUB_APP_ID`, `GITHUB_APP_PRIVATE_KEY`         | App ID and secret binding                                                                  |
| `GITHUB_API_BASE_URL`, `GITHUB_BASE_URL`          | Defaults `https://api.github.com`, `https://github.com`; no trailing slash                 |
| `BILLING_STRIPE_LIVEMODE`                         | Required `true` or `false`, matching the billing backend                                   |
| `BILLING_COMPLIMENTARY_PRO_TEAM_IDS`              | Optional comma-separated approved team IDs                                                 |
| `SECRET_MANAGER_PROJECT`                          | Project ID or number exactly matching stored secret version paths; defaults to FSC project |

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
