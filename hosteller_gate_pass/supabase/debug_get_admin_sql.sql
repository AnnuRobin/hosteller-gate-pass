-- ──────────────────────────────────────────────────────────────────────────────
-- DIAGNOSTIC: Get existing admin_create_user SQL
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.debug_get_admin_sql()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_source TEXT;
BEGIN
  SELECT prosrc INTO v_source
  FROM pg_proc 
  WHERE proname = 'admin_create_user';
  RETURN v_source;
END;
$$;
