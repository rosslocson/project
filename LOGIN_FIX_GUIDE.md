# Login & Forgot Password Fix Guide

## Problems Identified & Fixed

### ✅ **Issue 1: Admin Account Not Created (CRITICAL)**
**Problem:** The `schema.sql` file contains an INSERT statement for the admin account, but the Go application never executes it. It only runs `AutoMigrate()` which creates tables from models.

**Solution Implemented:** 
- Added `seedAdminAccount()` function in `main.go` that automatically creates the admin account on startup
- Function checks if admin exists first to avoid duplicates
- Admin credentials: `admin@example.com` / `admin123`

**What you need to do:**
1. Restart the backend server (`go run main.go`)
2. The admin account will be created automatically

---

### ✅ **Issue 2: Email Whitespace Not Trimmed**
**Problem:** Users entering emails with leading/trailing spaces (e.g., `" admin@example.com "`) would fail login because:
- Frontend trimmed email but backend handlers didn't
- Repository GetByEmail only converted to lowercase, didn't trim

**Solution Implemented:**
- In `auth_handlers.go`: Added `strings.TrimSpace()` to both Login and Register
- In `user_repository.go`: Added `strings.TrimSpace()` to GetByEmail

**Impact:** Login now works with accidental spaces in email input

---

### ✅ **Issue 3: Password Whitespace Not Trimmed**  
**Problem:** Passwords with leading/trailing spaces would fail because bcrypt comparison is exact

**Solution Implemented:**
- In `login_screen.dart`: Changed `_passCtrl.text` to `_passCtrl.text.trim()`
- In `auth_service.go`: Added `strings.TrimSpace()` to password before bcrypt comparison

**Impact:** Password input now works even if user accidentally added spaces

---

### 🔐 **Issue 4: Forgot Password Requires SMTP Configuration**
**Problem:** Forgot password sends OTP via email, but requires environment variables

**What you need to do:**
1. Set up Gmail App Password (if using Gmail):
   - Go to https://myaccount.google.com/apppasswords
   - Generate app password for your account
   
2. Create `.env` file in backend folder with:
```bash
SMTP_EMAIL=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
DATABASE_URL=host=localhost user=postgres password=alex12345 dbname=userapp port=5432 sslmode=disable
JWT_SECRET=your-secret-key-change-in-production
```

3. The application will log detailed SMTP errors if something goes wrong

---

## Testing the Fixes

### 1. **Test Admin Login**
```
Email: admin@example.com
Password: admin123
```
✅ Should now successfully log in and show admin dashboard

### 2. **Test User Registration**
- Register a new user with email and password
- Passwords are hashed with bcrypt
- Login with the registered account

### 3. **Test Forgot Password**
```
1. Click "Forgot Password?"
2. Enter email address
3. Check inbox for 6-digit OTP
4. Enter OTP and new password
5. Reset password
6. Login with new password
```

---

## Files Modified

1. **backend/main.go**
   - Added bcrypt import
   - Added seedAdminAccount() function
   - Call seedAdminAccount(DB) after migrations

2. **backend/handlers/auth_handlers.go**
   - Login: Trim email before passing to service
   - Register: Trim email before passing to service

3. **backend/services/auth_service.go**
   - Login: Trim password before bcrypt comparison

4. **backend/repositories/user_repository.go**
   - GetByEmail: Trim email before database query

5. **frontend/lib/screens/login_screen.dart**
   - _login(): Trim password input

---

## Troubleshooting

### Login still failing?
- Check that backend is running: `go run main.go`
- Look for log messages about admin account creation
- Verify database connection with: `psql -U postgres -d userapp -c "SELECT email, role FROM users;"`
- Try the test admin account: admin@example.com / admin123

### Forgot Password email not received?
- Check backend logs for SMTP errors (look for 🚫, 🔌, ⏱️ emojis)
- Verify `.env` file has SMTP credentials
- If using Gmail, ensure App Password is correct (NOT regular password)
- Check spam folder
- Try resetting OTP expiry in database if needed

### Password comparison still failing?
- Ensure no extra spaces in password input
- Check that passwords are using bcrypt hashes in database
- If users registered before fix, their passwords should still be hashed correctly

---

## Security Notes

- **Never commit `.env` file** - add to `.gitignore`
- Change JWT_SECRET in `.env` for production
- Change SMTP credentials for production
- Consider rotating app passwords periodically
- Admin password "admin123" should be changed after first login

