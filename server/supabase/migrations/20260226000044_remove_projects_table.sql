-- Remove the projects layer: workflows, builds, environment_variables
-- now reference org_id directly instead of project_id.

-- ============================================================
-- 1. Add org_id columns (nullable temporarily)
-- ============================================================

ALTER TABLE public.workflows
  ADD COLUMN org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.builds
  ADD COLUMN org_id uuid REFERENCES public.organizations(id);

ALTER TABLE public.environment_variables
  ADD COLUMN org_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;

-- ============================================================
-- 2. Back-fill org_id from existing project_id → projects.org_id
-- ============================================================

UPDATE public.workflows w
  SET org_id = p.org_id
  FROM public.projects p
  WHERE w.project_id = p.id;

UPDATE public.builds b
  SET org_id = p.org_id
  FROM public.projects p
  WHERE b.project_id = p.id;

UPDATE public.environment_variables ev
  SET org_id = p.org_id
  FROM public.projects p
  WHERE ev.project_id = p.id;

-- ============================================================
-- 3. Drop old RLS policies that reference project_id BEFORE dropping columns
-- ============================================================

DROP POLICY IF EXISTS "workflows: project members can read" ON public.workflows;
DROP POLICY IF EXISTS "workflows: write role can create" ON public.workflows;
DROP POLICY IF EXISTS "workflows: write role can update" ON public.workflows;
DROP POLICY IF EXISTS "workflows: write role can delete" ON public.workflows;

DROP POLICY IF EXISTS "workflow_triggers: project members can read" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: write role can manage" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: write role can update" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: write role can delete" ON public.workflow_triggers;

DROP POLICY IF EXISTS "builds: project members can read" ON public.builds;
DROP POLICY IF EXISTS "builds: write role can cancel" ON public.builds;

DROP POLICY IF EXISTS "build_runs: project members can read" ON public.build_runs;

DROP POLICY IF EXISTS "build_logs: project members can read" ON public.build_logs;

DROP POLICY IF EXISTS "env_vars: project members can read" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: write role can create" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: write role can update" ON public.environment_variables;
DROP POLICY IF EXISTS "env_vars: write role can delete" ON public.environment_variables;

-- ============================================================
-- 4. Make org_id NOT NULL, drop project_id
-- ============================================================

ALTER TABLE public.workflows
  ALTER COLUMN org_id SET NOT NULL;
ALTER TABLE public.workflows
  DROP COLUMN project_id;

ALTER TABLE public.builds
  ALTER COLUMN org_id SET NOT NULL;
ALTER TABLE public.builds
  DROP COLUMN project_id;

ALTER TABLE public.environment_variables
  ALTER COLUMN org_id SET NOT NULL;
ALTER TABLE public.environment_variables
  DROP COLUMN project_id;

-- ============================================================
-- 4. Fix UNIQUE constraint on environment_variables
-- ============================================================

ALTER TABLE public.environment_variables
  ADD CONSTRAINT uq_env_vars_org_key UNIQUE (org_id, key);

-- ============================================================
-- 5. Create indexes
-- ============================================================

CREATE INDEX idx_workflows_org_id ON public.workflows(org_id);
CREATE INDEX idx_builds_org_id_created ON public.builds(org_id, created_at DESC);
CREATE INDEX idx_env_vars_org_id ON public.environment_variables(org_id);

-- ============================================================
-- 6. Drop projects and project_members tables
-- ============================================================

DROP TABLE IF EXISTS public.project_members CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;

-- ============================================================
-- 7. Drop project-related RLS helper functions
-- ============================================================

DROP FUNCTION IF EXISTS public.user_project_ids();
DROP FUNCTION IF EXISTS public.user_project_role(uuid);

-- ============================================================
-- 8. Create new org-based write helper
-- ============================================================

CREATE OR REPLACE FUNCTION public.user_org_write(p_org_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.org_members
    WHERE org_id = p_org_id
      AND user_id = (SELECT auth.uid())
      AND role IN ('owner', 'admin')
  );
$$;

-- ============================================================
-- 9. Create new RLS policies for workflows
-- ============================================================

CREATE POLICY "workflows: org members can read"
  ON public.workflows FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "workflows: org admins can create"
  ON public.workflows FOR INSERT
  WITH CHECK (public.user_org_write(org_id));

CREATE POLICY "workflows: org admins can update"
  ON public.workflows FOR UPDATE
  USING (public.user_org_write(org_id));

CREATE POLICY "workflows: org admins can delete"
  ON public.workflows FOR DELETE
  USING (public.user_org_write(org_id));

-- ============================================================
-- 10. Create new RLS policies for workflow_triggers
-- ============================================================

CREATE POLICY "workflow_triggers: org members can read"
  ON public.workflow_triggers FOR SELECT
  USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE org_id = ANY(public.user_org_ids())
    )
  );

CREATE POLICY "workflow_triggers: org admins can create"
  ON public.workflow_triggers FOR INSERT
  WITH CHECK (
    public.user_org_write(
      (SELECT org_id FROM public.workflows WHERE id = workflow_id)
    )
  );

CREATE POLICY "workflow_triggers: org admins can update"
  ON public.workflow_triggers FOR UPDATE
  USING (
    public.user_org_write(
      (SELECT org_id FROM public.workflows WHERE id = workflow_id)
    )
  );

CREATE POLICY "workflow_triggers: org admins can delete"
  ON public.workflow_triggers FOR DELETE
  USING (
    public.user_org_write(
      (SELECT org_id FROM public.workflows WHERE id = workflow_id)
    )
  );

-- ============================================================
-- 11. Create new RLS policies for builds
-- ============================================================

CREATE POLICY "builds: org members can read"
  ON public.builds FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "builds: org admins can cancel"
  ON public.builds FOR UPDATE
  USING (public.user_org_write(org_id));

-- ============================================================
-- 12. Create new RLS policies for build_runs
-- ============================================================

CREATE POLICY "build_runs: org members can read"
  ON public.build_runs FOR SELECT
  USING (
    build_id IN (
      SELECT id FROM public.builds
      WHERE org_id = ANY(public.user_org_ids())
    )
  );

-- ============================================================
-- 13. Create new RLS policies for build_logs
-- ============================================================

CREATE POLICY "build_logs: org members can read"
  ON public.build_logs FOR SELECT
  USING (
    build_id IN (
      SELECT id FROM public.builds
      WHERE org_id = ANY(public.user_org_ids())
    )
  );

-- ============================================================
-- 14. Create new RLS policies for environment_variables
-- ============================================================

CREATE POLICY "env_vars: org members can read"
  ON public.environment_variables FOR SELECT
  USING (org_id = ANY(public.user_org_ids()));

CREATE POLICY "env_vars: org admins can create"
  ON public.environment_variables FOR INSERT
  WITH CHECK (public.user_org_write(org_id));

CREATE POLICY "env_vars: org admins can update"
  ON public.environment_variables FOR UPDATE
  USING (public.user_org_write(org_id));

CREATE POLICY "env_vars: org admins can delete"
  ON public.environment_variables FOR DELETE
  USING (public.user_org_write(org_id));

-- ============================================================
-- 15. Drop project_role type if exists
-- ============================================================

DROP TYPE IF EXISTS public.project_role;
