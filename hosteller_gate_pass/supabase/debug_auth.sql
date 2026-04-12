-- ──────────────────────────────────────────────────────────────────────────────
-- DIAGNOSTIC: Check auth.users schema and a sample hash
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.debug_auth_schema()
RETURNS TABLE (column_name TEXT, data_type TEXT)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT column_name::text, data_type::text
  FROM information_schema.columns
  WHERE table_schema = 'auth' AND table_name = 'users';
$$;

CREATE OR REPLACE FUNCTION public.debug_sample_hash(p_pass TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN extensions.crypt(p_pass, extensions.gen_salt('bf'::text));
END;
$$;
