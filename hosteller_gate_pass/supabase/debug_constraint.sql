-- ──────────────────────────────────────────────────────────────────────────────
-- DIAGNOSTIC: Check role constraint
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.debug_get_constraint()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_check TEXT;
BEGIN
  SELECT check_clause INTO v_check
  FROM information_schema.check_constraints cc
  JOIN information_schema.constraint_column_usage ccu ON cc.constraint_name = ccu.constraint_name
  WHERE cc.constraint_name = 'staff_credentials_role_check';
  RETURN v_check;
END;
$$;
