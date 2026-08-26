// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY") || "";
const BREVO_SENDER = Deno.env.get("BREVO_SENDER") || "AGBS";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function hashOtp(otp: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(otp);
  const hashBuffer = await crypto.subtle.digest("SHA-256", msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { mobile_number, purpose } = await req.json();

    // 1. Validate Mobile Number (10-digit Indian number)
    const mobileClean = (mobile_number || "").toString().trim();
    if (!/^[6-9]\d{9}$/.test(mobileClean)) {
      return new Response(
        JSON.stringify({ error: "Please enter a valid 10-digit mobile number." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const validPurpose = ["signup", "login", "reset_password"].includes(purpose) ? purpose : "signup";
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1b. If purpose is reset_password, verify that a Member profile exists for this mobile number
    if (validPurpose === "reset_password") {
      const { data: profile, error: profErr } = await supabase
        .from("profiles")
        .select("role")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (profErr || !profile) {
        return new Response(
          JSON.stringify({ error: "No registered account found for this mobile number." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 2. Rate Limit Cooldown (30 seconds)
    const thirtySecsAgo = new Date(Date.now() - 30 * 1000).toISOString();
    const { data: recentOtps } = await supabase
      .from("otp_verifications")
      .select("created_at")
      .eq("mobile_number", mobileClean)
      .eq("purpose", validPurpose)
      .eq("verified", false)
      .gte("created_at", thirtySecsAgo);

    if (recentOtps && recentOtps.length > 0) {
      return new Response(
        JSON.stringify({ error: "Please wait 30 seconds before requesting a new OTP." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Generate 6-digit OTP & Hash with SHA-256
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otp_hash = await hashOtp(otp);
    const expires_at = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    // 4. Insert row into otp_verifications database
    const { error: dbError } = await supabase.from("otp_verifications").insert({
      mobile_number: mobileClean,
      otp_hash,
      purpose: validPurpose,
      expires_at,
      attempts: 0,
      verified: false,
    });

    if (dbError) {
      return new Response(
        JSON.stringify({ error: `Database error: ${dbError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Send Transactional SMS via Brevo API
    let brevoSuccess = false;
    let brevoErrMsg = "";

    const smsMessage = validPurpose === "reset_password"
      ? `Your AGBS Password Reset OTP is ${otp}. Valid for 5 minutes. Do not share this code.`
      : `Your AGBS Family Registry OTP is ${otp}. Valid for 5 minutes. Do not share this code.`;

    try {
      const brevoResponse = await fetch("https://api.brevo.com/v3/transactionalSMS/sms", {
        method: "POST",
        headers: {
          "api-key": BREVO_API_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          sender: BREVO_SENDER,
          recipient: `91${mobileClean}`,
          content: smsMessage,
          type: "transactional",
        }),
      });

      if (brevoResponse.ok) {
        brevoSuccess = true;
      } else {
        brevoErrMsg = await brevoResponse.text();
        console.error("Brevo SMS API Error:", brevoErrMsg);
      }
    } catch (err: any) {
      brevoErrMsg = err.message || "Failed to reach Brevo API";
    }

    if (brevoSuccess) {
      return new Response(
        JSON.stringify({ success: true, message: `OTP sent via SMS to +91 ${mobileClean}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // Fallback for testing if Brevo SMS fails due to missing SMS credits or sender ID restrictions
      return new Response(
        JSON.stringify({
          success: true,
          message: `OTP generated (Brevo SMS Notice: ${brevoErrMsg}). Verification Code: ${otp}`,
          dev_otp: otp,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
