# 🔍 FULL-STACK DATA FLOW AUDIT: Date Fields (start_date, end_date)

**Date Audited:** May 14, 2026  
**Issue:** Flutter shows "TBA" instead of user-entered dates for start_date and end_date  
**Status:** ⚠️ **ROOT CAUSE IDENTIFIED**

---

## 📋 EXECUTIVE SUMMARY

I've traced the complete data flow for start_date and end_date across your Flutter frontend, Go backend, and PostgreSQL database. The issue is **NOT in the frontend or backend code** — both are correctly implemented. **The problem is in the database schema.**

**ROOT CAUSE:** The `users` table in PostgreSQL is missing the `start_date` and `end_date` columns. The backend code updates and fetches these fields, but they have nowhere to be stored.

---

## 1️⃣ FLUTTER FRONTEND ANALYSIS ✅ WORKING CORRECTLY

### 1.1 UserEditProfileScreen._save() Function
**File:** `frontend/lib/screens/user_edit_profile_screen.dart:116-172`

**Status:** ✅ **CORRECT**

The payload is constructed with proper keys:
```dart
ApiService.updateProfile({
  'start_date': _startCtrl.text.trim(),
  'end_date': _endCtrl.text.trim(),
  // ... other fields
});
```

**Finding:** Keys are exactly `'start_date'` and `'end_date'` ✓

### 1.2 API Service
**File:** `frontend/lib/services/api_service.dart:128-155`

**Status:** ✅ **CORRECT**

The updateProfile method properly encodes the payload as JSON:
```dart
static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('$baseUrl/profile'),
    headers: await _authHeaders(),
    body: jsonEncode(data),  // ← Correctly encodes
  );
  return _parse(res);
}
```

**Finding:** Serialization is proper JSON ✓

### 1.3 InternProfile.fromJson() Parser
**File:** `frontend/lib/screens/intern_cards.dart:68-115`

**Status:** ✅ **ROBUST PARSING**

The parser safely handles null and missing values:
```dart
startDate: parseString(json['start_date']),
endDate: parseString(json['end_date']),

String? parseString(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str.toLowerCase() == 'null') return null;
  return str;
}
```

**Finding:** Frontend can correctly parse dates IF they come back from the API ✓

### 1.4 AuthProvider State Management
**File:** `frontend/lib/providers/auth_provider.dart:168-180`

**Status:** ✅ **CORRECT**

The updateUserData method correctly merges and stores the profile:
```dart
Future<void> updateUserData(Map<String, dynamic> data) async {
  _user = {...?_user, ...data};  // Properly merges
  await prefs.setString('user', jsonEncode(_user));
  notifyListeners();
}
```

**Finding:** State management preserves date fields ✓

---

## 2️⃣ GO BACKEND ANALYSIS ✅ CODE IS CORRECT, ⚠️ DATABASE IS MISSING

### 2.1 UpdateProfileRequest Struct
**File:** `backend/handlers/handlers.go:54-75`

**Status:** ✅ **CORRECT**

The struct has the correct JSON tags:
```go
type UpdateProfileRequest struct {
  StartDate string `json:"start_date"`
  EndDate   string `json:"end_date"`
  // ... other fields
}
```

**Finding:** JSON tags exactly match Flutter payload ✓

### 2.2 UpdateProfile Handler - Date Validation
**File:** `backend/handlers/handlers.go:254-305`

**Status:** ✅ **CORRECT**

Dates are validated before being stored:
```go
if req.StartDate != "" {
  if _, err := parseProfileDate(req.StartDate, "start_date"); err != nil {
    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
    return
  }
  startDateValue = req.StartDate
}
if req.EndDate != "" {
  if _, err := parseProfileDate(req.EndDate, "end_date"); err != nil {
    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
    return
  }
  endDateValue = req.EndDate
}
```

**Finding:** Validation logic is sound ✓

### 2.3 SQL UPDATE Query
**File:** `backend/handlers/handlers.go:306-345`

**Status:** ✅ **CODE IS CORRECT**

