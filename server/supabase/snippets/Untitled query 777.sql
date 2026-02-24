INSERT INTO public.builds (
  id, project_id, workflow_id, status,
  github_owner, github_repo, commit_sha, branch, github_event
) VALUES (
  '00000000-0000-0000-0000-000000000030',
  '00000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000020',
  'queued',
  'demo-org', 'ios-demo-app', 'abc1234', 'main', 'push'
);
