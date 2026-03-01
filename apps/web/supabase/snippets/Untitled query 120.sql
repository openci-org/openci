SELECT cron.schedule(
  'purge-old-build-logs',
  '0 3 * * *',
  $$ SELECT public.purge_old_build_logs(); $$
);