# 🚀 Full-Stack User Management System
## Complete Setup Guide for Beginners
### Stack: Flutter (Frontend) + Go/Golang (Backend) + PostgreSQL (Database)

---

## 📁 Project Structure Overview

```
project/
├── backend/                  ← Go API server
│   ├── main.go               ← Entry point
│   ├── go.mod                ← Go dependencies
│   ├── .env                  ← Environment variables (secrets)
│   ├── handlers/
│   │   └── handlers.go       ← All API route logic
│   ├── middleware/
│   │   └── jwt.go            ← Authentication middleware
│   └── models/
│       └── user.go           ← Database models
│
└── frontend/                 ← Flutter app
    ├── pubspec.yaml          ← Flutter dependencies
    └── lib/
        ├── main.dart         ← App entry + routing
        ├── providers/
        │   └── auth_provider.dart   ← State management
        ├── services/
        │   └── api_service.dart     ← HTTP calls to backend
        ├── screens/
        │   ├── login_screen.dart
        │   ├── register_screen.dart
        │   ├── dashboard_screen.dart
        │   ├── profile_screen.dart
        │   ├── users_screen.dart
        │   └── add_user_screen.dart
        └── widgets/
            ├── sidebar.dart
            └── stat_card.dart
```

---

## 🛠️ PART 1: Install Required Tools

### Step 1 — Install Go (Golang)

1. Go to https://go.dev/dl/
2. Download the installer for your OS (Windows/Mac/Linux)
3. Run the installer, click Next/Install through all steps
4. Open a Terminal (Mac/Linux) or Command Prompt (Windows)
5. Verify installation:
   ```
   go version
   ```
   You should see something like: `go version go1.21.0`

---

### Step 2 — Install PostgreSQL

**Windows:**
1. Go to https://www.postgresql.org/download/windows/
2. Download the installer (choose the latest version)
3. Run installer — during setup:
   - Set password for the `postgres` user to: `postgres`
   - Keep default port: `5432`
   - Click through the rest with defaults
4. When done, open "pgAdmin" (installed alongside PostgreSQL)

**Mac:**
```bash
# Install Homebrew first (if not installed):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then install PostgreSQL:
brew install postgresql@16
brew services start postgresql@16
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

---

### Step 3 — Create the Database

Open terminal/pgAdmin Query Tool and run:

```sql
-- Connect as postgres user first
-- In terminal:
psql -U postgres

-- Then run these commands:
CREATE DATABASE userapp;
\q
```

**On Mac/Linux you may need:**
```bash
sudo -u postgres psql
CREATE DATABASE userapp;
\q
```

---

### Step 4 — Install Flutter

1. Go to https://docs.flutter.dev/get-started/install
2. Choose your OS and follow the guide
3. After install, run:
   ```
   flutter doctor
   ```
4. Fix any issues shown (usually just accepting Android licenses)
5. For **web support** (recommended for this app):
   ```
   flutter config --enable-web
   ```

---

### Step 5 — Install VS Code (Recommended Editor)

1. Go to https://code.visualstudio.com/
2. Install it
3. Open VS Code → Extensions (Ctrl+Shift+X) → Install:
   - **Go** (by Google)
   - **Flutter** (by Dart Code)
   - **Dart** (by Dart Code)

---

## ⚙️ PART 2: Set Up the Backend (Go)

### Step 6 — Copy Backend Files

Create this folder structure on your computer:
```
mkdir -p ~/myproject/backend/handlers
mkdir -p ~/myproject/backend/middleware
mkdir -p ~/myproject/backend/models
```

Copy all the backend files provided:
- `main.go` → `backend/main.go`
- `handlers/handlers.go` → `backend/handlers/handlers.go`
- `middleware/jwt.go` → `backend/middleware/jwt.go`
- `models/user.go` → `backend/models/user.go`
- `go.mod` → `backend/go.mod`
- `.env` → `backend/.env`

---

### Step 7 — Install Go Dependencies

Open terminal in the `backend/` folder:

```bash
cd ~/myproject/backend

# Download all dependencies listed in go.mod
go mod tidy
```

This will automatically download:
- **gin** — web framework (like Express for Node.js)
- **gorm** — database ORM (makes SQL easy)
- **jwt** — authentication tokens
- **bcrypt** — password hashing
- **godotenv** — reads .env files

Wait for it to finish (may take 1-2 minutes).

---

### Step 8 — Configure Database Connection

Open `backend/.env` in any text editor:

```
DATABASE_URL=host=localhost user=postgres password=postgres dbname=userapp port=5432 sslmode=disable
JWT_SECRET=your-super-secret-key-change-this-in-production
PORT=8080
```

⚠️ **Important:** If you set a different password for postgres during install, change `password=postgres` to your actual password.

---

### Step 9 — Run the Backend Server

```bash
cd ~/myproject/backend
go run main.go
```

✅ You should see output like:
```
Database migrated successfully
Server running on port 8080
```

The backend is now running at: **http://localhost:8080**

### Test the backend is working:
Open your browser and go to: `http://localhost:8080/health`
You should see: `{"status":"ok","time":"..."}`

