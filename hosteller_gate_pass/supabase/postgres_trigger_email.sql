-- =========================================================================
-- SETUP INSTRUCTIONS FOR RESEND EMAIL TRIGGER
-- =========================================================================
-- 1. Create your API Key in Resend (https://resend.com/api-keys)
-- 2. Paste your API Key into the `v_resend_api_key` variable below.
-- 3. Run this script in the Supabase SQL Editor to activate it.
-- =========================================================================

-- Step 1: Create the Function that does the actual API call
CREATE OR REPLACE FUNCTION send_email_on_hod_approval() 
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_student_email text;
  v_student_name text;
  v_html_body text;
  v_request_id bigint;
  
  -- 🔴 REPLACE THIS WITH YOUR RESEND API KEY 🔴
  v_resend_api_key text := 're_ae5fXYn8_JTkHRcCygCysQKeL1AfGsZP5'; 
BEGIN
  -- Only trigger when HOD status flips exactly to 'approved' and it hasn't fired yet
  IF NEW.hod_status = 'approved' AND (OLD.hod_status IS DISTINCT FROM 'approved') THEN
    
    -- Fetch the student's email and name from the `users` table. 
    -- Fetch the email from the `users` table.
    -- (We are fetching the student's `email`. If you created a dedicated column for the parent, change `email` to `parent_email` below!)
    SELECT email, full_name 
    INTO v_demo_email, v_student_name
    FROM public.users 
    WHERE id = NEW.student_id;

    IF v_demo_email IS NOT NULL AND v_demo_email <> '' THEN

        -- Create a beautiful HTML Email message
        v_html_body := '
        <div style="font-family: sans-serif; padding: 20px; border-radius: 8px; border: 1px solid #e2e8f0; max-width: 500px;">
           <h2 style="color: #059669;">✅ Gate Pass Approved</h2>
           <p style="color: #334155; font-size: 16px;">
             Hello Parent,<br><br>
             Your child <strong>' || v_student_name || '</strong> has been fully approved for a gate pass by the HOD.<br><br>
             <strong>Destination:</strong> ' || NEW.destination || '<br>
             <strong>Reason:</strong> ' || NEW.reason || '
           </p>
           <p style="color: #64748B; font-size: 14px; margin-top: 20px;">
             <em>Please find further details in the Hosteller App.</em>
           </p>
        </div>';

        -- Fire the asynchronous HTTP POST request to Resend leveraging pg_net
        SELECT net.http_post(
          url := 'https://api.resend.com/emails',
          headers := jsonb_build_object(
              'Authorization', 'Bearer ' || v_resend_api_key,
              'Content-Type', 'application/json'
          ),
          body := jsonb_build_object(
              'from', 'Hosteller App <onboarding@resend.dev>',
              'to', jsonb_build_array(v_demo_email),
              'subject', 'Gate Pass Approved for ' || v_student_name,
              'html', v_html_body
          )
        ) INTO v_request_id;
        
        -- Mark as notified in the DB so it doesn't try sending multiple times 
        NEW.parent_notified := TRUE;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Step 2: Swap out the old MSG91 trigger for the new Email Trigger
DROP TRIGGER IF EXISTS trigger_send_sms_on_hod_approval ON public.gate_pass_requests;
DROP TRIGGER IF EXISTS trigger_send_email_on_hod_approval ON public.gate_pass_requests;

CREATE TRIGGER trigger_send_email_on_hod_approval
BEFORE UPDATE ON public.gate_pass_requests
FOR EACH ROW
EXECUTE FUNCTION send_email_on_hod_approval();
