-- =========================================================================
-- SETUP INSTRUCTIONS
-- =========================================================================
-- 1. Ensure `pg_net` is enabled in your Supabase Dashboard
--    (Database -> Extensions -> pg_net)
-- 2. Modify the placeholders in the function below with your actual values:
--    - YOUR_MSG91_AUTH_KEY
--    - HSTPASS (your sender ID)
-- 3. Run this script in the Supabase SQL Editor.
-- =========================================================================

-- Step 1: Create the Function that does the actual API call
CREATE OR REPLACE FUNCTION send_msg91_sms_on_approval() 
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER -- Ensures it has permission to read the users table
AS $$
DECLARE
  v_parent_phone text;
  v_student_name text;
  v_message text;
  v_url text;
  v_request_id bigint;
  
  -- 🔴 REPLACE THESE WITH YOUR MSG91 CREDENTIALS 🔴
  v_auth_key text := '504526AIsxXjUa89U69ca642bP1'; 
  v_sender_id text := 'HSTPASS';
  v_dlt_te_id text := 'YOUR_DLT_TEMPLATE_ID'; -- Add your DLT Template ID here
BEGIN
  -- Only trigger when HOD status flips exactly to 'approved' and it hasn't fired yet
  IF NEW.hod_status = 'approved' AND (OLD.hod_status IS DISTINCT FROM 'approved') THEN
    
    -- Fetch the parent's phone number and student's name from the `users` table
    -- Since the user mentioned the 'parentsphno' column is in their 'users' table
    SELECT parentphno, full_name 
    INTO v_parent_phone, v_student_name
    FROM public.users 
    WHERE id = NEW.student_id;

    -- If parent phone is empty, skip.
    IF v_parent_phone IS NOT NULL AND v_parent_phone <> '' THEN

        -- Create SMS message text
        v_message := 'Your child ' || v_student_name || ' has been approved for a gate pass. Please find details in the hosteller app.';
        
        -- URL encode spaces (naive approach for spaces)
        -- Since the rest is simple alphanumeric, replacing space with '%20' works perfectly.
        v_message := replace(v_message, ' ', '%20');

        -- Prepare the MSG91 GET request URL (Ensure route=4 for transactional)
        v_url := 'https://api.msg91.com/api/sendhttp.php' ||
                 '?authkey=' || v_auth_key ||
                 '&mobiles=' || v_parent_phone ||
                 '&message=' || v_message ||
                 '&sender=' || v_sender_id ||
                 '&route=4' ||
                 '&DLT_TE_ID=' || v_dlt_te_id ||
                 '&country=91';

        -- Fire the asynchronous HTTP GET request leveraging pg_net
        SELECT net.http_get(url := v_url) INTO v_request_id;
        
        -- Mark as notified in the DB so it doesn't try sending multiple times 
        NEW.parent_notified := TRUE;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Step 2: Create the Trigger that fires BEFORE the update on gate_pass_requests
DROP TRIGGER IF EXISTS trigger_send_sms_on_hod_approval ON public.gate_pass_requests;

CREATE TRIGGER trigger_send_sms_on_hod_approval
BEFORE UPDATE ON public.gate_pass_requests
FOR EACH ROW
EXECUTE FUNCTION send_msg91_sms_on_approval();
