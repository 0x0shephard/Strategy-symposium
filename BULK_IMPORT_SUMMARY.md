# Bulk User Import - Summary

I've created scripts to automatically import all 300 pre-assigned user credentials into your Supabase database!

## What's Been Added

### 📁 New Files

1. **`scripts/users.json`**
   - Contains all 300 pre-assigned credentials
   - Username: YLES-001 through YLES-300
   - Emails: yles-001@investo.local through yles-300@investo.local
   - Pre-generated passwords

2. **`scripts/import-users.js`**
   - Bulk import script using Supabase Admin API
   - Automatically sets YLES-001 and YLES-300 as admin
   - All others become players
   - Shows progress and handles errors

3. **`scripts/export-credentials.js`**
   - Exports credentials to CSV format
   - Creates `credentials.csv` with all 300 users
   - Creates `credentials-admin.csv` with just admin accounts
   - Easy to distribute to participants

4. **`scripts/README.md`**
   - Detailed documentation
   - Troubleshooting guide
   - Verification queries

### ⚙️ Updated Files

1. **`package.json`**
   - Added `npm run import-users` command
   - Added `npm run export-credentials` command

2. **`.env`**
   - Added `SUPABASE_SERVICE_ROLE_KEY` for admin operations

3. **`SETUP_GUIDE.md`**
   - Updated with bulk import as recommended method
   - Much simpler setup process now!

## How to Use

### 1. Run Database Migration (if not done)

```bash
# Copy and run supabase/migrations/001_initial_schema.sql in Supabase SQL Editor
```

### 2. Import All 300 Users

```bash
npm run import-users
```

**Expected output:**
```
🚀 Starting bulk user import: 300 users

✅ [1/300] 👑 Created YLES-001 (admin)
✅ [2/300] 👤 Created YLES-002 (player)
...
✅ [300/300] 👑 Created YLES-300 (admin)

============================================================
📊 IMPORT SUMMARY
============================================================
✅ Successfully created: 300 users
⏭️  Skipped (already exist): 0 users
❌ Failed: 0 users
📈 Total processed: 300/300
============================================================

🔍 Verifying admin users...

👑 YLES-001: Admin role confirmed
👑 YLES-300: Admin role confirmed

✨ User import completed!
```

### 3. Export Credentials (Optional)

```bash
npm run export-credentials
```

This creates:
- `scripts/credentials.csv` - All 300 users
- `scripts/credentials-admin.csv` - Just the 2 admins

## User Credentials

### Admin Accounts (2 total)

| Username | Email | Password | Role |
|----------|-------|----------|------|
| YLES-001 | yles-001@investo.local | Yagm0yHecHh0 | Admin |
| YLES-300 | yles-300@investo.local | Ig2Ax2wCF5M3 | Admin |

### Player Accounts (298 total)

- YLES-002 through YLES-299
- Passwords in `scripts/users.json` or `scripts/credentials.csv`

## Login Instructions for Participants

Users login with their **USERNAME** (not email):

1. Go to the app URL
2. Enter username: `YLES-XXX` (e.g., YLES-002)
3. Enter password (from credentials sheet)
4. Click Sign In

**Note:** The app converts usernames to email format internally (`YLES-002` → `yles-002@investo.local`), but users only need to enter their username.

## Verification

Check that users were created correctly:

```sql
-- Count by role
SELECT role, COUNT(*)
FROM public.users
GROUP BY role;

-- Expected:
-- admin  | 2
-- player | 298
```

View admin accounts:

```sql
SELECT username, email, role
FROM public.users
WHERE role = 'admin'
ORDER BY username;
```

## Security Notes

1. **Keep credentials secure**: The `users.json` and CSV files contain plaintext passwords
2. **Don't commit to Git**: These files are already in `.gitignore`
3. **Delete CSVs after distribution**: Once you've distributed credentials, delete the CSV files
4. **Service role key**: The `.env` file now contains your service role key - keep it private!

## Troubleshooting

### Import script fails with "rate limiting"

The script includes automatic delays (1 second per 10 users). If you still hit rate limits, you can:
- Re-run the script (it skips existing users)
- Increase the delay in `import-users.js`

### Users not in public.users table

Check that the database trigger `on_auth_user_created` exists and is active:

```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

### Admin role not set

Manually set admin role:

```sql
UPDATE public.users
SET role = 'admin'
WHERE username IN ('YLES-001', 'YLES-300');
```

## Clean Up (After Event)

To remove all imported users:

```sql
-- WARNING: This deletes all users with @investo.local emails!
DELETE FROM auth.users WHERE email LIKE '%@investo.local';
```

This cascades to the `public.users` table automatically.

## Summary

You now have:
- ✅ 300 pre-created user accounts
- ✅ 2 admin accounts (YLES-001, YLES-300)
- ✅ 298 player accounts (YLES-002 to YLES-299)
- ✅ CSV files for credential distribution
- ✅ Automated import/export scripts
- ✅ Ready to start your game!

**Next step:** Run the app (`npm run dev`) and login as YLES-001 to create your first game!