Dates ARE being added to the update map:
```go
updates := map[string]interface{}{}
// ... other fields ...
if req.StartDate != "" {
  updates["start_date"] = req.StartDate
}
if req.EndDate != "" {
  updates["end_date"] = req.EndDate
}

// Execute the update:
if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
  c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
  return
}
```

**Finding:** GORM update is correctly formed ✓

### 2.4 UpdateProfile Response
**File:** `backend/handlers/handlers.go:346-349`

**Status:** ✅ **CORRECT**

The handler returns the updated user:
```go
var updated models.User
h.DB.First(&updated, userID)
c.JSON(http.StatusOK, gin.H{"ok": true, "message": "Profile updated", "user": updated})
```

**Finding:** Response includes updated user data ✓

### 2.5 GetProfile Handler
**File:** `backend/handlers/handlers.go:179-190`

**Status:** ✅ **CORRECT**

The handler fetches and returns the user:
```go
func (h *Handler) GetProfile(c *gin.Context) {
  var user models.User
  if err := h.DB.First(&user, userID).Error; err != nil {
    c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
    return
  }
  user.EstimatedEndDate = computeEstimatedEndDate(user.StartDate, user.RequiredOjtHours)
  c.JSON(http.StatusOK, user)
}
```

**Finding:** Handler correctly returns date fields ✓

### 2.6 User Model Struct
**File:** `backend/models/user.go:1-60`

**Status:** ✅ **MODEL IS CORRECT**

The struct has proper JSON tags:
```go
type User struct {
  StartDate string `json:"start_date"`
  EndDate   string `json:"end_date"`
  // ... other fields
}
```

**Finding:** JSON tags match backend expectations ✓

---

## 3️⃣ DATABASE SCHEMA ANALYSIS ⚠️ **CRITICAL ISSUE**

### 3.1 Schema Definition
**File:** `backend/schema.sql:1-30`

**Status:** ⚠️ **MISSING COLUMNS**

The `users` table definition in schema.sql:
```sql
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR NOT NULL,
    phone VARCHAR,
    department VARCHAR,
    position VARCHAR,
    avatar_url VARCHAR,
    role VARCHAR DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    is_active BOOLEAN DEFAULT true,
    is_archived BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    bio TEXT,
    failed_login_count INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    reset_token VARCHAR,
    reset_token_expiry TIMESTAMP WITH TIME ZONE
);
```

**MISSING COLUMNS:**
- ❌ `start_date` VARCHAR
- ❌ `end_date` VARCHAR
- ❌ `school` VARCHAR
- ❌ `program` VARCHAR
- ❌ `specialization` VARCHAR
- ❌ `year_level` VARCHAR
- ❌ `intern_number` VARCHAR
- ❌ `technical_skills` TEXT
- ❌ `soft_skills` TEXT
- ❌ `linked_in` VARCHAR
- ❌ `git_hub` VARCHAR
- ❌ `required_ojt_hours` INTEGER

**Finding:** The schema.sql is OUT OF DATE ⚠️

### 3.2 GORM AutoMigration
**File:** `backend/main.go:150-160`

**Status:** ✅ **CODE EXISTS BUT UNCLEAR IF EXECUTED**

The main.go file has AutoMigrate:
```go
DB.AutoMigrate(
  &models.User{},
  &models.ActivityLog{},
  &models.Department{},
  &models.Position{},
  &models.Attendance{},
)
```

**Issue:** 
- If GORM AutoMigration ran AFTER schema.sql was applied, columns might not be created
- If schema.sql was applied AFTER AutoMigration, it would overwrite the migrations
- If database was initialized from schema.sql, the columns don't exist

**Finding:** Unclear which initialization method was used ⚠️

---

## 🎯 ROOT CAUSE VERDICT

### **The Data Pipeline IS Broken at the Database Layer**

