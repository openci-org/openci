-- Dedicated PostgreSQL role for the Mac worker with minimum required permissions.
-- The worker connects directly via DATABASE_URL (not via PostgREST + JWT),
-- so it bypasses RLS entirely. Permissions are enforced at the GRANT level.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'worker_role') THEN
    CREATE ROLE worker_role WITH LOGIN PASSWORD 'CHANGE_ME_IN_PRODUCTION';
  END IF;
END;
$$;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO worker_role;

-- builds: worker reads queued jobs and updates status
GRANT SELECT, UPDATE ON public.builds TO worker_role;

-- build_runs: worker creates run records (uuid PK, no sequence needed)
GRANT INSERT, UPDATE ON public.build_runs TO worker_role;

-- build_logs: worker inserts log lines
GRANT INSERT ON public.build_logs TO worker_role;
GRANT USAGE ON SEQUENCE public.build_logs_id_seq TO worker_role;

-- workflows: worker reads workflow steps from yaml_definition
GRANT SELECT ON public.workflows TO worker_role;

-- environment_variables: worker reads env vars for the project
GRANT SELECT, UPDATE ON public.environment_variables TO worker_role;

-- worker_config: worker reads for self-update check
GRANT SELECT ON public.worker_config TO worker_role;

-- integrations: worker reads GitHub installation IDs
GRANT SELECT ON public.integrations TO worker_role;

-- RPC GRANT statements are in 20260222000031_create_rpcs.sql
-- (functions must exist before they can be granted)
