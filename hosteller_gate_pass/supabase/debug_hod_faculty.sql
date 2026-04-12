-- ── STEP 1: Check what error the function gives ─────────────────────────────
-- Run this in SQL Editor logged in as a HOD user to test:
-- (Replace the email/password with test values)

SELECT public.hod_create_faculty(
  p_email         := 'testfaculty@test.com',
  p_password      := 'Test@1234',
  p_full_name     := 'Test Faculty',
  p_phone         := '9876543210',
  p_department_id := NULL,  -- NULL = use HOD's own department
  p_class_id      := NULL
);

-- ── STEP 2: Check if pgcrypto is available ───────────────────────────────────
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';

-- ── STEP 3: Check auth.identities columns ───────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'identities'
ORDER BY ordinal_position;

-- ── STEP 4: Check auth.users columns ────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;
