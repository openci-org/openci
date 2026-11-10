# Changed-path workflow selection

`CITrigger.push` and `CITrigger.pullRequest` accept `paths`, a nonempty
literal list of repository-root-relative, case-sensitive glob patterns. Omit it
(or use `null`) to run whenever event and branch match. Patterns within one
trigger are ORed; event, branch and paths are ANDed. Applicable triggers are ORed
and produce at most one job per workflow. An unfiltered matching trigger runs
without fetching changed files. Negative patterns, absolute paths, parent-path
segments, computed lists and empty lists are configuration errors.

```dart
CITrigger.pullRequest(
  branch: '*',
  paths: ['apps/example/**', 'openci/example_ci.dart', 'pubspec.lock'],
)
```

The planner parses workflow source without executing it. PR filtering uses the
whole PR file list, paginated at 100 files, with head/base SHAs and counts checked
before and after retrieval. Each stacked PR is compared against its own base.
Base retargets (`pull_request.edited` with `changes.base`) trigger replanning;
title/body edits do not. Pushes compare the immutable webhook before/after SHAs.
Removed paths and both old/new rename paths count as changes.

Only complete data for the planned head can skip a workflow. PRs at the 3,000-file
cap and comparisons at the 300-file cap are conservatively incomplete. Missing
base revisions, new branches, force/divergent pushes, revision races, malformed
file lists, timeouts, transport errors, rate limits and 5xx comparison/file API
responses run the applicable workflows and persist `WebhookTask.pathFilterReason`.
Token, authorization and configuration failures retain their existing error/retry
behavior. External-fork and unknown-source PRs remain rejected. Deleted branches
retain the existing zero-job behavior.

## Storage and GitHub reporting

`CompleteWebhookTask` atomically publishes runnable BuildJobs, inserts a
`SkippedWorkflowCheck` per excluded workflow and completes the task. The skipped
row ID derives from task ID and workflow filename. Transaction rollback and the
conditional pending-to-completed transition protect concurrent/lost-response
retries. Skipped workflows have no BuildJob, BuildRun, dispatch, VM or billing
execution. Their records cascade with the webhook task or GitHub connection.

`reportSkippedWorkflowChecks` consumes only successful completion events. It
claims a five-minute SQL lease, verifies the active connection and App/host,
and reports the existing workflow Check name on the planned SHA with
`status: completed` and `conclusion: skipped`. It requests a repository-scoped
Checks-write token. Before creating a Check it searches all relevant pages for
its App and stable `external_id`, so an ambiguous create response is reconciled
on retry. Existing executor Checks are not modified by skipped reporting.

Failures schedule the row for retry after one minute. The minute-scheduled
`recoverSkippedWorkflowChecks` also recovers expired leases and missed Eventarc
delivery. Terminal writes are fenced by lease owner and expiry. Logs and stored
errors exclude SDK/HTTP exceptions, tokens and private source. GitHub has no
create-Check idempotency key: SQL leasing and API reconciliation bound duplicate
risk; an ambiguous response is never treated as successful delivery.

## This repository's dependency matrix

| Workflow              | Main paths                                                              | Additional inputs                                                                     |
| --------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Website CI            | `apps/website/**`                                                       | root `package.json`, `package-lock.json`, `vite.config.mts`, `.node-version`          |
| Firebase Functions CI | `firebase/functions/**`, `firebase/generated/**`, `firebase/scripts/**` | Firebase healthcheck, package and TypeScript config, root npm inputs and Node version |
| OpenCI Workflow CI    | `packages/openci_workflow/**`                                           | root `analysis_options.yaml`                                                          |
| OpenCI Shared CI      | `packages/openci_shared/**`                                             | root `analysis_options.yaml`                                                          |
| Dart Functions CI     | `firebase/dart_functions/**`, `packages/openci_shared/**`               | root `analysis_options.yaml`                                                          |
| Dart Format Check     | `**/*.dart`                                                             | analysis options, package manifests, lockfile, Git ignore files and FVM configuration |

The five package workflows also include their own `openci/*.dart` definition,
the workflow runtime SDK, version hook and generated workflow imports. All six
workflows include `**/pubspec.yaml`, the root `pubspec.lock` and `.fvmrc`.
The static parser reads these patterns from inline literal lists.

Changing only `apps/website/src/components/Pricing.astro` creates one Website CI
job and five skipped records. Root README changes create zero jobs and six skipped
records. A Dart change in the shared models runs Shared CI, Dart Functions CI and
Dart Format Check. Changing the root lockfile runs all six workflows.

## Validation and rollout

Run Dart format/analyze/tests in `firebase/dart_functions`, analyze the `openci`
workflow package, and run the Firebase Node format/check/test scripts. Generate
connector SDKs, format generated sources, and run the SQL Connect emulator tests
for planning, webhooks and dispatch. Planning integration tests use the actual
Dart HTTP Function, local GitHub fixture and SQL database, including the real
workflow files, transactional rollback, leases, authorization and reporting retry.

Deploy in this order:

1. Review/apply the additive SQL schema and deploy the `webhooks` connector.
   Existing planners remain compatible through default empty skipped inputs.
2. Deploy `reportSkippedWorkflowChecks` and `recoverSkippedWorkflowChecks` from
   the Node codebase. They use `OPENCI_API_SERVICE_ACCOUNT`, `GITHUB_APP_ID`,
   `GITHUB_API_BASE_URL`, `GITHUB_BASE_URL` and `GITHUB_APP_PRIVATE_KEY`. Reconcile
   the new Eventarc target's invocation grant in `infra/orchard/runtime_iam.tf`.
3. Deploy the Dart planner. Its GitHub installation needs `contents:read` and
   `pull_requests:read`; reporting needs `checks:write`. Confirm existing App
   installations have accepted these permissions.
4. Verify a PR and push that change only the website component above. Expect one
   runnable Check and five completed/skipped Checks. Verify skipped builds allocate
   no resources and that required checks permit the merge.

Rollback by removing `paths` conditions (or restoring the old planner).
Keep the connector and reporters until pending skipped notifications are drained;
do not drop the outbox during rollback. Local emulator results do not establish
production Eventarc/IAM delivery or actual usage savings.
