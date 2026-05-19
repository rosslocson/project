-- Safe migration for backward-compatible email verification.
-- This migration adds new fields used by the OTP flow and marks
-- all existing persisted users as legacy-compatible so they can
-- continue logging in without requiring retroactive email OTP.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS legacy_account BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS verification_token VARCHAR,
    ADD COLUMN IF NOT EXISTS verification_token_expiry TIMESTAMP WITH TIME ZONE;

UPDATE users
SET legacy_account = true
WHERE COALESCE(is_verified, false) = false;
