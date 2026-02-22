-- RLS policy tests using pgTAP
-- Run with: supabase test db

BEGIN;

SELECT plan(20);

-- ============================================================
-- Setup: create test users and data
-- ============================================================

-- User A: owner of org-1
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'user-a@test.com',
  crypt('password', gen_salt('bf')),
  now()
);

-- User B: member of org-1
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'user-b@test.com',
  crypt('password', gen_salt('bf')),
  now()
);

-- User C: not a member of org-1
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
VALUES (
  'cccccccc-0000-0000-0000-000000000001',
  'user-c@test.com',
  crypt('password', gen_salt('bf')),
  now()
);

-- Create org-1 and assign members (bypasses RLS; runs as postgres)
INSERT INTO public.organizations (id, name, slug)
VALUES ('11111111-0000-0000-0000-000000000001', 'Org One', 'org-one');

INSERT INTO public.org_members (org_id, user_id, role)
VALUES
  ('11111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'owner'),
  ('11111111-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'member');

-- Create project-1 in org-1
INSERT INTO public.projects (id, org_id, name, slug)
VALUES ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'Project One', 'project-one');

-- Create a build in project-1
INSERT INTO public.builds (id, project_id, workflow_id, status, github_owner, github_repo)
VALUES ('33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', NULL, 'queued', 'demo-org', 'demo-repo');

-- ============================================================
-- Test 1: User A (owner) can read org-1
-- ============================================================
SET LOCAL role authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "aaaaaaaa-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.organizations WHERE id = '11111111-0000-0000-0000-000000000001'),
  1,
  'User A (owner) can read org-1'
);

-- ============================================================
-- Test 2: User C (non-member) cannot read org-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.organizations WHERE id = '11111111-0000-0000-0000-000000000001'),
  0,
  'User C (non-member) cannot read org-1'
);

-- ============================================================
-- Test 3: User B (member) can read project-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "bbbbbbbb-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.projects WHERE id = '22222222-0000-0000-0000-000000000001'),
  1,
  'User B (member) can read project-1'
);

-- ============================================================
-- Test 4: User C cannot read project-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.projects WHERE id = '22222222-0000-0000-0000-000000000001'),
  0,
  'User C (non-member) cannot read project-1'
);

-- ============================================================
-- Test 5: User A (owner) can read builds in project-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "aaaaaaaa-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.builds WHERE id = '33333333-0000-0000-0000-000000000001'),
  1,
  'User A (owner) can read builds in project-1'
);

-- ============================================================
-- Test 6: User C cannot read builds in project-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.builds WHERE id = '33333333-0000-0000-0000-000000000001'),
  0,
  'User C (non-member) cannot read builds in project-1'
);

-- ============================================================
-- Test 7: User A (owner) can update org-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "aaaaaaaa-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ UPDATE public.organizations SET name = 'Org One Updated' WHERE id = '11111111-0000-0000-0000-000000000001' $$,
  'User A (owner) can update org-1'
);

-- ============================================================
-- Test 8: User B (member) cannot update org-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "bbbbbbbb-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT name FROM public.organizations WHERE id = '11111111-0000-0000-0000-000000000001'),
  'Org One Updated',
  'Verify previous update took effect'
);

-- Member update should affect 0 rows (RLS silently filters)
UPDATE public.organizations SET name = 'Org One Hacked' WHERE id = '11111111-0000-0000-0000-000000000001';

SELECT is(
  (SELECT name FROM public.organizations WHERE id = '11111111-0000-0000-0000-000000000001'),
  'Org One Updated',
  'User B (member) cannot update org-1'
);

-- ============================================================
-- Test 9: User A can read org_members of org-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "aaaaaaaa-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.org_members WHERE org_id = '11111111-0000-0000-0000-000000000001'),
  2,
  'User A can read all org members'
);

-- ============================================================
-- Test 10: User C cannot read org_members of org-1
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int FROM public.org_members WHERE org_id = '11111111-0000-0000-0000-000000000001'),
  0,
  'User C (non-member) cannot read org members'
);

