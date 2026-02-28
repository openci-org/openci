-- Rename organizations → teams, org_members → team_members,
-- org_invitations → team_invitations, and all org_id → team_id columns.

BEGIN;

-- ============================================================
-- 1. Rename tables
-- ============================================================
ALTER TABLE public.organizations RENAME TO teams;
ALTER TABLE public.org_members RENAME TO team_members;
ALTER TABLE public.org_invitations RENAME TO team_invitations;

-- ============================================================
-- 2. Rename columns: org_id → team_id
-- ============================================================
ALTER TABLE public.teams RENAME CONSTRAINT organizations_pkey TO teams_pkey;
ALTER INDEX public.organizations_slug_key RENAME TO teams_slug_key;
ALTER INDEX public.idx_organizations_slug RENAME TO idx_teams_slug;

ALTER TABLE public.team_members RENAME COLUMN org_id TO team_id;
ALTER TABLE public.team_members RENAME CONSTRAINT org_members_pkey TO team_members_pkey;
ALTER TABLE public.team_members RENAME CONSTRAINT org_members_org_id_user_id_key TO team_members_team_id_user_id_key;
ALTER INDEX public.idx_org_members_org_id RENAME TO idx_team_members_team_id;
ALTER INDEX public.idx_org_members_user_id RENAME TO idx_team_members_user_id;

ALTER TABLE public.team_invitations RENAME COLUMN org_id TO team_id;
ALTER TABLE public.team_invitations RENAME CONSTRAINT org_invitations_pkey TO team_invitations_pkey;
ALTER INDEX public.org_invitations_token_key RENAME TO team_invitations_token_key;
ALTER INDEX public.idx_org_invitations_email RENAME TO idx_team_invitations_email;
ALTER INDEX public.idx_org_invitations_org_id RENAME TO idx_team_invitations_team_id;
ALTER INDEX public.idx_org_invitations_token RENAME TO idx_team_invitations_token;

ALTER TABLE public.builds RENAME COLUMN org_id TO team_id;
ALTER INDEX public.idx_builds_org_id_created RENAME TO idx_builds_team_id_created;

ALTER TABLE public.environment_variables RENAME COLUMN org_id TO team_id;
ALTER INDEX public.idx_env_vars_org_id RENAME TO idx_env_vars_team_id;
ALTER INDEX public.uq_env_vars_org_key RENAME TO uq_env_vars_team_key;

ALTER TABLE public.integrations RENAME COLUMN org_id TO team_id;
ALTER INDEX public.idx_integrations_org_id RENAME TO idx_integrations_team_id;
ALTER INDEX public.integrations_org_id_provider_installation_id_key
  RENAME TO integrations_team_id_provider_installation_id_key;

-- ============================================================
-- 3. Drop ALL old RLS policies first (before dropping functions they depend on)
-- ============================================================

-- teams (was organizations)
DROP POLICY IF EXISTS "organizations: members can read" ON public.teams;
DROP POLICY IF EXISTS "organizations: owners can update" ON public.teams;
DROP POLICY IF EXISTS "organizations: owners can delete" ON public.teams;

-- team_members (was org_members)
DROP POLICY IF EXISTS "org_members: members can read" ON public.team_members;
DROP POLICY IF EXISTS "org_members: admins can add members" ON public.team_members;
DROP POLICY IF EXISTS "org_members: owners can update roles" ON public.team_members;
DROP POLICY IF EXISTS "org_members: admins can remove members" ON public.team_members;

-- team_invitations (was org_invitations)
DROP POLICY IF EXISTS "org_invitations: admins can create invitations" ON public.team_invitations;
DROP POLICY IF EXISTS "org_invitations: admins can read org invitations" ON public.team_invitations;
DROP POLICY IF EXISTS "org_invitations: admins can update invitations" ON public.team_invitations;
DROP POLICY IF EXISTS "org_invitations: admins can delete invitations" ON public.team_invitations;

-- builds
DROP POLICY IF EXISTS "builds: org members can read" ON public.builds;
DROP POLICY IF EXISTS "builds: org admins can cancel" ON public.builds;

