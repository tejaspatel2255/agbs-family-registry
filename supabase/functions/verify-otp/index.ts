// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    const { mobile_number, otp, purpose, full_name } = await req.json();
    const mobileClean = (mobile_number || "").toString().trim();
    const otpClean = (otp || "").toString().trim();

    if (!mobileClean || !otpClean || !purpose) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch latest unverified, unexpired row
    const now = new Date().toISOString();
    const { data: record, error: fetchErr } = await supabase
      .from("otp_verifications")
      .select("*")
      .eq("mobile_number", mobileClean)
      .eq("purpose", purpose)
      .eq("verified", false)
      .gt("expires_at", now)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (fetchErr || !record) {
      return new Response(
        JSON.stringify({ error: "OTP expired or invalid. Please request a new one." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Check max attempts (5)
    if (record.attempts >= 5) {
      return new Response(
        JSON.stringify({ error: "Too many attempts. Please request a new OTP." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Hash input OTP & compare
    const inputHash = await hashOtp(otpClean);
    if (inputHash !== record.otp_hash) {
      // Increment attempts
      await supabase
        .from("otp_verifications")
        .update({ attempts: record.attempts + 1 })
        .eq("id", record.id);

      return new Response(
        JSON.stringify({ error: "Incorrect OTP. Please try again." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // If purpose === 'reset_password'
    if (purpose === "reset_password") {
      // Look up profile by mobile_number
      const { data: profile, error: profErr } = await supabase
        .from("profiles")
        .select("id, role")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (profErr || !profile) {
        return new Response(
          JSON.stringify({ error: "No account found for this number" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Mark OTP as verified
      await supabase
        .from("otp_verifications")
        .update({ verified: true })
        .eq("id", record.id);

      // Generate secure random token, insert row into password_reset_tokens (expires in 10 mins)
      const resetToken = crypto.randomUUID();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

      const { error: tokenInsertErr } = await supabase
        .from("password_reset_tokens")
        .insert({
          mobile_number: mobileClean,
          token: resetToken,
          expires_at: expiresAt,
          used: false,
        });

      if (tokenInsertErr) {
        return new Response(
          JSON.stringify({ error: `Failed to create reset token: ${tokenInsertErr.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          reset_token: resetToken,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Mark verified = true for normal login/signup
    await supabase
      .from("otp_verifications")
      .update({ verified: true })
      .eq("id", record.id);

    const syntheticEmail = `${mobileClean}@agbs.app`;

    if (purpose === "signup") {
      // Check if user already exists
      const { data: existingProfile } = await supabase
        .from("profiles")
        .select("id")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      let userId = existingProfile?.id;

      if (!userId) {
        // Create auth user with random secure password
        const randomPassword = `AGBS#${crypto.randomUUID()}`;
        const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
          email: syntheticEmail,
          password: randomPassword,
          email_confirm: true,
          user_metadata: {
            full_name: full_name || "Member",
            mobile_number: mobileClean,
          },
        });

        if (createErr || !newUser.user) {
          return new Response(
            JSON.stringify({ error: createErr?.message || "Failed to create user account." }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        userId = newUser.user.id;

        // Create profile row
        await supabase.from("profiles").upsert({
          id: userId,
          mobile_number: mobileClean,
          role: "member",
          full_name: full_name || "Member",
        });
      }

      // Mint session for user
      const { data: linkData, error: linkErr } = await supabase.auth.admin.generateLink({
        type: "magiclink",
        email: syntheticEmail,
      });

      if (linkErr || !linkData) {
        return new Response(
          JSON.stringify({ error: "Failed to generate user session." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          user_id: userId,
          access_token: linkData.properties?.hashed_token || "",
          refresh_token: linkData.properties?.action_link || "",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // purpose === 'login'
      const { data: profile } = await supabase
        .from("profiles")
        .select("id")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (!profile) {
        return new Response(
          JSON.stringify({ error: "Account not found for this mobile number. Please sign up first." }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Mint session for existing user
      const { data: linkData, error: linkErr } = await supabase.auth.admin.generateLink({
        type: "magiclink",
        email: syntheticEmail,
      });

      if (linkErr || !linkData) {
        return new Response(
          JSON.stringify({ error: "Failed to create user session." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          user_id: profile.id,
          access_token: linkData.properties?.hashed_token || "",
          refresh_token: linkData.properties?.action_link || "",
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
