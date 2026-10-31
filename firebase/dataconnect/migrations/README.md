# Retired storage cleanup — 2026-10-31

The FSC cutover is complete. This cleanup removes definitions with no production
callers and the corresponding unused physical storage. It does not change the
retained billing ledger, build history or runtime operations.

## Scope

- Empty tables: `billing_trial_claims` and `skipped_workflow_reports`.
- Unpopulated `build_jobs` columns: `app_name`, `bundle_id`,
  `failure_summary_duration_ms`, `failure_summary_model`, `has_ipa`, `ipa_url`,
  `ipa_version` and `provisioned_udids`.
- Previously omitted `teams` columns: `ai_enabled` and `installation_ids`.
- Fifteen unused operations: `GetOpenBillingCheckoutCreation`,
  `GetBillingCustomerCreation`, `GetExpiredBillingWork`, `GetQueuedBillingJobs`,
  `GetBillingWorkerJobs`, `GetBuildJobDispatch`, `FinishBuildJobDispatch`,
  `GetGitHubConnections`, `GetBuildSteps`, `UpdateSecretReference`,
  `DeleteSecretReference`, `GetBillingTrialEligibility`, `StartBillingTrial`,
  `CreateSecretReference` and `GetSecretReference`.

The remaining 23 tables, 98 operations and 17 fragments are used by the current
Functions, planner, executor or Dashboard. Retained GraphQL operations and
fragments have no semantic changes. Generated SDKs were rebuilt; the unused
Dashboard billing/GitHub SDK generators, old PostgreSQL import tools, their `pg`
dependency and unused shared workflow-plan models were removed.

## Application order

1. Check runtime references and verify the retired tables are empty and the eight
   build columns are NULL. Preserve the two old team-column values separately.
2. Take a Cloud SQL backup and wait for completion. Retain copies of the deployed
   schema and connectors.
3. Remove the unused operations from deployed connectors, then deploy the reduced
   GraphQL schema with `COMPATIBLE` validation. This leaves the obsolete SQL
   storage in place until the next step.
4. Run [the SQL transaction](20261031_retire_unused_storage.sql) as the existing
   schema owner, after validating the same transaction with `ROLLBACK` in place
   of `COMMIT`. The migration locks the affected tables, rechecks that retired
   storage is empty and commits all four DDL changes together. It is a one-time
   migration and deliberately fails if reapplied or if the preconditions change.
5. Validate the deployed schema against SQL using `STRICT` in validation-only
   mode. Verify the physical catalog, retained row counts and read-only calls
   through the deployed connectors.

The schema migration REST endpoint returned `UNIMPLEMENTED` in this environment.
The reviewed SQL was applied through the Cloud SQL connector with the existing
operator IAM identity and schema-owner membership; no IAM grants were added.

## Production record

- Project: `openci-b1b91`; region: `asia-northeast1`.
- Service: `openci-b1b91-service`.
- Cloud SQL: `openci-b1b91-instance` / `openci-b1b91-database`.
- Completed backup: `1793443881930` (`Before FSC schema cleanup 2026-10-31`).
- SQL committed: `2026-10-31T10:57:38Z`.
- Post-deploy verification: all eight connectors and the schema match local
  definitions; validation-only `STRICT` passes; neither retired table nor any of
  the ten obsolete columns remains in the physical catalog.
- Preserved counts: 6,977 build jobs, 2 billing accounts, 3 billing periods and
  124 billing executions, unchanged from preflight.
- Read-only deployed-query checks passed for `GetActiveBuildDispatches`,
  `GetRecoverableBuildExecutions`, `GetBuildExecution`, `GetBillingContext`,
  `GetMyTeams`, `GetBuildJobs` and `GetSecrets`. Client queries used a verified
  existing member's impersonated identity to exercise their access checks.
- Private preflight evidence, old team-column values, deployed sources and
  verification results: `~/Backups/openci/fsc-schema-cleanup-20261031/` on the
  operator machine. These files are not committed to the repository.

Local format/static checks and 1,936 tests passed across Functions, the SQL
emulator, Dashboard, the shared Dart package, planner and CLI. Five existing
Dashboard web-only tests were skipped by the VM test runner. This cleanup did not
launch a new end-to-end build or repeat Stripe purchase tests.

Restoring an old database backup would also revert newer purchases and usage.
Any recovery must preserve and reconcile writes recorded after this cleanup.
