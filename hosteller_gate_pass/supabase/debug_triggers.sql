-- ──────────────────────────────────────────────────────────────────────────────
-- DIAGNOSTIC: Find auth hooks and triggers
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.debug_check_triggers()
RETURNS TABLE (table_name TEXT, trigger_name TEXT, function_name TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tr.tgrelid::regclass::text as table_name,
    tr.tgname::text as trigger_name,
    p.proname::text as function_name
  FROM pg_trigger tr
  JOIN pg_proc p ON tr.tgfoid = p.oid
  WHERE tr.tgrelid IN ('auth.users'::regclass, 'public.users'::regclass);
END;
$$;