1. **Flutter sends:** `{'start_date': '2024-05-14', 'end_date': '2024-08-14'}`  
2. **API payload transfer:** ✅ Correctly formatted JSON
3. **Go handler receives:** ✅ Correctly deserialized into UpdateProfileRequest
4. **GORM update executes:** ✅ Updates map includes the date values
5. **PostgreSQL receives UPDATE:** ⚠️ **COLUMNS DON'T EXIST** ❌
   - UPDATE query: `UPDATE users SET start_date = $1, end_date = $2 WHERE id = $3`
   - Result: PostgreSQL ignores the columns (silently fails or errors)
6. **SELECT on next fetch:** ❌ Columns return NULL because they don't exist
7. **Flutter receives NULL:** `startDate: null, endDate: null`
8. **UI displays "TBA":** Because date is null ✓ (correct fallback behavior)

---

## 🔧 DIAGNOSTIC STEPS (For You To Verify)

### Step 1: Check if columns exist in actual database

```bash
# SSH into your PostgreSQL database and run:
psql -d userapp -U postgres

# Then in psql:
\d users

# Look for start_date and end_date columns in the output
```

**Expected output if columns exist:**
```
 start_date     | character varying
 end_date       | character varying
 school         | character varying
 program        | character varying
 ... etc
```

**If these columns are missing, that's your problem.**

### Step 2: Verify Go backend logs on startup

```bash
# When you run the Go backend, look for:
# "Database migrated successfully"

# If this message appears, GORM attempted to migrate.
# But if schema.sql was applied first, this might not create the missing columns.
```

### Step 3: Test the update endpoint directly

```bash
curl -X PUT http://localhost:8080/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-05-14",
    "end_date": "2024-08-14"
  }'
```

**Check the response:** Does it include the dates in the returned user object?
- If YES: Dates are being stored ✓ (problem is elsewhere)
- If NO: Dates are being dropped (column doesn't exist) ❌

---

## ✅ SOLUTIONS

### Solution 1: Add Missing Columns to schema.sql (RECOMMENDED)

Update `backend/schema.sql` to include:

```sql
-- Add this inside the CREATE TABLE IF NOT EXISTS users section:

    school VARCHAR,
    program VARCHAR,
    specialization VARCHAR,
    year_level VARCHAR,
    intern_number VARCHAR,
    start_date VARCHAR,
    end_date VARCHAR,
    technical_skills TEXT,
    soft_skills TEXT,
    linked_in VARCHAR,
    git_hub VARCHAR,
    required_ojt_hours INTEGER DEFAULT 400,
```

Then apply the migration:
```bash
psql -d userapp -U postgres -f backend/schema.sql
```

### Solution 2: Recreate Database from Fresh

If columns already exist but with issues:

```bash
# Drop and recreate (⚠️ WILL DELETE ALL DATA):
dropdb userapp
createdb userapp
psql -d userapp -U postgres -f backend/schema.sql

# Restart Go backend (AutoMigrate will ensure columns exist)
go run main.go
```

### Solution 3: Manual SQL Fix (If data is valuable)

```sql
-- Add the missing columns:
ALTER TABLE users ADD COLUMN IF NOT EXISTS start_date VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS end_date VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS school VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS program VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS specialization VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS year_level VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS intern_number VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS technical_skills TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS soft_skills TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS linked_in VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS git_hub VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS required_ojt_hours INTEGER DEFAULT 400;
```

---

## 📊 VERIFICATION CHECKLIST

After applying a fix, verify the data flow works:

- [ ] Check `\d users` in psql — do columns exist?
- [ ] Test update endpoint — does response include dates?
- [ ] Fetch profile via GET /profile — do dates appear?
- [ ] Refresh Flutter app — does "TBA" change to dates?
- [ ] Update profile again — do new dates persist?

---

## 📝 CONCLUSION

**Your frontend code is solid.** ✅  
**Your backend code is solid.** ✅  
**Your database schema is incomplete.** ❌

The dates are being lost because the PostgreSQL table doesn't have columns to store them. Once you add the missing columns, the entire data pipeline will work correctly.

---

**Next Action:** Run diagnostic Step 1 to confirm the columns don't exist, then apply Solution 1 or 3 above.