🎉 **Backend is working!**

---

### Step 10 — Create the First Admin User

Since there's no admin yet, we need to create one manually.
While the backend is running, open a NEW terminal:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Admin",
    "last_name": "User",
    "email": "admin@example.com",
    "password": "Admin@123",
    "confirm_password": "Admin@123"
  }'
```

**On Windows** (use PowerShell):
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"first_name":"Admin","last_name":"User","email":"admin@example.com","password":"Admin@123","confirm_password":"Admin@123"}'
```

Then, promote this user to admin directly in the database:

```bash
psql -U postgres -d userapp -c "UPDATE users SET role='admin' WHERE email='admin@example.com';"
```

---

## 📱 PART 3: Set Up the Frontend (Flutter)

### Step 11 — Copy Frontend Files

Create the Flutter project structure:

```bash
cd ~/myproject
flutter create frontend
cd frontend
```

Now **replace** the generated files with the provided ones:
- Replace `pubspec.yaml`
- Replace `lib/main.dart`
- Create folders and copy all files:

```
lib/
  main.dart
  providers/
    auth_provider.dart
  services/
    api_service.dart
  screens/
    login_screen.dart
    register_screen.dart
    dashboard_screen.dart
    profile_screen.dart
    users_screen.dart
    add_user_screen.dart
  widgets/
    sidebar.dart
    stat_card.dart
```

Also create the assets folder:
```bash
mkdir -p assets/images
```

---

### Step 12 — Install Flutter Dependencies

```bash
cd ~/myproject/frontend
flutter pub get
```

This installs all packages from `pubspec.yaml`.

---

### Step 13 — Configure API URL

Open `lib/services/api_service.dart` and check line 4:

```dart
static const String baseUrl = 'http://localhost:8080/api';
```

- ✅ **Running on same computer** → keep `localhost`
- 📱 **Testing on physical phone** → change `localhost` to your computer's IP address
  - Find your IP: run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
  - Example: `'http://192.168.1.100:8080/api'`

---

### Step 14 — Run the Flutter App

**Option A — Run on Web (Easiest for beginners):**
```bash
cd ~/myproject/frontend
flutter run -d chrome
```

**Option B — Run on Windows Desktop:**
```bash
flutter run -d windows
```

**Option C — Run on macOS Desktop:**
```bash
flutter run -d macos
```

**Option D — Run on Android Emulator:**
1. Open Android Studio
2. Start an emulator from AVD Manager
3. Then run: `flutter run`

✅ The app should open showing the Login screen!

---

## 🎯 PART 4: Using the Application

### How to Log In (First Time)

1. Open the app — you'll see the **Login** screen
2. Enter:
   - Email: `admin@example.com`
   - Password: `Admin@123`
3. Click **Sign In**
4. You'll be taken to the **Dashboard**

---

### Dashboard Features

The dashboard shows:
- **Total Users** card — count of all registered users
- **Active Users** card — users with active accounts
- **Admins** card — number of admin accounts
- **Inactive** card — deactivated accounts
- **Recent Users** list — last 5 registered users
- **Recent Activity** feed — login/register/update events

---

### Managing Your Profile

1. Click **My Profile** in the left sidebar
2. **Edit Profile tab:**
   - Change your first/last name, phone, department, position, bio
   - Click **Save Changes**
3. **Change Password tab:**
   - Enter current password
   - Enter new password (must be strong: uppercase + number + special char)
   - Confirm new password
   - Click **Change Password**

---

### Managing Users (Admin Only)

1. Click **Users** in the sidebar (only visible to admins)
2. You'll see a list of all users
3. **Search:** Type in the search bar and press Enter
4. **Toggle Active/Inactive:** Use the switch next to each user
5. **Delete:** Click the red trash icon
6. **Add New User:** Click the **Add User** button (top right)

---

### Registering a New Account

