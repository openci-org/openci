-- RPC functions called by the Mac worker via PostgREST

-- claim_next_build: atomically claim the next queued build.
-- Uses FOR UPDATE SKIP LOCKED to support multiple concurrent workers
-- without double-claiming the same job.
CREATE OR REPLACE FUNCTION public.claim_next_build(p_worker_id text)
RETURNS public.builds LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_build public.builds;
BEGIN
  -- Lock the next queued build (skip any already locked by another worker)
  SELECT *
  INTO v_build
  FROM public.builds
  WHERE status = 'queued'
  ORDER BY created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Mark as in_progress atomically within the same transaction
  UPDATE public.builds
  SET
    status     = 'in_progress',
    updated_at = now()
  WHERE id = v_build.id
  RETURNING * INTO v_build;

  RETURN v_build;
END;
$$;

-- increment_env_var: atomically increment a numeric auto-increment env var.
-- Returns the value BEFORE incrementing (the current build uses this value).
CREATE OR REPLACE FUNCTION public.increment_env_var(p_env_var_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_current text;
  v_num     int;
BEGIN
  SELECT value
  INTO v_current
  FROM public.environment_variables
  WHERE id = p_env_var_id AND auto_increment = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Cast to int; fails loudly if the value is not a valid integer
  v_num := v_current::int + 1;

  UPDATE public.environment_variables
  SET
    value      = v_num::text,
    updated_at = now()
  WHERE id = p_env_var_id;

  -- Return the value before incrementing (current build number)
  RETURN v_current;
END;
$$;

-- create_organization: service-role RPC to create an org and add the caller as owner.
-- Used by the dashboard's org creation flow.
CREATE OR REPLACE FUNCTION public.create_organization(
  p_name text,
  p_slug text
)
RETURNS public.organizations LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_org public.organizations;
BEGIN
  INSERT INTO public.organizations (name, slug)
  VALUES (p_name, p_slug)
  RETURNING * INTO v_org;

  INSERT INTO public.org_members (org_id, user_id, role)
  VALUES (v_org.id, auth.uid(), 'owner');

  RETURN v_org;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_organization(text, text) TO authenticated;

-- worker_role RPC grants (role created in 20260222000030, functions created above)
GRANT EXECUTE ON FUNCTION public.claim_next_build(text) TO worker_role;
GRANT EXECUTE ON FUNCTION public.increment_env_var(uuid) TO worker_role;
