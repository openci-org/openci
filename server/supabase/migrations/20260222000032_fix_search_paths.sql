-- Fix mutable search_path warning for set_updated_at trigger function.
-- The function was created without SET search_path in the initial migration.

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
