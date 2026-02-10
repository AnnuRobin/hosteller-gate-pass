-- ============================================
-- Create Admin User - READY TO RUN
-- ============================================
-- Your database is already set up, just run this to create the admin user
-- ============================================

DO $$
DECLARE
  v_user_id UUID := 'f5b726b0-eaf8-48a9-9760-52c4afcf412a'; -- Your User ID from Supabase Auth
  v_email TEXT := 'admin@sjcetpalai.ac.in'; -- Your admin email
  v_full_name TEXT := 'System Administrator'; -- Admin name
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
    'admin',
    TRUE,
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE 
  SET 
    role = 'admin',
    is_staff = TRUE,
    email_verified = TRUE,
    email_verified_at = NOW();
  
  -- Create staff credentials
  INSERT INTO staff_credentials (user_id, username, role)
  VALUES (v_user_id, 'admin', 'admin')
  ON CONFLICT (user_id) DO UPDATE
  SET username = 'admin', role = 'admin';
  
  RAISE NOTICE '✅ Admin user created successfully!';
  RAISE NOTICE 'Username: admin';
  RAISE NOTICE 'Email: %', v_email;
END $$;

