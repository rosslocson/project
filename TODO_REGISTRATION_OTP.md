# TODO: Registration duplicate-email + OTP verification

## Step 1 — Duplicate email fix
- [ ] Update `backend/services/auth_service.go` `Register()` to check email existence (case-insensitive) before `Create`, and return a controlled error.
- [ ] Ensure `backend/handlers/auth_handlers.go` maps that controlled error to HTTP 409 (Conflict).

## Step 2 — Registration OTP fields (backend)
- [ ] Update `backend/models/user.go` to add `VerificationOTP` and `VerificationOTPExpiry` fields with GORM column tags.

## Step 3 — Registration OTP send + persistence (backend)
- [ ] Update `backend/services/auth_service.go` `Register()` to:
  - [ ] generate a 6-digit OTP
  - [ ] persist OTP + expiry
  - [ ] send email via `backend/email/register_email.go` `SendRegistrationEmail`

## Step 4 — Registration OTP verify endpoint (backend)
- [ ] Add endpoint handler `POST /api/auth/verify-otp` in `backend/handlers/auth_handlers.go`.
- [ ] Wire the route in `backend/main.go`.

## Step 5 — Flutter frontend call real verify endpoint
- [ ] Update `frontend/lib/screens/email_verification_screen.dart` to call `/api/auth/verify-otp` with the entered OTP.
- [ ] Remove mock `123456` validation.

## Step 6 — Manual verification checklist
- [ ] Register with same email twice: second attempt returns 409 “email already in use”.
- [ ] Register new email: OTP email is sent.
- [ ] Enter OTP: account becomes verified and navigate succeeds.

