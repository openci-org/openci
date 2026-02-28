-- ============================================================
-- Migration: Drop build_runs table and worker_config table
-- ============================================================

-- 1. Remove build_run_id from build_logs and link directly to builds
ALTER TABLE public.build_logs
  DROP COLUMN IF EXISTS build_run_id;

ALTER TABLE public.build_logs
  ADD COLUMN IF NOT EXISTS step_index integer,
  ADD COLUMN IF NOT EXISTS step_name text;

-- 2. Remove run_count and latest_run_id from builds
ALTER TABLE public.builds
  DROP COLUMN IF EXISTS run_count,
  DROP COLUMN IF EXISTS latest_run_id;

-- 3. Drop RLS policies on build_runs
DROP POLICY IF EXISTS "build_runs: team members can view" ON public.build_runs;
DROP POLICY IF EXISTS "build_runs: worker can manage" ON public.build_runs;

-- 4. Revoke worker_role permissions on build_runs
REVOKE ALL ON public.build_runs FROM worker_role;

-- 5. Drop build_runs table (this cascades trigger removal)
DROP TABLE IF EXISTS public.build_runs CASCADE;

-- 6. Drop orphaned function
DROP FUNCTION IF EXISTS public.update_build_on_run_created() CASCADE;

-- 7. Add useful indexes for build_logs -> builds
CREATE INDEX IF NOT EXISTS idx_build_logs_build_id_created
  ON public.build_logs (build_id, created_at);

CREATE INDEX IF NOT EXISTS idx_build_logs_build_step
  ON public.build_logs (build_id, step_index);

-- 8. Drop RLS policies on worker_config
DROP POLICY IF EXISTS "worker_config: anyone can read" ON public.worker_config;

-- 9. Revoke worker_role permissions on worker_config
REVOKE ALL ON public.worker_config FROM worker_role;

-- 10. Drop worker_config table
DROP TABLE IF EXISTS public.worker_config;
