-- workflows: YAML-defined build workflows belonging to a project

CREATE TABLE public.workflows (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id       uuid        NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  name             text        NOT NULL,
  -- Full YAML text is the source of truth (GitHub Actions style)
  yaml_definition  text        NOT NULL DEFAULT '',
  is_active        boolean     NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_workflows_project_id ON public.workflows(project_id);

CREATE TRIGGER workflows_updated_at
  BEFORE UPDATE ON public.workflows
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- workflow_triggers: parsed from yaml_definition on save
-- One workflow can have multiple trigger configurations
CREATE TABLE public.workflow_triggers (
  id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id    uuid         NOT NULL REFERENCES public.workflows(id) ON DELETE CASCADE,
  trigger_type   trigger_type NOT NULL,
  -- NULL = all branches/tags; pattern matching uses LIKE syntax
  branch_pattern text,
  -- "owner/repo" format from GitHub
  github_repo    text         NOT NULL,
  created_at     timestamptz  NOT NULL DEFAULT now(),
  updated_at     timestamptz  NOT NULL DEFAULT now()
);

-- Critical: webhook handler looks up workflows by repo+type+branch
CREATE INDEX idx_workflow_triggers_lookup
  ON public.workflow_triggers(github_repo, trigger_type);
CREATE INDEX idx_workflow_triggers_workflow_id
  ON public.workflow_triggers(workflow_id);

CREATE TRIGGER workflow_triggers_updated_at
  BEFORE UPDATE ON public.workflow_triggers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
