-- ============================================
-- Database Migration Script
-- Hostel Gate Pass System - Admin, Warden, and Parent Modules
-- ============================================

-- ============================================
-- 1. UPDATE USERS TABLE
-- ============================================

-- Add student-specific fields
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS semester INTEGER,
ADD COLUMN IF NOT EXISTS section TEXT,
ADD COLUMN IF NOT EXISTS home_address TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

-- Note: The role column already exists
-- We'll add 'admin' and 'parent' as new valid role values

-- ============================================
-- 2. CREATE PARENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS parents (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL CHECK (relationship IN ('father', 'mother', 'guardian')),
  is_primary_contact BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_parent_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_parents_student_id ON parents(student_id);
CREATE INDEX IF NOT EXISTS idx_parents_id ON parents(id);

-- Allow multiple parents per student, but ensure unique parent-student pairs
CREATE UNIQUE INDEX IF NOT EXISTS idx_parents_unique_pair ON parents(id, student_id);

-- ============================================
-- 3. CREATE PARENT_OTPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS parent_otps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gate_pass_request_id UUID NOT NULL REFERENCES gate_pass_requests(id) ON DELETE CASCADE,
  parent_phone TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attempts INTEGER DEFAULT 0,
  CONSTRAINT fk_gate_pass_request FOREIGN KEY (gate_pass_request_id) 
    REFERENCES gate_pass_requests(id) ON DELETE CASCADE
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_parent_otps_gate_pass_request ON parent_otps(gate_pass_request_id);
CREATE INDEX IF NOT EXISTS idx_parent_otps_expires_at ON parent_otps(expires_at);

-- ============================================
-- 4. UPDATE GATE_PASS_REQUESTS TABLE
-- ============================================

ALTER TABLE gate_pass_requests
ADD COLUMN IF NOT EXISTS parent_approval_status TEXT DEFAULT 'pending' CHECK (parent_approval_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS parent_approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS parent_remarks TEXT;

-- ============================================
-- 5. CREATE ADMIN_AUDIT_LOG TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON admin_audit_log(created_at);

-- ============================================
-- 6. CREATE SMS_LOGS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS sms_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_otp_id UUID REFERENCES parent_otps(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'failed', 'delivered')),
  provider_response JSONB,
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sms_logs_parent_otp_id ON sms_logs(parent_otp_id);
CREATE INDEX IF NOT EXISTS idx_sms_logs_status ON sms_logs(status);

-- ============================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_otps ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Admins can update users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;

-- Admin can view all users
CREATE POLICY "Admins can view all users"
ON users FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Admin can insert users
CREATE POLICY "Admins can create users"
ON users FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Admin can update users
CREATE POLICY "Admins can update users"
ON users FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Admin can delete users
CREATE POLICY "Admins can delete users"
ON users FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- PARENTS TABLE POLICIES
-- ============================================

-- Parents can view their own student relationships
CREATE POLICY "Parents can view their own student links"
ON parents FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Students can view their parents
CREATE POLICY "Students can view their parents"
ON parents FOR SELECT
TO authenticated
USING (student_id = auth.uid());

-- Admins can manage all parent relationships
CREATE POLICY "Admins can manage parent relationships"
ON parents FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- GATE PASS REQUESTS POLICIES
-- ============================================

DROP POLICY IF EXISTS "Wardens can delete gate pass requests" ON gate_pass_requests;
DROP POLICY IF EXISTS "Parents can view their student's gate pass requests" ON gate_pass_requests;
DROP POLICY IF EXISTS "Parents can update approval status" ON gate_pass_requests;

-- Warden can delete gate pass requests
CREATE POLICY "Wardens can delete gate pass requests"
ON gate_pass_requests FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'warden'
  )
);

-- Parents can view gate pass requests for their students
CREATE POLICY "Parents can view their student's gate pass requests"
ON gate_pass_requests FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM parents
    WHERE parents.id = auth.uid()
    AND parents.student_id = gate_pass_requests.student_id
  )
);

-- Parents can update parent approval status
CREATE POLICY "Parents can update approval status"
ON gate_pass_requests FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM parents
    WHERE parents.id = auth.uid()
    AND parents.student_id = gate_pass_requests.student_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM parents
    WHERE parents.id = auth.uid()
    AND parents.student_id = gate_pass_requests.student_id
  )
);

-- ============================================
-- PARENT OTPS POLICIES
-- ============================================

-- Students can view their own OTPs
CREATE POLICY "Students can view their own gate pass OTPs"
ON parent_otps FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM gate_pass_requests gpr
    WHERE gpr.id = parent_otps.gate_pass_request_id
    AND gpr.student_id = auth.uid()
  )
);

-- Students can insert OTPs for their requests
CREATE POLICY "Students can create OTPs for their requests"
ON parent_otps FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM gate_pass_requests gpr
    WHERE gpr.id = gate_pass_request_id
    AND gpr.student_id = auth.uid()
  )
);

-- Students can update their OTPs (for verification)
CREATE POLICY "Students can update their OTPs"
ON parent_otps FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM gate_pass_requests gpr
    WHERE gpr.id = parent_otps.gate_pass_request_id
    AND gpr.student_id = auth.uid()
  )
);

