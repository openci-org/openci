-- Fix security issues:
-- 1. Add (SELECT auth.uid()) wrappers in RLS helper functions (initplan optimization)
--    Migration ...033 fixed the policies but not the underlying helper functions.
-- 2. Restrict org_members UPDATE to owners only (removes role self-escalation vector)

-- ============================================================
-- Fix 1: RLS helper functions — add (SELECT auth.uid()) wrappers
-- ============================================================

CREATE OR REPLACE FUNCTION public.user_org_ids()
RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(array_agg(org_id), '{}')
  FROM public.org_members
  WHERE user_id = (SELECT auth.uid());
$$;

CREATE OR REPLACE FUNCTION public.user_org_role(p_org_id uuid)
RETURNS org_role LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role
  FROM public.org_members
  WHERE org_id = p_org_id AND user_id = (SELECT auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.user_project_role(p_project_id uuid)
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(
    -- 1. Direct project membership override
    (SELECT role::text FROM public.project_members
     WHERE project_id = p_project_id AND user_id = (SELECT auth.uid()) LIMIT 1),
    -- 2. Fall back to org-level role: owner/admin -> 'write', member -> 'read'
    (SELECT CASE
       WHEN om.role IN ('owner', 'admin') THEN 'write'
       ELSE 'read'
     END
     FROM public.org_members om
     JOIN public.projects p ON p.org_id = om.org_id
     WHERE p.id = p_project_id AND om.user_id = (SELECT auth.uid())
     LIMIT 1)
  );
$$;

-- ============================================================
-- Fix 2: org_members UPDATE policy — restrict to owners only
-- The previous policy allowed "OR user_id = auth.uid()" which let any member
-- UPDATE their own row via a direct Supabase client call, potentially changing
-- their own role. Self-removal from an org is a DELETE operation (already
-- handled by the admins-can-remove-members DELETE policy with self-remove clause).
-- ============================================================

DROP POLICY IF EXISTS "org_members: owners can update roles" ON public.org_members;

CREATE POLICY "org_members: owners can update roles"
  ON public.org_members FOR UPDATE
  USING (public.user_org_role(org_id) = 'owner');
