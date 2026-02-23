-- Fix auth_rls_initplan warnings: wrap auth.uid() and auth.email() in
-- (SELECT ...) so PostgreSQL evaluates them once per query, not once per row.
-- See: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select

-- ============================================================
-- profiles
-- ============================================================
DROP POLICY IF EXISTS "profiles: users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles: users can update own profile" ON public.profiles;

CREATE POLICY "profiles: users can read own profile"
  ON public.profiles FOR SELECT
  USING (id = (SELECT auth.uid()));

CREATE POLICY "profiles: users can update own profile"
  ON public.profiles FOR UPDATE
  USING (id = (SELECT auth.uid()));

-- ============================================================
-- org_members (policies that reference auth.uid() directly)
-- ============================================================
DROP POLICY IF EXISTS "org_members: owners can update roles" ON public.org_members;
DROP POLICY IF EXISTS "org_members: admins can remove members" ON public.org_members;

CREATE POLICY "org_members: owners can update roles"
  ON public.org_members FOR UPDATE
  USING (
    public.user_org_role(org_id) = 'owner'
    OR user_id = (SELECT auth.uid())
  );

CREATE POLICY "org_members: admins can remove members"
  ON public.org_members FOR DELETE
  USING (
    public.user_org_role(org_id) IN ('owner', 'admin')
    OR user_id = (SELECT auth.uid())
  );

-- ============================================================
-- org_invitations (auth.email() reference)
-- ============================================================
DROP POLICY IF EXISTS "org_invitations: admins can read org invitations" ON public.org_invitations;

CREATE POLICY "org_invitations: admins can read org invitations"
  ON public.org_invitations FOR SELECT
  USING (
    public.user_org_role(org_id) IN ('owner', 'admin')
    OR (
      email = (SELECT auth.email())
      AND status = 'pending'
    )
  );

-- ============================================================
-- project_members (auth.uid() reference)
-- ============================================================
DROP POLICY IF EXISTS "project_members: project write can delete" ON public.project_members;

CREATE POLICY "project_members: project write can delete"
  ON public.project_members FOR DELETE
  USING (
    public.user_project_role(project_id) = 'write'
    OR user_id = (SELECT auth.uid())
  );
