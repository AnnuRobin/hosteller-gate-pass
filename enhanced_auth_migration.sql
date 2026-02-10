-- ============================================
-- Enhanced Authentication Migration Script
-- Adds login support for Warden, HOD, and Admin modules
-- ============================================

-- ============================================
-- 0. FIX ROLE CONSTRAINT (CRITICAL - RUN FIRST!)
-- ============================================

-- Drop existing role constraint if it exists
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Add new constraint with all valid roles including admin, warden, hod
ALTER TABLE users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'advisor', 'hod', 'warden', 'admin', 'parent'));

-- ============================================
-- 1. CREATE STAFF_CREDENTIALS TABLE
-- This table stores login credentials for warden, HOD, and admin
-- ============================================

CREATE TABLE IF NOT EXISTS staff_credentials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('warden', 'hod', 'admin')),
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_staff_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_staff_credentials_user_id ON staff_credentials(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_credentials_username ON staff_credentials(username);
CREATE INDEX IF NOT EXISTS idx_staff_credentials_role ON staff_credentials(role);

-- Ensure one credential record per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_credentials_unique_user ON staff_credentials(user_id);

-- ============================================
-- 2. UPDATE USERS TABLE FOR STAFF ROLES
-- ============================================

-- Add staff-specific fields
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS employee_id TEXT,
ADD COLUMN IF NOT EXISTS designation TEXT,
ADD COLUMN IF NOT EXISTS is_staff BOOLEAN DEFAULT FALSE;

-- Create index for employee_id
CREATE INDEX IF NOT EXISTS idx_users_employee_id ON users(employee_id);

-- ============================================
-- 3. CREATE LOGIN_SESSIONS TABLE
-- Track active login sessions for security
-- ============================================

CREATE TABLE IF NOT EXISTS login_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  session_token TEXT UNIQUE NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_login_sessions_user_id ON login_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_login_sessions_token ON login_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_login_sessions_expires_at ON login_sessions(expires_at);

-- ============================================
-- 4. ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE staff_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_sessions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STAFF_CREDENTIALS POLICIES
-- ============================================

-- Staff can view their own credentials
CREATE POLICY "Staff can view own credentials"
ON staff_credentials FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admins can view all staff credentials
CREATE POLICY "Admins can view all staff credentials"
ON staff_credentials FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Admins can manage staff credentials
CREATE POLICY "Admins can manage staff credentials"
ON staff_credentials FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- LOGIN_SESSIONS POLICIES
-- ============================================

-- Users can view their own sessions
CREATE POLICY "Users can view own sessions"
ON login_sessions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admins can view all sessions
CREATE POLICY "Admins can view all sessions"
ON login_sessions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- 5. DATABASE FUNCTIONS FOR AUTHENTICATION
-- ============================================

-- Function to create staff user with credentials
CREATE OR REPLACE FUNCTION create_staff_user(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role TEXT,
  p_username TEXT,
  p_phone TEXT DEFAULT NULL,
  p_department_id UUID DEFAULT NULL,
  p_employee_id TEXT DEFAULT NULL,
  p_designation TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
  v_auth_user_id UUID;
BEGIN
  -- Validate role
  IF p_role NOT IN ('warden', 'hod', 'admin') THEN
    RAISE EXCEPTION 'Invalid staff role. Must be warden, hod, or admin';
  END IF;

  -- Create auth user (this would be done via Supabase Auth API in practice)
  -- For now, we'll create the user record directly
  v_user_id := uuid_generate_v4();

  -- Insert into users table
  INSERT INTO users (
    id, email, full_name, phone, role, 
    department_id, employee_id, designation, 
    is_staff, email_verified, email_verified_at
  ) VALUES (
    v_user_id, p_email, p_full_name, p_phone, p_role,
    p_department_id, p_employee_id, p_designation,
    TRUE, TRUE, NOW()
  );

  -- Create staff credentials
  INSERT INTO staff_credentials (user_id, username, role)
  VALUES (v_user_id, p_username, p_role);

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify staff login
CREATE OR REPLACE FUNCTION verify_staff_login(
  p_username TEXT,
  p_role TEXT
)
RETURNS TABLE(
  user_id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  is_active BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    sc.is_active
  FROM staff_credentials sc
  JOIN users u ON u.id = sc.user_id
  WHERE sc.username = p_username
    AND sc.role = p_role
    AND sc.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create login session
CREATE OR REPLACE FUNCTION create_login_session(
  p_user_id UUID,
  p_role TEXT,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE(
  session_id UUID,
  session_token TEXT,
  expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  v_session_id UUID;
  v_session_token TEXT;
  v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Generate session token
  v_session_token := encode(gen_random_bytes(32), 'hex');
  
  -- Set expiration to 24 hours from now
  v_expires_at := NOW() + INTERVAL '24 hours';
  
  -- Insert session record
  INSERT INTO login_sessions (user_id, role, session_token, ip_address, user_agent, expires_at)
  VALUES (p_user_id, p_role, v_session_token, p_ip_address, p_user_agent, v_expires_at)
  RETURNING id INTO v_session_id;
  
  -- Update last login time
  UPDATE staff_credentials
  SET last_login = NOW()
  WHERE user_id = p_user_id;
  
  RETURN QUERY SELECT v_session_id, v_session_token, v_expires_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate session token
CREATE OR REPLACE FUNCTION validate_session_token(
  p_session_token TEXT
)
RETURNS TABLE(
  user_id UUID,
  role TEXT,
  is_valid BOOLEAN
) AS $$
BEGIN
  -- Update last activity
  UPDATE login_sessions
  SET last_activity = NOW()
  WHERE session_token = p_session_token
    AND expires_at > NOW();
  
  RETURN QUERY
  SELECT 
    ls.user_id,
    ls.role,
    (ls.expires_at > NOW()) as is_valid
  FROM login_sessions ls
  WHERE ls.session_token = p_session_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to logout (invalidate session)
CREATE OR REPLACE FUNCTION logout_session(
  p_session_token TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM login_sessions
  WHERE session_token = p_session_token;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM login_sessions
  WHERE expires_at < NOW();
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. TRIGGERS
-- ============================================

-- Trigger to update staff_credentials updated_at
CREATE OR REPLACE FUNCTION update_staff_credentials_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_staff_credentials_timestamp ON staff_credentials;
CREATE TRIGGER update_staff_credentials_timestamp
BEFORE UPDATE ON staff_credentials
FOR EACH ROW
EXECUTE FUNCTION update_staff_credentials_timestamp();

-- ============================================
-- 7. SAMPLE DATA INSERTION (OPTIONAL)
-- ============================================

-- Create sample admin user (CHANGE PASSWORD IN PRODUCTION!)
-- Note: In production, you should create this via Supabase Auth API
-- This is just for demonstration

-- Example: Create an admin user
-- You'll need to run this after creating the auth user via Supabase
/*
DO $$
DECLARE
  v_admin_user_id UUID;
BEGIN
  -- First create the user via Supabase Auth, then get their ID
  -- For example: v_admin_user_id := 'your-auth-user-id-here';
  
  -- Insert into users table if not exists
  INSERT INTO users (id, email, full_name, role, is_staff, email_verified, email_verified_at)
  VALUES (
    v_admin_user_id,
    'admin@sjcetpalai.ac.in',
    'System Administrator',
    'admin',
    TRUE,
    TRUE,
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Create staff credentials
  INSERT INTO staff_credentials (user_id, username, role)
  VALUES (v_admin_user_id, 'admin', 'admin')
  ON CONFLICT (user_id) DO NOTHING;
END $$;
*/

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Next Steps:
-- 1. Run the base database_migration.sql first (if not already done)
-- 2. Run this enhanced_auth_migration.sql
-- 3. Create initial admin/warden/HOD users via Supabase Auth
-- 4. Link them to staff_credentials table
-- 5. Update your Flutter app to use the new authentication flow