-- ============================================================
-- Test 11: claim_next_build RPC returns the queued build
-- ============================================================
RESET role;
SELECT is(
  (SELECT (claim_next_build('test-worker')).id),
  '33333333-0000-0000-0000-000000000001'::uuid,
  'claim_next_build returns the queued build'
);

-- ============================================================
-- Test 12: claim_next_build returns NULL when no queued builds
-- ============================================================
SELECT is(
  (SELECT (claim_next_build('test-worker')).id),
  NULL,
  'claim_next_build returns NULL when no queued builds remain'
);

-- ============================================================
-- Test 13: Build status is now in_progress after claiming
-- ============================================================
SELECT is(
  (SELECT status FROM public.builds WHERE id = '33333333-0000-0000-0000-000000000001'),
  'in_progress'::build_status,
  'Build status is in_progress after claiming'
);

-- ============================================================
-- Test 14: increment_env_var returns previous value and increments
-- ============================================================
INSERT INTO public.environment_variables (id, project_id, key, value, auto_increment)
VALUES ('44444444-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'BUILD_NUMBER', '41', true);

SELECT is(
  (SELECT increment_env_var('44444444-0000-0000-0000-000000000001')),
  '41',
  'increment_env_var returns the value before incrementing'
);

SELECT is(
  (SELECT value FROM public.environment_variables WHERE id = '44444444-0000-0000-0000-000000000001'),
  '42',
  'increment_env_var increments the stored value'
);

-- ============================================================
-- Test 15: env var constraint: plain value with is_secret=false
-- ============================================================
SELECT lives_ok(
  $$ INSERT INTO public.environment_variables (project_id, key, value, is_secret)
     VALUES ('22222222-0000-0000-0000-000000000001', 'API_URL', 'https://api.example.com', false) $$,
  'Valid plain-text env var can be inserted'
);

-- ============================================================
-- Test 16: env var constraint: secret must have secret_path
-- ============================================================
SELECT throws_ok(
  $$ INSERT INTO public.environment_variables (project_id, key, is_secret, value)
     VALUES ('22222222-0000-0000-0000-000000000001', 'BAD_SECRET', true, 'should-not-have-value') $$,
  'new row for relation "environment_variables" violates check constraint "environment_variables_check"',
  'Secret env var without secret_path and with value violates constraint'
);

-- ============================================================
-- Test 17: worker_config is readable by anyone
-- ============================================================
SET LOCAL role authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT value FROM public.worker_config WHERE key = 'latest_version'),
  '0.0.1',
  'worker_config is readable by anyone (including non-org-members)'
);

-- ============================================================
-- Test 18: create_organization RPC creates org with owner role
-- ============================================================
SET LOCAL "request.jwt.claims" TO '{"sub": "cccccccc-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ SELECT create_organization('User C Org', 'user-c-org') $$,
  'create_organization RPC succeeds'
);

SELECT is(
  (SELECT count(*)::int FROM public.org_members
   WHERE user_id = 'cccccccc-0000-0000-0000-000000000001' AND role = 'owner'),
  1,
  'create_organization sets caller as owner'
);

-- ============================================================
-- Test 19: profile is auto-created on user signup
-- ============================================================
RESET role;
SELECT is(
  (SELECT count(*)::int FROM public.profiles WHERE id IN (
    'aaaaaaaa-0000-0000-0000-000000000001',
    'bbbbbbbb-0000-0000-0000-000000000001',
    'cccccccc-0000-0000-0000-000000000001'
  )),
  3,
  'Profiles are auto-created for all test users'
);

-- ============================================================
-- Test 20: auto org is created on user signup
-- ============================================================
SELECT is(
  (SELECT count(*)::int FROM public.org_members
   WHERE user_id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  2,  -- One from seed setup + one auto-created personal org
  'Auto org is created for user on signup'
);

SELECT * FROM finish();
ROLLBACK;
