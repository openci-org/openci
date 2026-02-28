-- Remove workflows and workflow_triggers tables.
-- Workflow definitions live in .openci/*.yaml files in GitHub repositories.
-- Each build already stores yaml_definition inline.

-- 1. Drop RLS policies
DROP POLICY IF EXISTS "workflows: org members can read" ON public.workflows;
DROP POLICY IF EXISTS "workflows: org admins can create" ON public.workflows;
DROP POLICY IF EXISTS "workflows: org admins can update" ON public.workflows;
DROP POLICY IF EXISTS "workflows: org admins can delete" ON public.workflows;

DROP POLICY IF EXISTS "workflow_triggers: org members can read" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: org admins can create" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: org admins can update" ON public.workflow_triggers;
DROP POLICY IF EXISTS "workflow_triggers: org admins can delete" ON public.workflow_triggers;

-- 2. Drop tables (workflow_triggers first due to FK dependency)
DROP TABLE IF EXISTS public.workflow_triggers CASCADE;
DROP TABLE IF EXISTS public.workflows CASCADE;

-- 3. Drop the trigger_type enum if no longer used elsewhere
DROP TYPE IF EXISTS public.trigger_type;

-- 4. Drop the org write helper only if it was created solely for workflows
-- (keep it — it's shared with env_vars and builds)
