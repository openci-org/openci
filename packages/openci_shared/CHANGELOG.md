# Changelog

## 2.0.0

- **Breaking:** Remove `githubBaseUrl` from `Team` and `BuildJobPlan`. Repository
  URLs are configured by the server. `BuildJobPlan.fromJson` ignores the legacy
  field when reading older planner payloads.
- Add authenticated GitHub connection start, session, candidate, and confirmation
  API clients with typed connection result models.
- Add team billing status, Checkout, and Customer Portal API clients.
- Add worker execution start/report API clients and `BuildJob.billingAdmissionId`
  for paid CI admission and usage accounting.
- Add Freezed value equality and `copyWith()` to changed-file results.

## 1.0.6

- Add `commitMessage` field to `BuildJob` model.
- Publish the current authenticated API clients required by the OpenCI CLI,
  including team and secret commands.
- Include build plans, steps, webhook tasks, workflow files, changed-file
  results, and Loki log models and utilities.
- Remove obsolete generated `StepEvent` files left behind when the model moved
  to the `loki` directory.

## 1.0.5

- Add `CicdCommitGroup`, `CicdWorkflowGroup`, and `CicdJobGroup` models for CI/CD log visualization.

## 1.0.4

- Add constant-time comparison utilities (`constantTimeCompare`, `constantTimeCompareString`).

## 1.0.3


- Add Chopper API service and client utilities.

## 1.0.2

- Add runsOn field to BuildJob.

## 1.0.0

- Add githubBaseUrl and githubApiBaseUrl fields to BuildJob.
