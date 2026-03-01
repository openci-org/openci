-- environment_variables: unifies Firestore environment_variables_v0 + secrets_v0
-- Scoped per project (was per team in Firestore)

CREATE TABLE public.environment_variables (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id     uuid        NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  key            text        NOT NULL,
  -- Plain-text value (NULL when is_secret = true)
  value          text,
  -- If true, the actual value is stored in GCP Secret Manager at secret_path
  is_secret      boolean     NOT NULL DEFAULT false,
  -- GCP Secret Manager resource path (e.g. projects/123/secrets/my-cert/versions/latest)
  secret_path    text,
  -- Auto-increment numeric value on each build (build number pattern)
  auto_increment boolean     NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, key),
  -- Constraint: either a plain value or a secret path must be provided
  CHECK (
    (is_secret = false AND value IS NOT NULL AND secret_path IS NULL)
    OR (is_secret = true AND secret_path IS NOT NULL AND value IS NULL)
  )
);

CREATE INDEX idx_env_vars_project_id ON public.environment_variables(project_id);

CREATE TRIGGER env_vars_updated_at
  BEFORE UPDATE ON public.environment_variables
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
