# Changelog

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
