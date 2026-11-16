-- Run after adding the repository columns and unique key, before deploying the
-- repository-aware schema/connectors and enabling repository confirmations.
-- No rows or legacy permissions are changed. Run as the existing schema owner.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';
LOCK TABLE public.github_connections IN ACCESS EXCLUSIVE MODE;

DO $migration$
DECLARE
  old_key record;
BEGIN
  -- Refuse to remove the old boundary until the new one is enforced.
  IF NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = 'public.github_connections'::regclass
      AND i.indisunique AND i.indisvalid
      AND i.indpred IS NULL AND i.indexprs IS NULL
      AND (
        SELECT array_agg(a.attname::text ORDER BY a.attname)
        FROM unnest(i.indkey::smallint[]) WITH ORDINALITY AS k(attnum, position)
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
        WHERE k.position <= i.indnkeyatts
      ) = ARRAY['github_api_base_url', 'github_app_id', 'repository_id']
  ) THEN
    RAISE EXCEPTION 'Deploy the unique host/App/repository key before this migration';
  END IF;

  -- SQL Connect rejects unique indexes absent from its schema, including this
  -- partial index from the first migration version. Existing legacy rows remain;
  -- ConfirmGitHubConnection requires a positive repository ID for every new row.
  DROP INDEX IF EXISTS public.github_connections_legacy_installation_key;

  -- Match exact key columns rather than relying on generated/truncated names.
  -- Both constraint-backed and standalone unique indexes are supported.
  FOR old_key IN
    SELECT c.conname, n.nspname, idx.relname
    FROM pg_index i
    JOIN pg_class idx ON idx.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = idx.relnamespace
    LEFT JOIN pg_constraint c ON c.conindid = i.indexrelid AND c.contype = 'u'
    WHERE i.indrelid = 'public.github_connections'::regclass
      AND i.indisunique AND NOT i.indisprimary
      AND i.indpred IS NULL AND i.indexprs IS NULL
      AND (
        SELECT array_agg(a.attname::text ORDER BY a.attname)
        FROM unnest(i.indkey::smallint[]) WITH ORDINALITY AS k(attnum, position)
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
        WHERE k.position <= i.indnkeyatts
      ) = ARRAY['github_api_base_url', 'github_app_id', 'installation_id']
  LOOP
    IF old_key.conname IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.github_connections DROP CONSTRAINT %I', old_key.conname);
    ELSE
      EXECUTE format('DROP INDEX %I.%I', old_key.nspname, old_key.relname);
    END IF;
  END LOOP;
END
$migration$;

COMMIT;
