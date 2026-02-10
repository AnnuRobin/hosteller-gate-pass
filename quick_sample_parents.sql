-- ============================================
-- Quick Sample Parent Data (Ready to Run)
-- ============================================
-- This version creates parent users directly without requiring Supabase Auth
-- NOTE: These parents won't be able to login via the app
-- For login capability, create them via Supabase Auth Dashboard first
-- ============================================

DO $$
DECLARE
  v_parent1_id UUID := uuid_generate_v4();
  v_parent2_id UUID := uuid_generate_v4();
  v_parent3_id UUID := uuid_generate_v4();
  v_parent4_id UUID := uuid_generate_v4();
  v_parent5_id UUID := uuid_generate_v4();
  
  v_student1_id UUID;
  v_student2_id UUID;
  v_student3_id UUID;
BEGIN
  -- Get first three students from database
  SELECT id INTO v_student1_id FROM users WHERE role = 'student' ORDER BY created_at LIMIT 1;
  SELECT id INTO v_student2_id FROM users WHERE role = 'student' ORDER BY created_at OFFSET 1 LIMIT 1;
  SELECT id INTO v_student3_id FROM users WHERE role = 'student' ORDER BY created_at OFFSET 2 LIMIT 1;
  
  IF v_student1_id IS NULL THEN
    RAISE EXCEPTION 'No students found in database. Please create students first.';
  END IF;
  
  -- Create Parent 1 (Father of Student 1)
  INSERT INTO users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
  VALUES (
    v_parent1_id,
    'john.doe@gmail.com',
    'John Doe',
    '+91-9876543210',
    'parent',
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (email) DO NOTHING;
  
  -- Create Parent 2 (Mother of Student 1)
  INSERT INTO users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
  VALUES (
    v_parent2_id,
    'jane.doe@gmail.com',
    'Jane Doe',
    '+91-9876543211',
    'parent',
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (email) DO NOTHING;
  
  -- Link Parent 1 to Student 1 (Primary Contact)
  INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
  VALUES (v_parent1_id, v_student1_id, 'father', TRUE, NOW())
  ON CONFLICT (id, student_id) DO NOTHING;
  
  -- Link Parent 2 to Student 1 (Secondary Contact)
  INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
  VALUES (v_parent2_id, v_student1_id, 'mother', FALSE, NOW())
  ON CONFLICT (id, student_id) DO NOTHING;
  
  -- If Student 2 exists, create parents for them
  IF v_student2_id IS NOT NULL THEN
    -- Create Parent 3 (Father of Student 2)
    INSERT INTO users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
    VALUES (
      v_parent3_id,
      'robert.smith@gmail.com',
      'Robert Smith',
      '+91-9876543212',
      'parent',
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO NOTHING;
    
    -- Link Parent 3 to Student 2
    INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
    VALUES (v_parent3_id, v_student2_id, 'father', TRUE, NOW())
    ON CONFLICT (id, student_id) DO NOTHING;
  END IF;
  
  -- If Student 3 exists, create parents for them
  IF v_student3_id IS NOT NULL THEN
    -- Create Parent 4 (Mother of Student 3)
    INSERT INTO users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
    VALUES (
      v_parent4_id,
      'mary.johnson@gmail.com',
      'Mary Johnson',
      '+91-9876543213',
      'parent',
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO NOTHING;
    
    -- Create Parent 5 (Guardian of Student 3)
    INSERT INTO users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
    VALUES (
      v_parent5_id,
      'david.johnson@gmail.com',
      'David Johnson',
      '+91-9876543214',
      'parent',
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO NOTHING;
    
    -- Link Parent 4 to Student 3 (Primary)
    INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
    VALUES (v_parent4_id, v_student3_id, 'mother', TRUE, NOW())
    ON CONFLICT (id, student_id) DO NOTHING;
    
    -- Link Parent 5 to Student 3 (Secondary)
    INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
    VALUES (v_parent5_id, v_student3_id, 'guardian', FALSE, NOW())
    ON CONFLICT (id, student_id) DO NOTHING;
  END IF;
  
  RAISE NOTICE '✅ Sample parent data created successfully!';
  RAISE NOTICE 'Created parents for up to 3 students';
  RAISE NOTICE 'NOTE: These parents cannot login without Supabase Auth records';
END $$;

-- Verify the data
SELECT 
  su.full_name as student,
  pu.full_name as parent,
  pu.email as parent_email,
  pu.phone as parent_phone,
  p.relationship,
  CASE WHEN p.is_primary_contact THEN 'Primary' ELSE 'Secondary' END as contact_type
FROM parents p
JOIN users pu ON pu.id = p.id
JOIN users su ON su.id = p.student_id
ORDER BY su.full_name, p.is_primary_contact DESC;
