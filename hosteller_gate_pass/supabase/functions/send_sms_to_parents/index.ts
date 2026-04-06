import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const msg91AuthKey = Deno.env.get('MSG91_AUTH_KEY') || '';
const msg91SenderId = Deno.env.get('MSG91_SENDER_ID') || '';

const supabase = createClient(supabaseUrl, supabaseKey);

// Format Indian phone number to international format
function formatPhoneNumber(phone: string): string {
  // Remove any existing +91 or + prefixes
  phone = phone.replace(/\+91/g, '').replace(/\+/g, '');
  // Remove any spaces or dashes
  phone = phone.replace(/\s/g, '').replace(/-/g, '');
  // Return just the 10 digits for MSG91
  return phone;
}

// Send SMS via MSG91 API
async function sendSmsViaMSG91(phoneNumber: string, message: string): Promise<boolean> {
  try {
    const formattedPhone = formatPhoneNumber(phoneNumber);

    const url = new URL('https://api.msg91.com/api/sendhttp.php');
    url.searchParams.append('authkey', msg91AuthKey);
    url.searchParams.append('mobiles', formattedPhone);
    url.searchParams.append('message', message);
    url.searchParams.append('sender', msg91SenderId);
    url.searchParams.append('route', '4');
    url.searchParams.append('country', '91');

    const response = await fetch(url.toString());

    if (response.ok) {
      console.log(`SMS sent successfully to ${phoneNumber}`);
      return true;
    } else {
      const text = await response.text();
      console.error(`Failed to send SMS to ${phoneNumber}: ${text}`);
      return false;
    }
  } catch (error) {
    console.error(`Error sending SMS to ${phoneNumber}:`, error);
    return false;
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  try {
    const { student_id, request_id } = await req.json();

    if (!student_id || !request_id) {
      return new Response(
        JSON.stringify({ error: 'student_id and request_id are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Fetch student name
    const { data: studentData, error: studentError } = await supabase
      .from('users')
      .select('full_name, id')
      .eq('id', student_id)
      .single();

    if (studentError || !studentData) {
      return new Response(
        JSON.stringify({ error: 'Student not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const studentName = studentData.full_name;

    // Fetch parents for the student
    const { data: parentsData, error: parentsError } = await supabase
      .from('parents')
      .select('id, user_id')
      .eq('student_id', student_id);

    if (parentsError || !parentsData || parentsData.length === 0) {
      console.log('No parents found for student:', student_id);
      return new Response(
        JSON.stringify({ message: 'No parents found for student', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Fetch phone numbers from users table for each parent
    const parentIds = parentsData.map(p => p.user_id);
    const { data: parentUsers, error: usersError } = await supabase
      .from('users')
      .select('phone')
      .in('id', parentIds);

    if (usersError || !parentUsers) {
      console.log('Error fetching parent phone numbers:', usersError);
      return new Response(
        JSON.stringify({ error: 'Error fetching parent phone numbers' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Filter valid phone numbers
    const phoneNumbers = parentUsers
      .map(u => u.phone)
      .filter(phone => phone && phone.length >= 10);

    if (phoneNumbers.length === 0) {
      console.log('No valid phone numbers for parents');
      return new Response(
        JSON.stringify({ message: 'No valid phone numbers for parents', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Prepare SMS message
    const message = `Your child ${studentName} has been approved for a gate pass. Please find details in the hosteller app.`;

    // Send SMS to all parents
    let sentCount = 0;
    for (const phone of phoneNumbers) {
      const success = await sendSmsViaMSG91(phone, message);
      if (success) sentCount++;
    }

    // Mark gate pass as parent_notified
    await supabase
      .from('gate_pass_requests')
      .update({ parent_notified: true })
      .eq('id', request_id);

    return new Response(
      JSON.stringify({
        message: 'SMS notification sent to parents',
        sent: sentCount,
        total_parents: phoneNumbers.length,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
