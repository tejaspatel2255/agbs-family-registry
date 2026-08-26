// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { reset_token, new_password } = await req.json();
    const tokenClean = (reset_token || "").toString().trim();
    const passwordClean = (new_password || "").toString();

    if (!tokenClean || !passwordClean) {
      return new Response(
        JSON.stringify({ error: "Reset token and new password are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Look up token in password_reset_tokens table (must exist, not used, not expired)
    const now = new Date().toISOString();
    const { data: tokenRecord, error: tokenErr } = await supabase
      .from("password_reset_tokens")
      .select("*")
      .eq("token", tokenClean)
      .eq("used", false)
      .gt("expires_at", now)
      .limit(1)
      .maybeSingle();

    if (tokenErr || !tokenRecord) {
      return new Response(
        JSON.stringify({ error: "Reset link expired, please try again." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validate password strength rule (min 8 chars, at least one letter and one number)
    if (
      passwordClean.length < 8 ||
      !/[a-zA-Z]/.test(passwordClean) ||
      !/[0-9]/.test(passwordClean)
    ) {
      return new Response(
        JSON.stringify({
          error: "Password must be at least 8 characters long and contain at least one letter and one number.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Find user profile linked to mobile_number
    const { data: profile, error: profErr } = await supabase
      .from("profiles")
      .select("id, role")
      .eq("mobile_number", tokenRecord.mobile_number)
      .maybeSingle();

    if (profErr || !profile) {
      return new Response(
        JSON.stringify({ error: "User account not found for this reset token." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Update user password via Supabase Admin API
    const { error: updateErr } = await supabase.auth.admin.updateUserById(
      profile.id,
      { password: passwordClean }
    );

    if (updateErr) {
      return new Response(
        JSON.stringify({ error: `Failed to update password: ${updateErr.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Mark token as used = true
    await supabase
      .from("password_reset_tokens")
      .update({ used: true })
      .eq("id", tokenRecord.id);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
