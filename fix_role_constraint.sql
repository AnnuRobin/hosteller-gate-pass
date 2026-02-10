-- ============================================
-- FIX: Update Users Table Role Constraint
-- ============================================
-- This script fixes the role constraint to include admin, warden, and hod
-- Run this BEFORE creating staff users

-- Step 1: Drop the existing role constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Step 2: Add new constraint with all valid roles
ALTER TABLE users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'advisor', 'hod', 'warden', 'admin', 'parent'));

-- Verify the constraint was added
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND conname = 'users_role_check';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Role constraint updated successfully! Valid roles: student, advisor, hod, warden, admin, parent';
END $$;
