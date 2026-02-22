-- Row Level Security policies for all tables
-- Worker (worker_role) bypasses RLS via direct DB connection
-- Webhook handler uses service_role (bypasses RLS)
-- Dashboard users use authenticated role (subject to RLS)

-- ============================================================
-- profiles
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: users can read own profile"
  ON public.profiles FOR SELECT
  USING (id = (SELECT auth.uid()));

CREATE POLICY "profiles: users can update own profile"
  ON public.profiles FOR UPDATE
  USING (id = (SELECT auth.uid()));

-- ============================================================
-- organizations
-- ============================================================
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organizations: members can read"
  ON public.organizations FOR SELECT
  USING (id = ANY(public.user_org_ids()));

CREATE POLICY "organizations: owners can update"
  ON public.organizations FOR UPDATE
  USING (public.user_org_role(id) = 'owner');

CREATE POLICY "organizations: owners can delete"
  ON public.organizations FOR DELETE
  USING (public.user_org_role(id) = 'owner');

-- INSERT is handled by the handle_new_user_org() trigger (SECURITY DEFINER)
-- No direct user INSERT policy needed.

-- ============================================================
-- org_members
-- ============================================================
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_members: members can read"
  ON public.org_members FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "org_members: admins can add members"
  ON public.org_members FOR INSERT
  WITH CHECK (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "org_members: owners can update roles"
  ON public.org_members FOR UPDATE
  USING (
    public.user_org_role(org_id) = 'owner'
    OR user_id = (SELECT auth.uid())  -- Users can remove themselves
  );

CREATE POLICY "org_members: admins can remove members"
  ON public.org_members FOR DELETE
  USING (
    public.user_org_role(org_id) IN ('owner', 'admin')
    OR user_id = (SELECT auth.uid())  -- Users can remove themselves
  );

-- ============================================================
-- org_invitations
-- ============================================================
ALTER TABLE public.org_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_invitations: admins can read org invitations"
  ON public.org_invitations FOR SELECT
  USING (
    public.user_org_role(org_id) IN ('owner', 'admin')
    -- Invitee can see their own pending invite for the accept flow
    OR (
      email = (SELECT auth.email())
      AND status = 'pending'
    )
  );

CREATE POLICY "org_invitations: admins can create invitations"
  ON public.org_invitations FOR INSERT
  WITH CHECK (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "org_invitations: admins can update invitations"
  ON public.org_invitations FOR UPDATE
  USING (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "org_invitations: admins can delete invitations"
  ON public.org_invitations FOR DELETE
  USING (public.user_org_role(org_id) IN ('owner', 'admin'));

-- ============================================================
-- projects
-- ============================================================
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "projects: org members can read"
  ON public.projects FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "projects: org admins can create projects"
  ON public.projects FOR INSERT
  WITH CHECK (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "projects: write role can update"
  ON public.projects FOR UPDATE
  USING (
    public.user_project_role(id) = 'write'
    OR public.user_org_role(org_id) IN ('owner', 'admin')
  );

CREATE POLICY "projects: org owners can delete"
  ON public.projects FOR DELETE
  USING (public.user_org_role(org_id) = 'owner');

-- ============================================================
-- project_members
-- ============================================================
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "project_members: org members can read"
  ON public.project_members FOR SELECT
  USING (project_id = ANY(public.user_project_ids()));

CREATE POLICY "project_members: project write can manage"
  ON public.project_members FOR INSERT
  WITH CHECK (public.user_project_role(project_id) = 'write');

CREATE POLICY "project_members: project write can update"
  ON public.project_members FOR UPDATE
  USING (public.user_project_role(project_id) = 'write');

CREATE POLICY "project_members: project write can delete"
  ON public.project_members FOR DELETE
  USING (
    public.user_project_role(project_id) = 'write'
    OR user_id = (SELECT auth.uid())  -- Users can remove themselves
  );

-- ============================================================
-- workflows
-- ============================================================
ALTER TABLE public.workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workflows: project members can read"
  ON public.workflows FOR SELECT
  USING (project_id = ANY(public.user_project_ids()));

CREATE POLICY "workflows: write role can create"
  ON public.workflows FOR INSERT
  WITH CHECK (public.user_project_role(project_id) = 'write');

CREATE POLICY "workflows: write role can update"
  ON public.workflows FOR UPDATE
  USING (public.user_project_role(project_id) = 'write');

CREATE POLICY "workflows: write role can delete"
  ON public.workflows FOR DELETE
  USING (public.user_project_role(project_id) = 'write');

-- ============================================================
-- workflow_triggers
-- ============================================================
ALTER TABLE public.workflow_triggers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workflow_triggers: project members can read"
  ON public.workflow_triggers FOR SELECT
  USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE project_id = ANY(public.user_project_ids())
    )
  );

CREATE POLICY "workflow_triggers: write role can manage"
  ON public.workflow_triggers FOR INSERT
  WITH CHECK (
    (SELECT project_id FROM public.workflows WHERE id = workflow_id)
      = ANY(public.user_project_ids())
    AND public.user_project_role(
      (SELECT project_id FROM public.workflows WHERE id = workflow_id)
    ) = 'write'
  );

CREATE POLICY "workflow_triggers: write role can update"
  ON public.workflow_triggers FOR UPDATE
  USING (
    public.user_project_role(
      (SELECT project_id FROM public.workflows WHERE id = workflow_id)
    ) = 'write'
  );

CREATE POLICY "workflow_triggers: write role can delete"
  ON public.workflow_triggers FOR DELETE
  USING (
    public.user_project_role(
      (SELECT project_id FROM public.workflows WHERE id = workflow_id)
    ) = 'write'
  );

-- ============================================================
-- builds
-- ============================================================
ALTER TABLE public.builds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "builds: project members can read"
  ON public.builds FOR SELECT
  USING (project_id = ANY(public.user_project_ids()));

-- Only write-role users can cancel a build (update status to 'cancelled')
CREATE POLICY "builds: write role can cancel"
  ON public.builds FOR UPDATE
  USING (public.user_project_role(project_id) = 'write');

-- INSERT and service operations are done via service_role (webhook handler)

-- ============================================================
-- build_runs
-- ============================================================
ALTER TABLE public.build_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "build_runs: project members can read"
  ON public.build_runs FOR SELECT
  USING (
    build_id IN (
      SELECT id FROM public.builds
      WHERE project_id = ANY(public.user_project_ids())
    )
  );

-- Worker writes via worker_role (direct DB connection, not subject to RLS)

-- ============================================================
-- build_logs
-- ============================================================
ALTER TABLE public.build_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "build_logs: project members can read"
  ON public.build_logs FOR SELECT
  USING (
    build_id IN (
      SELECT id FROM public.builds
      WHERE project_id = ANY(public.user_project_ids())
    )
  );

-- Worker writes via worker_role (direct DB connection, not subject to RLS)

-- ============================================================
-- environment_variables
-- ============================================================
ALTER TABLE public.environment_variables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "env_vars: project members can read"
  ON public.environment_variables FOR SELECT
  USING (project_id = ANY(public.user_project_ids()));

CREATE POLICY "env_vars: write role can create"
  ON public.environment_variables FOR INSERT
  WITH CHECK (public.user_project_role(project_id) = 'write');

CREATE POLICY "env_vars: write role can update"
  ON public.environment_variables FOR UPDATE
  USING (public.user_project_role(project_id) = 'write');

CREATE POLICY "env_vars: write role can delete"
  ON public.environment_variables FOR DELETE
  USING (public.user_project_role(project_id) = 'write');

-- ============================================================
-- integrations
-- ============================================================
ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "integrations: org members can read"
  ON public.integrations FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "integrations: org admins can manage"
  ON public.integrations FOR INSERT
  WITH CHECK (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "integrations: org admins can update"
  ON public.integrations FOR UPDATE
  USING (public.user_org_role(org_id) IN ('owner', 'admin'));

CREATE POLICY "integrations: org admins can delete"
  ON public.integrations FOR DELETE
  USING (public.user_org_role(org_id) IN ('owner', 'admin'));

-- ============================================================
-- worker_config
-- ============================================================
ALTER TABLE public.worker_config ENABLE ROW LEVEL SECURITY;

-- Public read (worker version check is unauthenticated)
CREATE POLICY "worker_config: anyone can read"
  ON public.worker_config FOR SELECT
  USING (true);

-- No user INSERT/UPDATE/DELETE policies; managed via service_role only
