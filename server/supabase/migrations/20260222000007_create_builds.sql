-- builds: replaces Firestore build_jobs_v0
-- Created by webhook handler (service_role); claimed and executed by Mac worker

CREATE TABLE public.builds (
  id                    uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id            uuid         NOT NULL REFERENCES public.projects(id),
  workflow_id           uuid         REFERENCES public.workflows(id),
  status                build_status NOT NULL DEFAULT 'queued',

  -- GitHub context (mirrors build_jobs_v0 fields)
  github_owner          text         NOT NULL,
  github_repo           text         NOT NULL,
  commit_sha            text,
  branch                text,
  tag_name              text,
  pull_request_number   int,
  github_event          text,    -- 'push', 'pull_request', 'create', 'release'
  github_action         text,    -- 'opened', 'synchronize', 'published', etc.
  github_sender         text,    -- login of the user who triggered the event

  -- GitHub App installation context
  installation_id       bigint,
  -- Short-lived token for the worker to clone the repository
  installation_token    text,
  token_expires_at      timestamptz,
  check_run_id          bigint,

  -- Retry tracking
  retried_from_build_id uuid         REFERENCES public.builds(id),
  run_count             int          NOT NULL DEFAULT 0,
  latest_run_id         uuid,        -- Set by trigger when first build_run is created

  created_at            timestamptz  NOT NULL DEFAULT now(),
  updated_at            timestamptz  NOT NULL DEFAULT now()
);

-- Worker polls: status='queued' ORDER BY created_at ASC LIMIT 1
CREATE INDEX idx_builds_queued ON public.builds(created_at ASC)
  WHERE status = 'queued';

-- Dashboard: builds for a project, newest first
CREATE INDEX idx_builds_project_id_created
  ON public.builds(project_id, created_at DESC);

CREATE INDEX idx_builds_workflow_id ON public.builds(workflow_id);

CREATE TRIGGER builds_updated_at
  BEFORE UPDATE ON public.builds
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
