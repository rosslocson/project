# 🚀 Fix Email OTP (Forgot Password / Send OTP)

## 1. Gmail App Password Setup (2 mins)
1. Login Gmail → [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. **Enable 2FA first** (if not).
3. Select **App=Mail**, **Device=Other** → **Generate**.
4. Copy **16-char code** (abcd efgh ijkl mnop → abcdefghijklmnop).

## 2. Update .env
```
SMTP_EMAIL=your@gmail.com
SMTP_PASSWORD=abcdefghijklmnop  # ← your 16-char code
```

## 3. Restart Backend
```powershell
cd backend
go run main.go
```
**Logs show:** `SMTP_HOST=smtp.gmail.com:587, EMAIL=your***` + `Server running on port 8080`

## 4. Test Email
**Browser:** http://localhost:8080/api/test-email?to=your@gmail.com  
**PowerShell:** `Invoke-RestMethod "http://localhost:8080/api/test-email?to=your@gmail.com"`  
**Expected:** `{"message":"Test email sent..."}`

## 5. Flutter App
Login Screen → **Forgot Password** → **SEND OTP** → **Check inbox/spam** (OTP expires 5min).

## Errors & Fixes
| Log/Error | Fix |
|-----------|-----|
| `SMTP_EMAIL not set` | Edit .env + restart |
| `535 Authentication failed` | New App Password |
| `connection refused` | Server running? port 8080 |
| No email but `"If email exists..."` | Check **spam**! |

**Postman:** Import `postman_collection.json` → Auth → forgot-password.

✅ **OTP emails now work instantly!** 🎉
