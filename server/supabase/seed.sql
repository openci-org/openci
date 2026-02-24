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
  'OpenCI Demo',
  'openci-demo',
  'A sample project for testing OpenCI workflows',
  'TypeScript',
  ARRAY['ios']
)
ON CONFLICT (org_id, slug) DO NOTHING;

-- Sample builds for worker testing (uses public repo — no token needed)
-- yaml_definition is embedded directly in each build
INSERT INTO public.builds (id, project_id, status, runner_os, github_owner, github_repo, commit_sha, branch, github_event, github_sender, yaml_definition)
VALUES
  (
    '00000000-0000-0000-0000-000000000100',
    '00000000-0000-0000-0000-000000000010',
    'queued', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'push', 'demo-user',
    $yaml$name: Simple Workflow

on:
  push:
    branches:
      - develop
  pull_request:
    branches:
      - develop

jobs:
  analyze:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Verify Node.js
        run: |
          echo "Node version: $(node --version)"
          echo "npm version: $(npm --version)"

      - name: Hello World
        run: echo "Hello World from OpenCI!"

      - name: Show system info
        run: |
          echo "OS: $(uname -s)"
          echo "Arch: $(uname -m)"
          sw_vers
$yaml$
  ),
  (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000010',
    'queued', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'pull_request', 'demo-user',
    $yaml$name: Simple Workflow

on:
  push:
    branches:
      - develop
  pull_request:
    branches:
      - develop

jobs:
  analyze:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Verify Node.js
        run: |
          echo "Node version: $(node --version)"
          echo "npm version: $(npm --version)"

      - name: Hello World
        run: echo "Hello World from OpenCI!"

      - name: Show system info
        run: |
          echo "OS: $(uname -s)"
          echo "Arch: $(uname -m)"
          sw_vers
$yaml$
  ),
  (
    '00000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000010',
    'in_progress', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'push', 'demo-user',
    NULL
  ),
  (
    '00000000-0000-0000-0000-000000000103',
    '00000000-0000-0000-0000-000000000010',
    'success', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'push', 'demo-user',
    NULL
  ),
  (
    '00000000-0000-0000-0000-000000000104',
    '00000000-0000-0000-0000-000000000010',
    'failure', 'linux',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'pull_request', 'demo-user',
    NULL
  )
ON CONFLICT DO NOTHING;

-- Worker config
INSERT INTO public.worker_config (key, value)
VALUES ('latest_version', '0.0.1')
ON CONFLICT (key) DO NOTHING;
