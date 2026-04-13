import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { email, password, fullName, phone, hostelName, roomNo,
            semester, section, homeAddress, parentPhone,
            departmentId, class_id } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    console.log(`Creating student: ${email}`);

    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    });

    if (authError) throw authError;

    const userId = authData.user?.id;
    if (!userId) throw new Error("Auth user creation failed");

    const { error: dbError } = await supabaseAdmin.from("users").insert({
      id: userId,
      email,
      full_name: fullName,
      phone,
      role: "student",
      hostel_name: hostelName,
      room_no: roomNo,
      semester,
      section,
      home_address: homeAddress,
      parent_phone: parentPhone,
      department_id: departmentId,
      class_id: class_id,
    });

    if (dbError) {
      console.error('Database error, cleaning up auth user:', dbError);
      await supabaseAdmin.auth.admin.deleteUser(userId);
      throw dbError;
    }

    return new Response(JSON.stringify({ success: true, userId }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });

  } catch (e) {
    console.error('Error:', e.message);
    return new Response(JSON.stringify({ success: false, message: e.message }), {
      status: 400,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