1. On the Login screen, click **Sign up**
2. Fill in:
   - First and Last name
   - Email address
   - Phone (optional)
   - Department and Position (optional)
   - Password — must contain:
     - At least 8 characters
     - One UPPERCASE letter
     - One number (0-9)
     - One special character (!@#$%...)
   - Confirm Password — must match exactly
3. The **password strength meter** shows Weak/Fair/Good/Strong in real-time
4. Click **Create Account**

---

## 🔌 PART 5: API Reference

All endpoints use JSON. Protected routes require the `Authorization: Bearer <token>` header.

### Authentication
| Method | URL | Description |
|--------|-----|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |

### Profile (requires login)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/profile` | Get my profile |
| PUT | `/api/profile` | Update my profile |
| PUT | `/api/profile/password` | Change password |

### Dashboard (requires login)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/dashboard/stats` | Get stats + recent data |

### Users (admin only)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/users` | List all users |
| POST | `/api/users` | Create user |
| GET | `/api/users/:id` | Get user by ID |
| PUT | `/api/users/:id` | Update user |
| DELETE | `/api/users/:id` | Delete user |

### Activity Logs (requires login)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/activity` | Get activity logs |

---

## ❗ PART 6: Common Errors & Fixes

### Error: "Connection refused" in Flutter app
**Cause:** Backend is not running
**Fix:** Go to backend folder, run `go run main.go`

### Error: "Failed to connect to database"
**Cause:** PostgreSQL is not running or wrong credentials
**Fix:**
```bash
# Start PostgreSQL
# Windows: Open Services app, find PostgreSQL, click Start
# Mac:
brew services start postgresql@16
# Linux:
sudo systemctl start postgresql
```

### Error: "Email already registered"
**Cause:** You tried to register with an email that exists
**Fix:** Use a different email or use the login screen

### Error: "Password too weak"
**Fix:** Make sure password has:
- 8+ characters
- At least one A-Z
- At least one a-z
- At least one 0-9
- At least one symbol like !@#$

### Error: `go: module not found`
**Fix:**
```bash
cd backend
go mod tidy
```

### Error: `flutter pub get` fails
**Fix:**
```bash
flutter clean
flutter pub get
```

### Flutter app shows blank/white screen
**Fix:** Check that the backend is running on port 8080

### Error: "Admin access required"
**Cause:** You're logged in as a regular user trying to access admin routes
**Fix:** Log in with the admin account or promote your account:
```bash
psql -U postgres -d userapp -c "UPDATE users SET role='admin' WHERE email='your@email.com';"
```

---

## 🔒 PART 7: Security Features Explained

### Password Hashing
Passwords are NEVER stored as plain text. They're hashed using **bcrypt** (industry standard). Even if someone steals your database, they can't read passwords.

### JWT Tokens
After login, the server gives you a **JWT token** (like a digital ID card). Every API request sends this token. The server verifies it's real and not expired (tokens expire after 24 hours).

### Confirm Password Validation
- ✅ Validated on the **Flutter frontend** (instant feedback as you type)
- ✅ Validated again on the **Go backend** (security layer — can't bypass frontend)

### Role-Based Access Control
- **Users** can only see their own profile and dashboard
- **Admins** can manage all users
- The backend checks the role on every admin request

### Activity Logging
Every important action (login, register, profile update, password change) is logged with:
- Who did it (user ID)
- What they did (action type)
- When (timestamp)
- From where (IP address)

---

## 🚀 PART 8: Running Both Together (Quick Reference)

Every time you want to use the app:

**Terminal 1 — Start Backend:**
```bash
cd ~/myproject/backend
go run main.go
```

**Terminal 2 — Start Flutter:**
```bash
cd ~/myproject/frontend
flutter run -d chrome
```

That's it! The app is live at the browser window that opens.

---

## 📦 PART 9: Building for Production

### Build Flutter Web App:
```bash
cd frontend
flutter build web
# Output is in: build/web/
```

### Build Go Backend Binary:
```bash
cd backend
go build -o server main.go
./server   # Run the compiled binary
```

### Important Before Production:
1. Change `JWT_SECRET` in `.env` to a long random string
2. Use a real PostgreSQL server (not localhost)
3. Set `sslmode=require` in `DATABASE_URL`
4. Put your backend behind a reverse proxy (nginx)
5. Use HTTPS for all connections

---

## 💡 Tips for Beginners

1. **Always start the backend before the frontend**
2. **Use VS Code** — it highlights errors as you type
3. **Hot Reload** in Flutter: Press `r` in the terminal while flutter is running to reload changes instantly
4. **View database**: Use **pgAdmin** (comes with PostgreSQL) to browse your tables visually
5. **View API logs**: The Go terminal shows every request — useful for debugging
6. **CORS errors**: If you see CORS errors in browser, it means the backend isn't running

---

*Built with Flutter • Go • PostgreSQL*
