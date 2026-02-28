-- Seed data for local development
-- Run after: supabase db reset

-- Test user (triggers profile auto-creation via handle_new_user())
-- Email: test@example.com / Password: password123
INSERT INTO auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at,
  created_at, updated_at, confirmation_token,
  raw_app_meta_data, raw_user_meta_data,
  email_change, email_change_token_new, email_change_token_current,
  email_change_confirm_status,
  phone, phone_change, phone_change_token,
  recovery_token, reauthentication_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000099',
  'authenticated', 'authenticated',
  'test@openci.org',
  crypt('password123', gen_salt('bf')),
  NOW(),
  NOW(), NOW(), '',
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Demo User"}',
  '', '', '',
  0,
  '', '', '',
  '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000099',
  '00000000-0000-0000-0000-000000000099',
  jsonb_build_object('sub', '00000000-0000-0000-0000-000000000099', 'email', 'test@example.com'),
  'email',
  '00000000-0000-0000-0000-000000000099',
  NOW(), NOW(), NOW()
) ON CONFLICT (provider_id, provider) DO NOTHING;

-- Insert test organization (bypasses RLS; seed runs as postgres)
INSERT INTO public.organizations (id, name, slug, billing_enabled)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Demo Organization',
  'demo-org',
  false
)
ON CONFLICT (slug) DO NOTHING;

-- Link test user to demo org as owner
INSERT INTO public.org_members (org_id, user_id, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000099',
  'owner'
) ON CONFLICT DO NOTHING;

-- Sample builds for worker testing (uses public repo — no token needed)
INSERT INTO public.builds (id, org_id, status, runner_os, github_owner, github_repo, commit_sha, branch, github_event, github_sender, yaml_definition)
VALUES
  (
    '00000000-0000-0000-0000-000000000100',
    '00000000-0000-0000-0000-000000000001',
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
    '00000000-0000-0000-0000-000000000001',
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
    '00000000-0000-0000-0000-000000000001',
    'in_progress', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'push', 'demo-user',
    NULL
  ),
  (
    '00000000-0000-0000-0000-000000000103',
    '00000000-0000-0000-0000-000000000001',
    'success', 'macos',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'push', 'demo-user',
    NULL
  ),
  (
    '00000000-0000-0000-0000-000000000104',
    '00000000-0000-0000-0000-000000000001',
    'failure', 'linux',
    'open-ci-io', 'openci',
    '6641e45bf5c90414ed9668f8a4a97e8c6ca03b87', 'develop',
    'pull_request', 'demo-user',
    NULL
  )
ON CONFLICT DO NOTHING;

-- Sample environment variables (non-secret)
INSERT INTO public.environment_variables (id, org_id, key, value, is_secret)
VALUES
  (
    '00000000-0000-0000-0000-000000000300',
    '00000000-0000-0000-0000-000000000001',
    'FLUTTER_VERSION', '3.38.7', false
  ),
  (
    '00000000-0000-0000-0000-000000000301',
    '00000000-0000-0000-0000-000000000001',
    'XCODE_VERSION', '16.2', false
  )
ON CONFLICT DO NOTHING;

-- Worker config
INSERT INTO public.worker_config (key, value)
VALUES ('latest_version', '0.0.1')
ON CONFLICT (key) DO NOTHING;
