-- Add FK from org_members.user_id to profiles.id so PostgREST can
-- resolve the embedded profiles join in getOrgMembers().
-- Without this FK the join silently fails and returns an empty result.

ALTER TABLE public.org_members
  ADD CONSTRAINT org_members_user_id_fkey_profiles
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
