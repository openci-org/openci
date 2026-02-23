-- Migrate environment_variables secrets from GCP Secret Manager to Supabase Vault.
-- Replaces secret_path (GCP resource path) with vault_secret_id (vault.secrets.id).

-- Drop the existing CHECK constraint that references secret_path
ALTER TABLE public.environment_variables
  DROP CONSTRAINT IF EXISTS environment_variables_check;

-- Swap columns: remove GCP path, add Vault reference
ALTER TABLE public.environment_variables
  DROP COLUMN IF EXISTS secret_path,
  ADD COLUMN IF NOT EXISTS vault_secret_id uuid;

-- Re-add the CHECK constraint using vault_secret_id
ALTER TABLE public.environment_variables
  ADD CONSTRAINT environment_variables_secret_check CHECK (
    (is_secret = false AND value IS NOT NULL AND vault_secret_id IS NULL)
    OR (is_secret = true  AND vault_secret_id IS NOT NULL AND value IS NULL)
  );

-- -----------------------------------------------------------------------
-- get_env_var_secret: SECURITY DEFINER wrapper so worker_role can read
-- decrypted secrets without direct access to vault.decrypted_secrets.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_env_var_secret(p_env_var_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_vault_id uuid;
  v_secret   text;
BEGIN
  SELECT vault_secret_id
  INTO   v_vault_id
  FROM   public.environment_variables
  WHERE  id = p_env_var_id
    AND  is_secret = true;

  IF NOT FOUND OR v_vault_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT decrypted_secret
  INTO   v_secret
  FROM   vault.decrypted_secrets
  WHERE  id = v_vault_id;

  RETURN v_secret;
END;
$$;

-- Only worker_role may call this function.
-- Dashboard server uses service_role and can query vault.decrypted_secrets directly.
REVOKE EXECUTE ON FUNCTION public.get_env_var_secret(uuid) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.get_env_var_secret(uuid) TO worker_role;

-- -----------------------------------------------------------------------
-- Dashboard helper RPCs (called server-side with service_role key).
-- The Next.js API routes use these instead of constructing raw SQL.
-- -----------------------------------------------------------------------

-- create_vault_secret: create a secret in Vault, return its uuid.
CREATE OR REPLACE FUNCTION public.create_vault_secret(
  p_secret text,
  p_name   text DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_id uuid;
BEGIN
  SELECT vault.create_secret(p_secret, p_name) INTO v_id;
  RETURN v_id;
END;
$$;

-- update_vault_secret: replace the value of an existing vault secret.
CREATE OR REPLACE FUNCTION public.update_vault_secret(
  p_vault_secret_id uuid,
  p_new_secret      text
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  PERFORM vault.update_secret(p_vault_secret_id, p_new_secret);
END;
$$;

-- delete_vault_secret: remove a secret from Vault by id.
CREATE OR REPLACE FUNCTION public.delete_vault_secret(
  p_vault_secret_id uuid
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  DELETE FROM vault.secrets WHERE id = p_vault_secret_id;
END;
$$;

-- Only service_role (dashboard server) may call the vault helper functions.
REVOKE EXECUTE ON FUNCTION public.create_vault_secret(text, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_vault_secret(uuid, text)  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_vault_secret(uuid)        FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.create_vault_secret(text, text)  TO service_role;
GRANT  EXECUTE ON FUNCTION public.update_vault_secret(uuid, text)  TO service_role;
GRANT  EXECUTE ON FUNCTION public.delete_vault_secret(uuid)        TO service_role;
