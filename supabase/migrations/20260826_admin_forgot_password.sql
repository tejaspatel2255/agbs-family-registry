-- Add reset_password purpose constraint and reset token columns to otp_verifications
ALTER TABLE public.otp_verifications DROP CONSTRAINT IF EXISTS otp_verifications_purpose_check;
ALTER TABLE public.otp_verifications ADD CONSTRAINT otp_verifications_purpose_check CHECK (purpose IN ('signup', 'login', 'reset_password'));

ALTER TABLE public.otp_verifications ADD COLUMN IF NOT EXISTS reset_token TEXT;
ALTER TABLE public.otp_verifications ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMPTZ;
ALTER TABLE public.otp_verifications ADD COLUMN IF NOT EXISTS reset_token_used BOOLEAN DEFAULT FALSE;
