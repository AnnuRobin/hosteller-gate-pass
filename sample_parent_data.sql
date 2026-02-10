-- ============================================
-- Sample Data for Parents Table
-- ============================================
-- This script creates sample parent users and links them to students
-- 
-- INSTRUCTIONS:
-- 1. First, you need to create parent users via Supabase Auth Dashboard
--    OR use the admin API to create them programmatically
-- 2. Then run this script to link them to students in the parents table
-- 
-- For this example, we'll assume you have some student IDs
-- Replace the UUIDs with actual student IDs from your database
-- ============================================

-- ============================================
-- STEP 1: Create Parent Users in Auth & Users Table
-- ============================================
-- You need to create these users first via Supabase Dashboard:
-- 1. Go to Authentication → Users → Add User
-- 2. Create users with emails like: parent1@gmail.com, parent2@gmail.com, etc.
-- 3. Copy their User IDs and use them below

-- Example: After creating parent users in Supabase Auth, insert them into users table
-- Replace these UUIDs with actual parent user IDs from Supabase Auth

DO $$
DECLARE
  -- Parent 1 (Father of Student 1)
  v_parent1_id UUID := 'REPLACE_WITH_PARENT1_AUTH_ID'; -- Replace with actual auth user ID
  v_parent1_email TEXT := 'john.doe@gmail.com';
  v_parent1_name TEXT := 'John Doe';
  v_parent1_phone TEXT := '+91-9876543210';
  
  -- Parent 2 (Mother of Student 1)
  v_parent2_id UUID := 'REPLACE_WITH_PARENT2_AUTH_ID'; -- Replace with actual auth user ID
  v_parent2_email TEXT := 'jane.doe@gmail.com';
  v_parent2_name TEXT := 'Jane Doe';
  v_parent2_phone TEXT := '+91-9876543211';
  
  -- Parent 3 (Father of Student 2)
  v_parent3_id UUID := 'REPLACE_WITH_PARENT3_AUTH_ID'; -- Replace with actual auth user ID
  v_parent3_email TEXT := 'robert.smith@gmail.com';
  v_parent3_name TEXT := 'Robert Smith';
  v_parent3_phone TEXT := '+91-9876543212';
  
  -- Student IDs (get these from your users table where role = 'student')
  v_student1_id UUID; -- Will be fetched from database
  v_student2_id UUID; -- Will be fetched from database
BEGIN
  -- Get first two student IDs from database
  SELECT id INTO v_student1_id FROM users WHERE role = 'student' LIMIT 1;
  SELECT id INTO v_student2_id FROM users WHERE role = 'student' OFFSET 1 LIMIT 1;
  
  IF v_student1_id IS NULL OR v_student2_id IS NULL THEN
    RAISE EXCEPTION 'Not enough students found in database. Please create students first.';
  END IF;
  
  -- Insert Parent 1 into users table
  INSERT INTO users (
    id, email, full_name, phone, role, 
    email_verified, email_verified_at, created_at
  ) VALUES (
    v_parent1_id, v_parent1_email, v_parent1_name, v_parent1_phone, 'parent',
    TRUE, NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE 
  SET role = 'parent', email_verified = TRUE;
  
  -- Insert Parent 2 into users table
  INSERT INTO users (
    id, email, full_name, phone, role,
    email_verified, email_verified_at, created_at
  ) VALUES (
    v_parent2_id, v_parent2_email, v_parent2_name, v_parent2_phone, 'parent',
    TRUE, NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE 
  SET role = 'parent', email_verified = TRUE;
  
  -- Insert Parent 3 into users table
  INSERT INTO users (
    id, email, full_name, phone, role,
    email_verified, email_verified_at, created_at
  ) VALUES (
    v_parent3_id, v_parent3_email, v_parent3_name, v_parent3_phone, 'parent',
    TRUE, NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE 
  SET role = 'parent', email_verified = TRUE;
  
  -- Link Parent 1 (Father) to Student 1
  INSERT INTO parents (id, student_id, relationship, is_primary_contact)
  VALUES (v_parent1_id, v_student1_id, 'father', TRUE)
  ON CONFLICT (id, student_id) DO NOTHING;
  
  -- Link Parent 2 (Mother) to Student 1
  INSERT INTO parents (id, student_id, relationship, is_primary_contact)
  VALUES (v_parent2_id, v_student1_id, 'mother', FALSE)
  ON CONFLICT (id, student_id) DO NOTHING;
  
  -- Link Parent 3 (Father) to Student 2
  INSERT INTO parents (id, student_id, relationship, is_primary_contact)
  VALUES (v_parent3_id, v_student2_id, 'father', TRUE)
  ON CONFLICT (id, student_id) DO NOTHING;
  
  RAISE NOTICE 'Sample parent data created successfully!';
  RAISE NOTICE 'Parent 1 (%) linked to Student 1', v_parent1_name;
  RAISE NOTICE 'Parent 2 (%) linked to Student 1', v_parent2_name;
  RAISE NOTICE 'Parent 3 (%) linked to Student 2', v_parent3_name;
END $$;


-- ============================================
-- ALTERNATIVE: Simpler Version Without Auth Users
-- ============================================
-- If you just want to test the parents table structure without creating auth users,
-- you can use this simpler version that creates dummy parent records
-- NOTE: These won't be able to login since they don't have auth records

/*
DO $$
DECLARE
  v_student1_id UUID;
  v_student2_id UUID;
BEGIN
  -- Get first two students
  SELECT id INTO v_student1_id FROM users WHERE role = 'student' LIMIT 1;
  SELECT id INTO v_student2_id FROM users WHERE role = 'student' OFFSET 1 LIMIT 1;
  
  IF v_student1_id IS NULL OR v_student2_id IS NULL THEN
    RAISE EXCEPTION 'Not enough students found. Create students first.';
  END IF;
  
  -- Create dummy parent users (won't be able to login)
  INSERT INTO users (id, email, full_name, phone, role, created_at)
  VALUES 
    (uuid_generate_v4(), 'father1@gmail.com', 'John Doe', '+91-9876543210', 'parent', NOW()),
    (uuid_generate_v4(), 'mother1@gmail.com', 'Jane Doe', '+91-9876543211', 'parent', NOW()),
    (uuid_generate_v4(), 'father2@gmail.com', 'Robert Smith', '+91-9876543212', 'parent', NOW())
  ON CONFLICT DO NOTHING
  RETURNING id;
  
  -- Link to students (you'll need to adjust the IDs)
  -- This is just a placeholder - you'd need to capture the returned IDs above
  
  RAISE NOTICE 'Dummy parent users created (cannot login without auth records)';
END $$;
*/


-- ============================================
-- STEP 2: Verify Parent Data
-- ============================================

-- Check all parents and their linked students
SELECT 
  p.id as parent_id,
  pu.full_name as parent_name,
  pu.email as parent_email,
  pu.phone as parent_phone,
  p.relationship,
  p.is_primary_contact,
  su.full_name as student_name,
  su.email as student_email
FROM parents p
JOIN users pu ON pu.id = p.id
JOIN users su ON su.id = p.student_id
ORDER BY su.full_name, p.is_primary_contact DESC, p.relationship;

-- Count parents per student
SELECT 
  u.full_name as student_name,
  COUNT(p.id) as parent_count
FROM users u
LEFT JOIN parents p ON p.student_id = u.id
WHERE u.role = 'student'
GROUP BY u.id, u.full_name
ORDER BY u.full_name;
