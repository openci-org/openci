-- RLS helper functions using SECURITY DEFINER to avoid N+1 query plans.
-- PostgreSQL caches STABLE function results within a single statement,
-- so these are called once per query, not once per row.
--
-- NOTE: Functions live in public schema (not auth) because Supabase Cloud
-- does not grant CREATE privileges on the auth schema to project owners.

-- Returns the set of org_ids the current user belongs to.
CREATE OR REPLACE FUNCTION public.user_org_ids()
RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(array_agg(org_id), '{}')
  FROM public.org_members
  WHERE user_id = auth.uid();
$$;

-- Returns the role a user has in a specific org. NULL = not a member.
CREATE OR REPLACE FUNCTION public.user_org_role(p_org_id uuid)
RETURNS org_role LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role
  FROM public.org_members
  WHERE org_id = p_org_id AND user_id = auth.uid()
  LIMIT 1;
$$;

-- Returns the set of project_ids accessible by the current user
-- (all projects in orgs they belong to).
CREATE OR REPLACE FUNCTION public.user_project_ids()
RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(array_agg(DISTINCT p.id), '{}')
  FROM public.projects p
  WHERE p.org_id = ANY(public.user_org_ids());
$$;

-- Returns the effective role for a user on a specific project.
-- project_members override takes priority over org-level role.
CREATE OR REPLACE FUNCTION public.user_project_role(p_project_id uuid)
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(
    -- 1. Direct project membership override
    (SELECT role::text FROM public.project_members
     WHERE project_id = p_project_id AND user_id = auth.uid() LIMIT 1),
    -- 2. Fall back to org-level role: owner/admin -> 'write', member -> 'read'
    (SELECT CASE
       WHEN om.role IN ('owner', 'admin') THEN 'write'
       ELSE 'read'
     END
     FROM public.org_members om
     JOIN public.projects p ON p.org_id = om.org_id
     WHERE p.id = p_project_id AND om.user_id = auth.uid()
     LIMIT 1)
  );
$$;
