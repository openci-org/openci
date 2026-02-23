-- Seed data for local development
-- Run after: supabase db reset

-- Note: auth.users rows are created via Supabase Auth (not seeded directly in production).
-- For local testing, use the Supabase Studio Auth UI or supabase/tests/auth.sql.

-- Insert test organization (bypasses RLS; seed runs as postgres)
INSERT INTO public.organizations (id, name, slug, billing_enabled)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Demo Organization',
  'demo-org',
  false
)
ON CONFLICT (slug) DO NOTHING;

-- Insert test project
INSERT INTO public.projects (id, org_id, name, slug, description, framework, platforms)
VALUES (
  '00000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000001',
  'iOS Demo App',
  'ios-demo-app',
  'A sample iOS project for testing OpenCI workflows',
  'Swift',
  ARRAY['ios']
)
ON CONFLICT (org_id, slug) DO NOTHING;

-- Insert test workflow with GitHub Actions-style YAML
INSERT INTO public.workflows (id, project_id, name, yaml_definition, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000020',
  '00000000-0000-0000-0000-000000000010',
  'iOS Build & Deploy',
  $yaml$
name: iOS Build & Deploy
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    steps:
      - name: Install dependencies
        run: bundle install

      - name: Build and archive
        run: fastlane build

      - name: Upload to TestFlight
        run: fastlane beta
$yaml$,
  true
)
ON CONFLICT DO NOTHING;

-- Insert matching workflow trigger
INSERT INTO public.workflow_triggers (workflow_id, trigger_type, branch_pattern, github_repo)
VALUES
  ('00000000-0000-0000-0000-000000000020', 'push',         'main', 'demo-org/ios-demo-app'),
  ('00000000-0000-0000-0000-000000000020', 'pull_request',  'main', 'demo-org/ios-demo-app')
ON CONFLICT DO NOTHING;

-- Worker config
INSERT INTO public.worker_config (key, value)
VALUES ('latest_version', '0.0.1')
ON CONFLICT (key) DO NOTHING;
