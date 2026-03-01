-- Move yaml_definition from workflows into builds directly.
-- Workers no longer need to join the workflows table.

ALTER TABLE public.builds
  ADD COLUMN yaml_definition text;

-- Drop workflow_id FK (no longer needed)
ALTER TABLE public.builds
  DROP CONSTRAINT IF EXISTS builds_workflow_id_fkey;

ALTER TABLE public.builds
  DROP COLUMN IF EXISTS workflow_id;

-- Drop the builds index on workflow_id
DROP INDEX IF EXISTS idx_builds_workflow_id;

-- Recreate claim_next_build without workflow_id reference
CREATE OR REPLACE FUNCTION public.claim_next_build(p_worker_id text, p_runner_os runner_os DEFAULT 'macos')
RETURNS public.builds LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_build public.builds;
BEGIN
  SELECT *
  INTO v_build
  FROM public.builds
  WHERE status = 'queued'
    AND runner_os = p_runner_os
  ORDER BY created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  UPDATE public.builds
  SET
    status     = 'in_progress',
    updated_at = now()
  WHERE id = v_build.id
  RETURNING * INTO v_build;

  RETURN v_build;
END;
$$;
