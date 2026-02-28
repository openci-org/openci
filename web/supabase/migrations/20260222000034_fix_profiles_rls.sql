-- Allow org members to read profiles of other members in their shared orgs.
-- Without this, the org members page cannot display any member names since
-- the profiles LEFT JOIN returns null for everyone except the current user.

DROP POLICY IF EXISTS "profiles: users can read own profile" ON public.profiles;

CREATE POLICY "profiles: org members can read each other"
  ON public.profiles FOR SELECT
  USING (
    -- Own profile
    id = (SELECT auth.uid())
    -- Or a member of any shared org
    OR id IN (
      SELECT user_id FROM public.org_members
      WHERE org_id = ANY(public.user_org_ids())
    )
  );
