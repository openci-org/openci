-- Drop build_runs table, worker_config table, and fix duplicate indexes.
-- Retries are modeled as new build records using builds.retried_from_build_id.

BEGIN;

-- 1. Remove build_run_id FK and column from build_logs
ALTER TABLE public.build_logs DROP CONSTRAINT IF EXISTS build_logs_build_run_id_fkey;
DROP INDEX IF EXISTS idx_build_logs_run_id_created;
DROP INDEX IF EXISTS idx_build_logs_run_step;
ALTER TABLE public.build_logs DROP COLUMN IF EXISTS build_run_id;

-- 2. Add step indexes on build_logs (previously on build_run_id)
CREATE INDEX IF NOT EXISTS idx_build_logs_build_id_created
  ON public.build_logs(build_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_build_logs_build_step
  ON public.build_logs(build_id, step_index, id);

-- 3. Remove run-related columns from builds
ALTER TABLE public.builds DROP COLUMN IF EXISTS run_count;
ALTER TABLE public.builds DROP COLUMN IF EXISTS latest_run_id;

-- 4. Drop build_runs table (CASCADE removes triggers, policies, etc.)
DROP TABLE IF EXISTS public.build_runs CASCADE;

-- 5. Drop the trigger function that was used by build_runs
DROP FUNCTION IF EXISTS public.update_build_on_run_created();

-- 6. Drop worker_config table (no longer used; version check uses GitHub Releases API)
DROP POLICY IF EXISTS "worker_config: anyone can read" ON public.worker_config;
REVOKE ALL ON public.worker_config FROM worker_role;
DROP TABLE IF EXISTS public.worker_config;

-- 7. Fix duplicate indexes on builds
--    idx_builds_queued and idx_builds_queued_runner_os had identical definitions.
--    Replace both with a proper composite index that includes runner_os for claim_next_build().
DROP INDEX IF EXISTS idx_builds_queued;
DROP INDEX IF EXISTS idx_builds_queued_runner_os;
CREATE INDEX idx_builds_queued_runner_os
  ON public.builds(runner_os, created_at ASC)
  WHERE status = 'queued';

COMMIT;
