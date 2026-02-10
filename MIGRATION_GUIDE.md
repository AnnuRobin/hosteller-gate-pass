# Quick Start Guide: Database Migration

## Step 1: Run the Migration Script

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file `database_migration.sql` from your project
4. Copy and paste the entire contents into the SQL Editor
5. Click **Run** to execute the migration

> [!WARNING]
> **Test First!** If possible, test this migration in a development/staging environment before running on production.

## Step 2: Create an Admin User

After running the migration, you need to create your first admin user:

```sql
-- In Supabase SQL Editor, run this to make an existing user an admin:
UPDATE users 
SET role = 'admin' 
WHERE email = 'your-admin-email@example.com';
```

Or create a new admin user through the Supabase Auth dashboard and then update their role.

## Step 3: Verify the Migration

Check that all tables were created successfully:

```sql
-- Check if new tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('parents', 'parent_otps', 'admin_audit_log', 'sms_logs');

-- Check if new columns were added to users table
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('semester', 'section', 'home_address', 'email_verified', 'email_verified_at');

-- Check if new columns were added to gate_pass_requests table
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'gate_pass_requests' 
AND column_name IN ('parent_approval_status', 'parent_approved_at', 'parent_remarks');
```

## Step 4: Test Database Functions

```sql
-- Test OTP generation
SELECT * FROM create_parent_otp(
  'your-gate-pass-request-id'::UUID,
  '+1234567890'
);

-- Test email validation
SELECT validate_college_email('student@sjcetpalai.ac.in'); -- Should return true
SELECT validate_college_email('parent@gmail.com'); -- Should return false
```

## Next Steps

After the database migration is complete, you can proceed with:

1. **Implementing the Flutter application code** (models, services, UI screens)
2. **Setting up SMS integration** with Twilio or AWS SNS
3. **Testing the complete workflow** end-to-end

Refer to the `implementation_plan.md` for detailed code examples and implementation guidance.

## Troubleshooting

### Error: "relation already exists"
This means the table was already created. You can either:
- Drop the table first: `DROP TABLE table_name CASCADE;`
- Or modify the script to use `CREATE TABLE IF NOT EXISTS`

### Error: "column already exists"
The column was already added. You can either:
- Drop the column first: `ALTER TABLE table_name DROP COLUMN column_name;`
- Or modify the script to use `ADD COLUMN IF NOT EXISTS`

### Error: "policy already exists"
Drop the existing policy first:
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

## SMS Integration (TODO)

To enable SMS OTP delivery, you'll need to:

1. Sign up for a Twilio account or AWS SNS
2. Get your API credentials
3. Update the `send_sms_otp()` function to integrate with your SMS provider
4. Store credentials securely in Supabase Vault or environment variables

Example Twilio integration (to be added to the function):
```sql
-- This would be implemented using Supabase Edge Functions
-- or a backend service that calls Twilio's API
```