-- build_runs
DROP POLICY IF EXISTS "build_runs: org members can read" ON public.build_runs;

-- build_logs
DROP POLICY IF EXISTS "build_logs: org members can read" ON public.build_logs;

-- environment_variables
DROP POLICY IF EXISTS "env_vars: org members can read" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: org admins can create" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: org admins can update" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: org admins can delete" ON public.environment_variables;

-- integrations
DROP POLICY IF EXISTS "integrations: org members can read" ON public.integrations;
DROP POLICY IF EXISTS "integrations: org admins can manage" ON public.integrations;
DROP POLICY IF EXISTS "integrations: org admins can update" ON public.integrations;
DROP POLICY IF EXISTS "integrations: org admins can delete" ON public.integrations;

-- profiles
DROP POLICY IF EXISTS "profiles: org members can read each other" ON public.profiles;

-- ============================================================
-- 4. Drop old functions (now safe since policies are gone)
-- ============================================================
DROP FUNCTION IF EXISTS public.user_org_ids();
DROP FUNCTION IF EXISTS public.user_org_role(uuid);
DROP FUNCTION IF EXISTS public.user_org_write(uuid);

-- ============================================================
-- 5. Create new RLS helper functions
-- ============================================================

CREATE OR REPLACE FUNCTION public.user_team_ids()
  RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT COALESCE(array_agg(team_id), '{}')
  FROM public.team_members
  WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.user_team_role(p_team_id uuid)
  RETURNS text LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT role
  FROM public.team_members
  WHERE team_id = p_team_id AND user_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.user_team_write(p_team_id uuid)
  RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT public.user_team_role(p_team_id) IN ('owner', 'admin');
$$;

-- ============================================================
-- 4. Update create_organization() → create_team()
-- ============================================================
DROP FUNCTION IF EXISTS public.create_organization(text, text);

CREATE OR REPLACE FUNCTION public.create_team(p_name text, p_slug text)
  RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_team_id uuid;
BEGIN
  INSERT INTO public.teams (name, slug) VALUES (p_name, p_slug)
  RETURNING id INTO v_team_id;

  INSERT INTO public.team_members (team_id, user_id, role)
  VALUES (v_team_id, auth.uid(), 'owner');

  RETURN v_team_id;
END;
$$;

-- ============================================================
-- 5. Update handle_new_user_org trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user_org()
  RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_team_id uuid;
  v_slug text;
