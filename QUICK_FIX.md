# 🚀 QUICK FIX ACTION PLAN

## The Problem (Confirmed)
Your PostgreSQL `users` table is missing the `start_date` and `end_date` columns (and many others). The backend code tries to update/fetch them, but PostgreSQL has nowhere to store them.

---

## ✅ Immediate Fix (Choose One)

### Option A: Update schema.sql and Recreate DB (Recommended for fresh start)

**Step 1: Update backend/schema.sql**

Add these columns to the `CREATE TABLE IF NOT EXISTS users (...)` section in `backend/schema.sql`:

```sql
-- Add after the existing columns, before the closing );

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

**Step 2: Stop your Go backend**
```bash
# In the go terminal, press Ctrl+C
```

**Step 3: Drop and recreate the database**
```sql
-- Open PostgreSQL command line (adjust connection as needed):
dropdb userapp;
createdb userapp;
```

**Step 4: Reimport the schema**
```bash
# In your terminal:
psql -d userapp -U postgres < backend/schema.sql
```

**Step 5: Restart the Go backend**
```bash
cd backend
go run main.go
```

The GORM AutoMigration will run and ensure everything is in sync.

---

### Option B: Add Columns to Existing Database (Preserves existing data)

If you have users you want to keep, run these SQL commands:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS school VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS program VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS specialization VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS year_level VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS intern_number VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS start_date VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS end_date VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS technical_skills TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS soft_skills TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS linked_in VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS git_hub VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS required_ojt_hours INTEGER DEFAULT 400;
```

Then restart the Go backend:
```bash
cd backend
go run main.go
```

---

## ✔️ Verification Checklist

After applying the fix:

1. **Check columns exist:**
   ```bash
   # In PostgreSQL:
   \d users
   # Look for: start_date, end_date, school, program, etc.
   ```

2. **Test the update endpoint:**
   - Go to Flutter app
   - Edit profile and enter start date and end date
   - Save
   - Refresh the app
   - **Expected:** Dates should appear, not "TBA"

3. **Alternative verification** (using curl):
   ```bash
   curl -X GET http://localhost:8080/api/profile \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   
   # Should return JSON with:
   # "start_date": "2024-05-14",
   # "end_date": "2024-08-14"
   ```

---

## 🎯 What This Fixes

✅ Dates will be stored in PostgreSQL  
✅ Dates will be returned in GET /profile responses  
✅ Flutter will receive the dates and display them instead of "TBA"  
✅ All profile fields (school, program, skills, etc.) will persist  

---

## ⚠️ If You Get Stuck

Review the comprehensive audit report: [DATA_FLOW_AUDIT_REPORT.md](DATA_FLOW_AUDIT_REPORT.md)

It contains:
- Detailed analysis of all 5 layers of your data flow
- Root cause explanation
- Full diagnostic steps
- Complete solution options