-- Parents can view OTPs for their students' requests
CREATE POLICY "Parents can view their students OTPs"
ON parent_otps FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM gate_pass_requests gpr
    JOIN parents p ON p.student_id = gpr.student_id
    WHERE gpr.id = parent_otps.gate_pass_request_id
    AND p.id = auth.uid()
  )
);

-- ============================================
-- ADMIN AUDIT LOG POLICIES
-- ============================================

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs"
ON admin_audit_log FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- SMS LOGS POLICIES
-- ============================================

-- Students can view SMS logs for their OTPs
CREATE POLICY "Students can view their SMS logs"
ON sms_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM parent_otps po
    JOIN gate_pass_requests gpr ON gpr.id = po.gate_pass_request_id
    WHERE po.id = sms_logs.parent_otp_id
    AND gpr.student_id = auth.uid()
  )
);

-- Admins can view all SMS logs
CREATE POLICY "Admins can view all SMS logs"
ON sms_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- 8. DATABASE FUNCTIONS
-- ============================================

-- Email Domain Validation Function
CREATE OR REPLACE FUNCTION validate_college_email(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN email ILIKE '%@sjcetpalai.ac.in';
END;
$$ LANGUAGE plpgsql;

-- Trigger Function to Validate Email on User Creation/Update
CREATE OR REPLACE FUNCTION check_email_domain()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user is student, advisor, hod, or warden
  IF NEW.role IN ('student', 'advisor', 'hod', 'warden') THEN
    IF NOT validate_college_email(NEW.email) THEN
      RAISE EXCEPTION 'Students and faculty must use college email domain: sjcetpalai.ac.in';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS validate_user_email_domain ON users;
CREATE TRIGGER validate_user_email_domain
BEFORE INSERT OR UPDATE OF email ON users
FOR EACH ROW
EXECUTE FUNCTION check_email_domain();

-- Generate OTP Function
CREATE OR REPLACE FUNCTION generate_otp()
RETURNS TEXT AS $$
BEGIN
  RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Create OTP for Gate Pass Function
CREATE OR REPLACE FUNCTION create_parent_otp(
  p_gate_pass_request_id UUID,
  p_parent_phone TEXT
)
RETURNS TABLE(otp_code TEXT, expires_at TIMESTAMP WITH TIME ZONE) AS $$
DECLARE
  v_otp TEXT;
  v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Generate 6-digit OTP
  v_otp := generate_otp();
  
  -- Set expiration to 10 minutes from now
  v_expires_at := NOW() + INTERVAL '10 minutes';
  
  -- Insert OTP record
  INSERT INTO parent_otps (gate_pass_request_id, parent_phone, otp_code, expires_at)
  VALUES (p_gate_pass_request_id, p_parent_phone, v_otp, v_expires_at);
  
  RETURN QUERY SELECT v_otp, v_expires_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send SMS Function (Placeholder for Integration)
CREATE OR REPLACE FUNCTION send_sms_otp(
  p_parent_otp_id UUID,
  p_phone_number TEXT,
  p_otp_code TEXT
)
RETURNS UUID AS $$
DECLARE
  v_sms_log_id UUID;
  v_message TEXT;
BEGIN
  -- Create SMS message
  v_message := 'Your gate pass approval OTP is: ' || p_otp_code || '. Valid for 10 minutes.';
  
  -- Log SMS attempt
  INSERT INTO sms_logs (parent_otp_id, phone_number, message, status)
  VALUES (p_parent_otp_id, p_phone_number, v_message, 'pending')
  RETURNING id INTO v_sms_log_id;
  
  -- TODO: Integrate with Twilio/AWS SNS here
  -- For now, just mark as sent
  UPDATE sms_logs
  SET status = 'sent', sent_at = NOW()
  WHERE id = v_sms_log_id;
  
  RETURN v_sms_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify OTP Function
CREATE OR REPLACE FUNCTION verify_parent_otp(
  p_gate_pass_request_id UUID,
  p_otp_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_otp_record RECORD;
BEGIN
  -- Get the OTP record
  SELECT * INTO v_otp_record
  FROM parent_otps
  WHERE gate_pass_request_id = p_gate_pass_request_id
    AND otp_code = p_otp_code
    AND is_verified = FALSE
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- Check if OTP exists and is valid
  IF v_otp_record IS NULL THEN
    -- Increment attempts if record exists
    UPDATE parent_otps
    SET attempts = attempts + 1
    WHERE gate_pass_request_id = p_gate_pass_request_id
      AND otp_code = p_otp_code;
    
    RETURN FALSE;
  END IF;
  
  -- Mark OTP as verified
  UPDATE parent_otps
  SET is_verified = TRUE,
      verified_at = NOW()
  WHERE id = v_otp_record.id;
  
  -- Update gate pass request
  UPDATE gate_pass_requests
  SET parent_approval_status = 'approved',
      parent_approved_at = NOW()
  WHERE id = p_gate_pass_request_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Run this script in your Supabase SQL Editor
-- Make sure to test in a development environment first!