BEGIN
  v_slug := lower(regexp_replace(
    split_part(NEW.email, '@', 1),
    '[^a-zA-Z0-9]', '-', 'g'
  ));

  IF EXISTS (SELECT 1 FROM public.teams WHERE slug = v_slug) THEN
    v_slug := v_slug || '-' || substr(NEW.id::text, 1, 8);
  END IF;

  INSERT INTO public.teams (name, slug)
  VALUES (split_part(NEW.email, '@', 1), v_slug)
  RETURNING id INTO v_team_id;

  INSERT INTO public.team_members (team_id, user_id, role)
  VALUES (v_team_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$;

-- ============================================================
-- 6. Recreate RLS policies with new function refs
-- ============================================================

-- teams
CREATE POLICY "teams: members can read" ON public.teams
  FOR SELECT USING (id = ANY(user_team_ids()));
CREATE POLICY "teams: owners can update" ON public.teams
  FOR UPDATE USING (user_team_role(id) = 'owner');
CREATE POLICY "teams: owners can delete" ON public.teams
  FOR DELETE USING (user_team_role(id) = 'owner');

-- team_members
CREATE POLICY "team_members: members can read" ON public.team_members
  FOR SELECT USING (team_id = ANY(user_team_ids()));
CREATE POLICY "team_members: admins can add members" ON public.team_members
  FOR INSERT WITH CHECK (user_team_write(team_id));
CREATE POLICY "team_members: owners can update roles" ON public.team_members
  FOR UPDATE USING (user_team_role(team_id) = 'owner');
CREATE POLICY "team_members: admins can remove members" ON public.team_members
  FOR DELETE USING (user_team_write(team_id));

-- team_invitations
CREATE POLICY "team_invitations: admins can create" ON public.team_invitations
  FOR INSERT WITH CHECK (user_team_write(team_id));
CREATE POLICY "team_invitations: admins can read" ON public.team_invitations
  FOR SELECT USING (user_team_write(team_id));
CREATE POLICY "team_invitations: admins can update" ON public.team_invitations
  FOR UPDATE USING (user_team_write(team_id));
CREATE POLICY "team_invitations: admins can delete" ON public.team_invitations
  FOR DELETE USING (user_team_write(team_id));

-- builds
CREATE POLICY "builds: team members can read" ON public.builds
  FOR SELECT USING (team_id = ANY(user_team_ids()));
CREATE POLICY "builds: team admins can cancel" ON public.builds
  FOR UPDATE USING (user_team_write(team_id));

-- build_runs
CREATE POLICY "build_runs: team members can read" ON public.build_runs
  FOR SELECT USING (
    build_id IN (SELECT id FROM public.builds WHERE team_id = ANY(user_team_ids()))
  );

-- build_logs
CREATE POLICY "build_logs: team members can read" ON public.build_logs
  FOR SELECT USING (
    build_id IN (SELECT id FROM public.builds WHERE team_id = ANY(user_team_ids()))
  );

-- environment_variables
CREATE POLICY "env_vars: team members can read" ON public.environment_variables
  FOR SELECT USING (team_id = ANY(user_team_ids()));
CREATE POLICY "env_vars: team admins can create" ON public.environment_variables
  FOR INSERT WITH CHECK (user_team_write(team_id));
CREATE POLICY "env_vars: team admins can update" ON public.environment_variables
  FOR UPDATE USING (user_team_write(team_id));
CREATE POLICY "env_vars: team admins can delete" ON public.environment_variables
  FOR DELETE USING (user_team_write(team_id));

-- integrations
CREATE POLICY "integrations: team members can read" ON public.integrations
  FOR SELECT USING (team_id = ANY(user_team_ids()));
CREATE POLICY "integrations: team admins can manage" ON public.integrations
  FOR INSERT WITH CHECK (user_team_write(team_id));
CREATE POLICY "integrations: team admins can update" ON public.integrations
  FOR UPDATE USING (user_team_write(team_id));
CREATE POLICY "integrations: team admins can delete" ON public.integrations
  FOR DELETE USING (user_team_write(team_id));

-- profiles
CREATE POLICY "profiles: team members can read each other" ON public.profiles
  FOR SELECT USING (
    id IN (
      SELECT user_id FROM public.team_members
      WHERE team_id = ANY(public.user_team_ids())
    )
  );

-- ============================================================
-- 7. Update claim_next_build RPCs (they reference org_id)
-- ============================================================
-- Recreate to use team_id
CREATE OR REPLACE FUNCTION public.claim_next_build(p_runner_os runner_os DEFAULT 'macos')
  RETURNS SETOF builds LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_build builds;
BEGIN
  SELECT * INTO v_build
  FROM builds
  WHERE status = 'queued' AND runner_os = p_runner_os
  ORDER BY created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  UPDATE builds SET status = 'in_progress', updated_at = now()
  WHERE id = v_build.id;

  v_build.status := 'in_progress';
  RETURN NEXT v_build;
END;
$$;

-- ============================================================
-- 8. Update increment_env_var to use team_id
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_env_var(p_team_id uuid, p_key text)
  RETURNS text LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_current text;
  v_new_val integer;
BEGIN
  SELECT value INTO v_current
  FROM environment_variables
  WHERE team_id = p_team_id AND key = p_key AND auto_increment = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No auto-increment env var found for key %', p_key;
  END IF;

  v_new_val := v_current::integer + 1;

  UPDATE environment_variables
  SET value = v_new_val::text, updated_at = now()
  WHERE team_id = p_team_id AND key = p_key;

  RETURN v_new_val::text;
END;
$$;

COMMIT;
