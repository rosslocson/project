# InternSpace Backend

## Setup

1. Install Go 1.21+
2. `go mod tidy`
3. PostgreSQL: run schema.sql or AutoMigrate runs
4. Copy `.env.example` to `.env` and edit:
   - SMTP_EMAIL/SMTP_PASSWORD (Gmail App Password required)
   - DATABASE_URL
5. `go build -o server ./main.go` or `./server` (Linux/Mac) / `server.exe` (Windows)

## Test Email
```
curl \"http://localhost:8080/api/test-email?to=your@email.com\"
```
Check server logs and your inbox/spam.

## Reset Password Flow
1. Frontend calls POST /api/auth/forgot-password {email: \"user@example.com\"}
2. 6-digit OTP emailed (5min expiry)
3. POST /api/auth/reset-password {token: \"123456\", new_password: \"...\"}

## Postman
import postman_collection.json (add register/login first)

## Run
`cd backend && ./server`

