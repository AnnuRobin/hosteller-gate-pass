-- ──────────────────────────────────────────────────────────────────────────────
-- HOD_CREATE_FACULTY (Refined Version 16 - THE EXACT CLONE)
-- ──────────────────────────────────────────────────────────────────────────────
-- Matches the working 'admin_create_user' logic exactly while adding 
-- HOD-level department security.
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.hod_create_faculty(
  p_email         TEXT,
  p_password      TEXT,
  p_full_name     TEXT,
  p_phone         TEXT    DEFAULT NULL,
  p_department_id UUID    DEFAULT NULL,
  p_class_id      UUID    DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_user_id UUID;
  v_caller_id   UUID;
  v_caller_role TEXT;
  v_caller_dept UUID;
  v_result      JSON;
BEGIN
  -- 1. Security Check (HOD Only, same department)
  v_caller_id := auth.uid();
  SELECT role, department_id INTO v_caller_role, v_caller_dept 
  FROM public.users WHERE id = v_caller_id;

  IF v_caller_role NOT IN ('hod', 'admin') THEN 
    RAISE EXCEPTION 'Unauthorized: Only HODs or Admins can create faculty'; 
  END IF;

  -- Force department if caller is HOD
  IF v_caller_role = 'hod' THEN 
    p_department_id := v_caller_dept; 
  END IF;

  -- 2. Generate ID exactly like working function
  v_new_user_id := uuid_generate_v4();

  -- 3. INSERT into auth.users (EXACT clone of working Admin columns/values)
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, recovery_sent_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_new_user_id, 'authenticated', 'authenticated',
    lower(trim(p_email)), crypt(p_password, gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', p_full_name),
    NOW(), NOW(), '', '', '', ''
  );

  -- 4. INSERT into public.users (EXACT clone of working Admin columns/values)
  -- Note: We set is_staff to TRUE and role to 'advisor'
  INSERT INTO public.users (
    id, email, full_name, phone, role,
    department_id, class_id, 
    email_verified, email_verified_at, created_at, is_staff
  ) VALUES (
    v_new_user_id, lower(trim(p_email)), p_full_name, p_phone, 'advisor',
    p_department_id, p_class_id,
    TRUE, NOW(), NOW(), TRUE
  );

  -- 5. Audit Log (Mirroring working Admin behavior)
  INSERT INTO admin_audit_log (admin_id, action, target_user_id, details)
  VALUES (
    v_caller_id, 'hod_create_faculty', v_new_user_id,
    jsonb_build_object('email', p_email, 'role', 'advisor', 'full_name', p_full_name)
  );

  v_result := json_build_object('success', true, 'user_id', v_new_user_id, 'email', p_email);
  RETURN v_result;

EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'User with email % already exists', p_email;
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error creating faculty: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hod_create_faculty TO authenticated;
