-- Add runner_os to builds so workers can filter jobs by platform

CREATE TYPE runner_os AS ENUM ('macos', 'linux');

ALTER TABLE public.builds
  ADD COLUMN runner_os runner_os NOT NULL DEFAULT 'macos';

CREATE INDEX idx_builds_queued_runner_os
  ON public.builds(created_at ASC)
  WHERE status = 'queued';

-- Recreate claim_next_build with runner_os filter
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

GRANT EXECUTE ON FUNCTION public.claim_next_build(text, runner_os) TO worker_role;
