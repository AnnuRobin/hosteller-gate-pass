-- ============================================
-- Create Parent Users with Login Capability
-- ============================================
-- This script creates parent users in Supabase Auth AND links them to students
-- These parents will be able to login to the app
-- 
-- INSTRUCTIONS:
-- 1. Run this script in Supabase SQL Editor
-- 2. The script will create auth users and link them to students
-- 3. Default password for all parents: "Parent@123"
-- 4. Parents can login using their email and password
-- ============================================

DO $$
DECLARE
  v_student1_id UUID;
  v_student2_id UUID;
  v_student3_id UUID;
  
  v_parent1_id UUID;
  v_parent2_id UUID;
  v_parent3_id UUID;
  v_parent4_id UUID;
  v_parent5_id UUID;
BEGIN
  -- Get first three students from database
  SELECT id INTO v_student1_id FROM users WHERE role = 'student' ORDER BY created_at LIMIT 1;
  SELECT id INTO v_student2_id FROM users WHERE role = 'student' ORDER BY created_at OFFSET 1 LIMIT 1;
  SELECT id INTO v_student3_id FROM users WHERE role = 'student' ORDER BY created_at OFFSET 2 LIMIT 1;
  
  IF v_student1_id IS NULL THEN
    RAISE EXCEPTION 'No students found in database. Please create students first.';
  END IF;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Creating Parent Users with Login Access';
  RAISE NOTICE '========================================';
  
  -- ============================================
  -- Parent 1: John Doe (Father of Student 1)
  -- ============================================
  BEGIN
    -- Create auth user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      recovery_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      uuid_generate_v4(),
      'authenticated',
      'authenticated',
      'john.doe@gmail.com',
      crypt('Parent@123', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"John Doe"}',
      NOW(),
      NOW(),
      '',
      '',
      '',
      ''
    )
    RETURNING id INTO v_parent1_id;
    
    -- Create user profile
    INSERT INTO public.users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
    VALUES (
      v_parent1_id,
      'john.doe@gmail.com',
      'John Doe',
      '+91-9876543210',
      'parent',
      TRUE,
      NOW(),
      NOW()
    );
    
    -- Link to student
    INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
    VALUES (v_parent1_id, v_student1_id, 'father', TRUE, NOW());
    
    RAISE NOTICE '✅ Created: John Doe (john.doe@gmail.com) - Father of Student 1';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE '⚠️  john.doe@gmail.com already exists, skipping...';
  END;
  
  -- ============================================
  -- Parent 2: Jane Doe (Mother of Student 1)
  -- ============================================
  BEGIN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, recovery_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', uuid_generate_v4(),
      'authenticated', 'authenticated', 'jane.doe@gmail.com',
      crypt('Parent@123', gen_salt('bf')), NOW(), NOW(), NOW(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Jane Doe"}',
      NOW(), NOW(), '', '', '', ''
    )
    RETURNING id INTO v_parent2_id;
    
    INSERT INTO public.users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
    VALUES (v_parent2_id, 'jane.doe@gmail.com', 'Jane Doe', '+91-9876543211', 'parent', TRUE, NOW(), NOW());
    
    INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
    VALUES (v_parent2_id, v_student1_id, 'mother', FALSE, NOW());
    
    RAISE NOTICE '✅ Created: Jane Doe (jane.doe@gmail.com) - Mother of Student 1';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE '⚠️  jane.doe@gmail.com already exists, skipping...';
  END;
  
  -- ============================================
  -- Parent 3: Robert Smith (Father of Student 2)
  -- ============================================
  IF v_student2_id IS NOT NULL THEN
    BEGIN
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, recovery_sent_at, last_sign_in_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, email_change, email_change_token_new, recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000', uuid_generate_v4(),
        'authenticated', 'authenticated', 'robert.smith@gmail.com',
        crypt('Parent@123', gen_salt('bf')), NOW(), NOW(), NOW(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Robert Smith"}',
        NOW(), NOW(), '', '', '', ''
      )
      RETURNING id INTO v_parent3_id;
      
      INSERT INTO public.users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
      VALUES (v_parent3_id, 'robert.smith@gmail.com', 'Robert Smith', '+91-9876543212', 'parent', TRUE, NOW(), NOW());
      
      INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
      VALUES (v_parent3_id, v_student2_id, 'father', TRUE, NOW());
      
      RAISE NOTICE '✅ Created: Robert Smith (robert.smith@gmail.com) - Father of Student 2';
    EXCEPTION
      WHEN unique_violation THEN
        RAISE NOTICE '⚠️  robert.smith@gmail.com already exists, skipping...';
    END;
  END IF;
  
  -- ============================================
  -- Parent 4: Mary Johnson (Mother of Student 3)
  -- ============================================
  IF v_student3_id IS NOT NULL THEN
    BEGIN
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, recovery_sent_at, last_sign_in_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, email_change, email_change_token_new, recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000', uuid_generate_v4(),
        'authenticated', 'authenticated', 'mary.johnson@gmail.com',
        crypt('Parent@123', gen_salt('bf')), NOW(), NOW(), NOW(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Mary Johnson"}',
        NOW(), NOW(), '', '', '', ''
      )
      RETURNING id INTO v_parent4_id;
      
      INSERT INTO public.users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
      VALUES (v_parent4_id, 'mary.johnson@gmail.com', 'Mary Johnson', '+91-9876543213', 'parent', TRUE, NOW(), NOW());
      
      INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
      VALUES (v_parent4_id, v_student3_id, 'mother', TRUE, NOW());
      
      RAISE NOTICE '✅ Created: Mary Johnson (mary.johnson@gmail.com) - Mother of Student 3';
    EXCEPTION
      WHEN unique_violation THEN
        RAISE NOTICE '⚠️  mary.johnson@gmail.com already exists, skipping...';
    END;
    
    -- ============================================
    -- Parent 5: David Johnson (Guardian of Student 3)
    -- ============================================
    BEGIN
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, recovery_sent_at, last_sign_in_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, email_change, email_change_token_new, recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000', uuid_generate_v4(),
        'authenticated', 'authenticated', 'david.johnson@gmail.com',
        crypt('Parent@123', gen_salt('bf')), NOW(), NOW(), NOW(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"David Johnson"}',
        NOW(), NOW(), '', '', '', ''
      )
      RETURNING id INTO v_parent5_id;
      
      INSERT INTO public.users (id, email, full_name, phone, role, email_verified, email_verified_at, created_at)
      VALUES (v_parent5_id, 'david.johnson@gmail.com', 'David Johnson', '+91-9876543214', 'parent', TRUE, NOW(), NOW());
      
      INSERT INTO parents (id, student_id, relationship, is_primary_contact, created_at)
      VALUES (v_parent5_id, v_student3_id, 'guardian', FALSE, NOW());
      
      RAISE NOTICE '✅ Created: David Johnson (david.johnson@gmail.com) - Guardian of Student 3';
    EXCEPTION
      WHEN unique_violation THEN
        RAISE NOTICE '⚠️  david.johnson@gmail.com already exists, skipping...';
    END;
  END IF;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Parent users created successfully!';
  RAISE NOTICE 'Default password: Parent@123';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- Verify Created Parents
-- ============================================
SELECT 
  su.full_name as student,
  pu.full_name as parent,
  pu.email as parent_email,
  pu.phone as parent_phone,
  p.relationship,
  CASE WHEN p.is_primary_contact THEN '⭐ Primary' ELSE 'Secondary' END as contact_type
FROM parents p
JOIN users pu ON pu.id = p.id
JOIN users su ON su.id = p.student_id
ORDER BY su.full_name, p.is_primary_contact DESC;

-- ============================================
-- LOGIN CREDENTIALS
-- ============================================
-- Email: john.doe@gmail.com       | Password: Parent@123 | Role: Father (Primary)
-- Email: jane.doe@gmail.com       | Password: Parent@123 | Role: Mother (Secondary)
-- Email: robert.smith@gmail.com   | Password: Parent@123 | Role: Father (Primary)
-- Email: mary.johnson@gmail.com   | Password: Parent@123 | Role: Mother (Primary)
-- Email: david.johnson@gmail.com  | Password: Parent@123 | Role: Guardian (Secondary)
-- ============================================
