-- projects: belong to an organization

CREATE TABLE public.projects (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid        NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  slug        text        NOT NULL,
  description text,
  framework   text,
  platforms   text[]      NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, slug)
);

CREATE INDEX idx_projects_org_id ON public.projects(org_id);

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- project_members: optional per-project role overrides
-- Inherits org-level access by default; this table only adds explicit overrides
CREATE TABLE public.project_members (
  id         uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid         NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id    uuid         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       project_role NOT NULL DEFAULT 'read',
  created_at timestamptz  NOT NULL DEFAULT now(),
  updated_at timestamptz  NOT NULL DEFAULT now(),
  UNIQUE (project_id, user_id)
);

CREATE INDEX idx_project_members_user_id    ON public.project_members(user_id);
CREATE INDEX idx_project_members_project_id ON public.project_members(project_id);

CREATE TRIGGER project_members_updated_at
  BEFORE UPDATE ON public.project_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
