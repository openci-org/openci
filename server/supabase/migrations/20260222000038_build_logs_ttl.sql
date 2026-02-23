-- Build logs TTL: delete logs older than 7 days.
-- The SQL function is called by pg_cron (enabled via Supabase Dashboard > Extensions).
-- To register the cron job on the hosted project, run the following SQL once in
-- the Supabase SQL Editor (requires pg_cron to be enabled first):
--
--   SELECT cron.schedule(
--     'purge-old-build-logs',
--     '0 3 * * *',
--     $$ SELECT public.purge_old_build_logs(); $$
--   );

CREATE OR REPLACE FUNCTION public.purge_old_build_logs()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.build_logs
  WHERE created_at < now() - interval '7 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.purge_old_build_logs() TO service_role;
