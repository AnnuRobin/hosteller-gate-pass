-- ============================================
-- Create HOD User
-- ============================================

DO $$
DECLARE
  v_user_id UUID := 'PASTE_HOD_USER_ID_HERE'; -- Replace with User ID from Supabase Dashboard
  v_email TEXT := 'hod@sjcetpalai.ac.in'; -- Replace with actual email
  v_full_name TEXT := 'HOD Name'; -- Replace with actual name
  v_username TEXT := 'hod01'; -- Replace with desired username
BEGIN
  -- Insert into users table
  INSERT INTO users (
    id, 
    email, 
    full_name, 
    role, 
    is_staff, 
    email_verified, 
    email_verified_at,
    created_at
  ) VALUES (
    v_user_id,
    v_email,
    v_full_name,
    'hod',
    TRUE,
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE 
  SET 
    role = 'hod',
    is_staff = TRUE,
    email_verified = TRUE,
    email_verified_at = NOW();
  
  -- Create staff credentials
  INSERT INTO staff_credentials (user_id, username, role)
  VALUES (v_user_id, v_username, 'hod')
  ON CONFLICT (user_id) DO UPDATE
  SET username = v_username, role = 'hod';
  
  RAISE NOTICE 'HOD user created successfully!';
END $$;
