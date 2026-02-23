-- integrations: third-party app connections (GitHub App installations)
-- Replaces teams_v0.installationIds array; scoped per org

CREATE TABLE public.integrations (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid        NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  -- 'github' for now; extensible to 'gitlab', 'bitbucket' later
  provider        text        NOT NULL DEFAULT 'github',
  -- GitHub App installation ID
  installation_id bigint      NOT NULL,
  -- The GitHub account/org that installed the app
  github_account  text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, provider, installation_id)
);

CREATE INDEX idx_integrations_org_id ON public.integrations(org_id);

CREATE TRIGGER integrations_updated_at
  BEFORE UPDATE ON public.integrations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
