-- One-time setup: register the build-logs TTL cron job.
-- Run via: make sb-setup-cron
--
-- Prerequisites:
--   1. pg_cron extension must be enabled on the Supabase project.
--      Dashboard → Database → Extensions → pg_cron → Enable
--   2. Migration 20260222000038_build_logs_ttl.sql must have been applied.

-- Remove existing job with the same name (idempotent)
SELECT cron.unschedule('purge-old-build-logs')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'purge-old-build-logs'
);

-- Register: run daily at 03:00 UTC
SELECT cron.schedule(
  'purge-old-build-logs',
  '0 3 * * *',
  $$ SELECT public.purge_old_build_logs(); $$
);

-- Confirm
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'purge-old-build-logs';
