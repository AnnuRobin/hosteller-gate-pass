-- ============================================
-- Verify Department and Student Data
-- ============================================
-- Run this in Supabase SQL Editor to check your data

-- 1. Check all departments
SELECT 
  id,
  name,
  hod_id,
  created_at
FROM departments
ORDER BY name;

-- 2. Check student distribution by department
SELECT 
  d.name as department_name,
  COUNT(u.id) as student_count,
  COUNT(CASE WHEN u.semester IS NOT NULL AND u.section IS NOT NULL THEN 1 END) as students_with_batch_info
FROM departments d
LEFT JOIN users u ON u.department_id = d.id AND u.role = 'student'
GROUP BY d.id, d.name
ORDER BY d.name;

-- 3. Check batch distribution (semester + section)
SELECT 
  d.name as department,
  u.semester,
  u.section,
  COUNT(u.id) as student_count
FROM departments d
LEFT JOIN users u ON u.department_id = d.id AND u.role = 'student'
WHERE u.semester IS NOT NULL AND u.section IS NOT NULL
GROUP BY d.id, d.name, u.semester, u.section
ORDER BY d.name, u.semester, u.section;

-- 4. Check students without department assignment
SELECT 
  id,
  full_name,
  email,
  role,
  department_id,
  semester,
  section
FROM users
WHERE role = 'student' AND department_id IS NULL;

-- 5. Check students without semester/section
SELECT 
  id,
  full_name,
  email,
  d.name as department,
  semester,
  section
FROM users u
LEFT JOIN departments d ON d.id = u.department_id
WHERE role = 'student' 
  AND (semester IS NULL OR section IS NULL);

-- 6. Sample of properly configured students
SELECT 
  u.id,
  u.full_name,
  u.email,
  d.name as department,
  u.semester,
  u.section
FROM users u
JOIN departments d ON d.id = u.department_id
WHERE u.role = 'student'
  AND u.semester IS NOT NULL 
  AND u.section IS NOT NULL
ORDER BY d.name, u.semester, u.section, u.full_name
LIMIT 20;
