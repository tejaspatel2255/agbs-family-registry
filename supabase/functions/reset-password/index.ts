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
    const { mobile_number, reset_token, new_password } = await req.json();
    const mobileClean = (mobile_number || "").toString().trim();
    const tokenClean = (reset_token || "").toString().trim();
    const passwordClean = (new_password || "").toString();

    if (!mobileClean || !tokenClean || !passwordClean) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Password strength check: Min 8 chars, at least 1 letter, at least 1 number
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

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Verify reset_token in otp_verifications table
    const now = new Date().toISOString();
    const { data: record, error: tokenErr } = await supabase
      .from("otp_verifications")
      .select("*")
      .eq("mobile_number", mobileClean)
      .eq("reset_token", tokenClean)
      .eq("reset_token_used", false)
      .gt("reset_token_expires_at", now)
      .limit(1)
      .maybeSingle();

    if (tokenErr || !record) {
      return new Response(
        JSON.stringify({ error: "Invalid, expired, or already used password reset token." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Fetch admin user profile ID
    const { data: profile, error: profErr } = await supabase
      .from("profiles")
      .select("id, role")
      .eq("mobile_number", mobileClean)
      .maybeSingle();

    if (profErr || !profile || profile.role !== "admin") {
      return new Response(
        JSON.stringify({ error: "Admin profile not found for this mobile number." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Update Supabase Auth Password via Admin API
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

    // 4. Mark reset_token as used
    await supabase
      .from("otp_verifications")
      .update({ reset_token_used: true })
      .eq("id", record.id);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Password updated successfully! Please log in with your new password.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
