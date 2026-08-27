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
    const body = await req.json();
    const { mobile_number, otp, purpose, full_name, role, requested_role, password } = body;
    const mobileClean = (mobile_number || "").toString().trim();
    const otpClean = (otp || "").toString().trim();
    const reqRoleRaw = requested_role || role;
    const targetRole = reqRoleRaw === "admin" ? "admin" : "member";

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
      await supabase
        .from("otp_verifications")
        .update({ attempts: record.attempts + 1 })
        .eq("id", record.id);

      return new Response(
        JSON.stringify({ error: "Incorrect OTP. Please try again." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Reset password purpose
    if (purpose === "reset_password") {
      const { data: profile, error: profErr } = await supabase
        .from("profiles")
        .select("id")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (profErr || !profile) {
        return new Response(
          JSON.stringify({ error: "No account found for this number." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabase
        .from("otp_verifications")
        .update({ verified: true })
        .eq("id", record.id);

      const resetToken = crypto.randomUUID();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

      await supabase.from("password_reset_tokens").insert({
        mobile_number: mobileClean,
        token: resetToken,
        expires_at: expiresAt,
        used: false,
      });

      return new Response(
        JSON.stringify({ success: true, reset_token: resetToken }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mark OTP verified
    await supabase
      .from("otp_verifications")
      .update({ verified: true })
      .eq("id", record.id);

    const syntheticEmail = `${mobileClean}@agbs.app`;

    if (purpose === "signup") {
      // Check if profile already exists for this mobile
      const { data: existingProfile } = await supabase
        .from("profiles")
        .select("id, roles, role, full_name")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (existingProfile) {
        let existingRoles: string[] = [];
        if (Array.isArray(existingProfile.roles) && existingProfile.roles.length > 0) {
          existingRoles = existingProfile.roles;
        } else if (existingProfile.role) {
          existingRoles = [existingProfile.role];
        }

        // Case A: User already has requested_role
        if (existingRoles.includes(targetRole)) {
          return new Response(
            JSON.stringify({
              error: `Already registered as ${targetRole}, please log in instead.`,
            }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Case B: User exists, but doesn't have requested_role -> Add Role Flow
        if (!password) {
          return new Response(
            JSON.stringify({ error: "Incorrect password for this account." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Verify password against auth
        const { error: authErr } = await supabase.auth.signInWithPassword({
          email: syntheticEmail,
          password: password.trim(),
        });

        if (authErr) {
          return new Response(
            JSON.stringify({ error: "Incorrect password for this account." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Append new role to existing roles
        const updatedRoles = Array.from(new Set([...existingRoles, targetRole]));
        await supabase
          .from("profiles")
          .update({
            roles: updatedRoles,
            role: targetRole,
          })
          .eq("id", existingProfile.id);

        return new Response(
          JSON.stringify({
            success: true,
            added_role: targetRole,
            user_id: existingProfile.id,
            roles: updatedRoles,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Case C: New User Signup
      const userPassword = password || `AGBS#${crypto.randomUUID()}`;
      const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
        email: syntheticEmail,
        password: userPassword,
        email_confirm: true,
        user_metadata: {
          full_name: full_name || "User",
          mobile_number: mobileClean,
        },
      });

      if (createErr || !newUser.user) {
        return new Response(
          JSON.stringify({ error: createErr?.message || "Failed to create user account." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const userId = newUser.user.id;

      await supabase.from("profiles").upsert({
        id: userId,
        mobile_number: mobileClean,
        roles: [targetRole],
        role: targetRole,
        full_name: full_name || (targetRole === "admin" ? "Admin" : "Member"),
      });

      // Generate session
      const { data: linkData } = await supabase.auth.admin.generateLink({
        type: "magiclink",
        email: syntheticEmail,
      });

      return new Response(
        JSON.stringify({
          success: true,
          user_id: userId,
          roles: [targetRole],
          access_token: linkData?.properties?.hashed_token || "",
          refresh_token: linkData?.properties?.action_link || "",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // Login purpose
      const { data: profile } = await supabase
        .from("profiles")
        .select("id, roles, role")
        .eq("mobile_number", mobileClean)
        .maybeSingle();

      if (!profile) {
        return new Response(
          JSON.stringify({ error: "Account not found for this mobile number." }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      let existingRoles: string[] = [];
      if (Array.isArray(profile.roles) && profile.roles.length > 0) {
        existingRoles = profile.roles;
      } else if (profile.role) {
        existingRoles = [profile.role];
      }

      return new Response(
        JSON.stringify({
          success: true,
          user_id: profile.id,
          roles: existingRoles,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
