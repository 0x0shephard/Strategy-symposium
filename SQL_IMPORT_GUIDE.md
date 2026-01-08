# SQL User Import Guide

## Overview

I've created a SQL script that creates all 300 users directly in the database. This is the **recommended** approach since the Auth API import was failing.

## Files Created

1. **`supabase/migrations/002_bulk_create_users.sql`** - Complete SQL script with all 300 users
2. **`scripts/generate-sql-migration.py`** - Python script that generated the SQL (for reference)

## How to Use

### Step 1: Run the Initial Migration (if not done)

Go to Supabase SQL Editor and run:
```
supabase/migrations/001_initial_schema.sql
```

### Step 2: Run the User Creation Script

1. Open your Supabase project: https://amjbqilkjkeihaaawkpr.supabase.co
2. Go to: **SQL Editor**
3. Click **New Query**
4. Copy the entire contents of: **`supabase/migrations/002_bulk_create_users.sql`**
5. Paste into the query editor
6. Click **Run** (or press Cmd/Ctrl + Enter)

### What Happens

The script will:
- ✅ Create all 300 users in `auth.users` table
- ✅ Hash all passwords securely using bcrypt
- ✅ Set YLES-001 and YLES-300 as **admin** role
- ✅ Set YLES-002 through YLES-299 as **player** role
- ✅ Trigger will automatically create profiles in `public.users` table
- ✅ Display verification results

### Expected Output

You should see:
```
NOTICE: Successfully created all 300 users!
```

Plus a table showing:
```
role   | count
-------+-------
admin  | 2
player | 298
```

## Verify Users Were Created

Run this query:
```sql
SELECT role, COUNT(*) as count
FROM public.users
GROUP BY role
ORDER BY role;
```

Expected result:
- **admin**: 2
- **player**: 298

## Login Credentials

### Admin Accounts

| Username | Password |
|----------|----------|
| YLES-001 | Yagm0yHecHh0 |
| YLES-300 | Ig2Ax2wCF5M3 |

### Player Accounts

All credentials are in `scripts/credentials.csv` (run `npm run export-credentials` to generate)

## Troubleshooting

### Error: "relation auth.users does not exist"

You need to run migration 001 first (the initial schema).

### Users created in auth.users but not in public.users

Check that the trigger exists:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

If missing, the trigger was in migration 001. Re-run it or manually create profiles:
```sql
INSERT INTO public.users (id, username, role)
SELECT
  id,
  raw_user_meta_data->>'username' as username,
  (raw_user_meta_data->>'role')::user_role as role
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users);
```

### Password hashing error

The script requires the `pgcrypto` extension. It's created automatically in the script, but verify with:
```sql
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';
```

## After Import

1. **Test login** as YLES-001:
   - Username: `YLES-001`
   - Password: `Yagm0yHecHh0`

2. **Export credentials** for distribution:
   ```bash
   npm run export-credentials
   ```
   This creates `scripts/credentials.csv` with all usernames and passwords.

3. **Run the app**:
   ```bash
   npm run dev
   ```

## Clean Up (After Event)

To remove all users:
```sql
DELETE FROM auth.users WHERE email LIKE '%@investo.local';
```

This cascades to the `public.users` table.

## Why SQL Instead of API?

The Supabase Auth Admin API was returning a 500 error. The SQL approach:
- ✅ Works reliably
- ✅ Faster (creates all 300 users in seconds)
- ✅ Direct database access
- ✅ Better for bulk operations
- ✅ No rate limiting issues

## Summary

You're now ready to:
1. ✅ Run `002_bulk_create_users.sql` in Supabase SQL Editor
2. ✅ Verify 300 users created (2 admins, 298 players)
3. ✅ Login as YLES-001 or YLES-300
4. ✅ Start creating games!

**Next step:** Copy and run `supabase/migrations/002_bulk_create_users.sql` in your Supabase SQL Editor!
