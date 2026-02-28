-- Drop build_runs table and simplify build_logs to reference builds directly.
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

-- 6. Revoke worker_role grants on build_runs (already gone via CASCADE, but be explicit)
-- (No-op since table is dropped)

COMMIT;
