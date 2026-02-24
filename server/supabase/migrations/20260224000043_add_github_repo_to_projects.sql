-- Add GitHub repository link to projects
-- Webhook handler uses these to find the project for incoming events

ALTER TABLE public.projects
  ADD COLUMN github_owner text,
  ADD COLUMN github_repo  text;

CREATE UNIQUE INDEX idx_projects_github_repo
  ON public.projects(github_owner, github_repo)
  WHERE github_owner IS NOT NULL AND github_repo IS NOT NULL;
