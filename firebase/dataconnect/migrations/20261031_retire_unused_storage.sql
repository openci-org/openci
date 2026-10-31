-- Apply after the retired operations and GraphQL definitions have been removed.
-- Preflight: both retired tables are empty and all eight removed build columns
-- are NULL. Retain a Cloud SQL backup and the old team-column values first.
-- Run as the existing schema owner. Commit all removals together, and fail
-- instead of waiting for locks or discarding newly populated storage.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

LOCK TABLE "public"."billing_trial_claims", "public"."skipped_workflow_reports",
  "public"."build_jobs", "public"."teams" IN ACCESS EXCLUSIVE MODE;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "public"."billing_trial_claims")
    OR EXISTS (SELECT 1 FROM "public"."skipped_workflow_reports")
    OR EXISTS (
      SELECT 1 FROM "public"."build_jobs"
      WHERE "app_name" IS NOT NULL OR "bundle_id" IS NOT NULL
        OR "failure_summary_duration_ms" IS NOT NULL
        OR "failure_summary_model" IS NOT NULL OR "has_ipa" IS NOT NULL
        OR "ipa_url" IS NOT NULL OR "ipa_version" IS NOT NULL
        OR "provisioned_udids" IS NOT NULL
    ) THEN
    RAISE EXCEPTION 'Retired storage contains data; review before cleanup';
  END IF;
END $$;

ALTER TABLE "public"."build_jobs" DROP COLUMN "app_name", DROP COLUMN "bundle_id", DROP COLUMN "failure_summary_duration_ms", DROP COLUMN "failure_summary_model", DROP COLUMN "has_ipa", DROP COLUMN "ipa_url", DROP COLUMN "ipa_version", DROP COLUMN "provisioned_udids";

ALTER TABLE "public"."teams" DROP COLUMN "ai_enabled", DROP COLUMN "installation_ids";

DROP TABLE "public"."billing_trial_claims";

DROP TABLE "public"."skipped_workflow_reports";

COMMIT;
