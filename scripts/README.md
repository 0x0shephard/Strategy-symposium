# User Import Scripts

This directory contains scripts to bulk import users into Supabase.

## Prerequisites

1. Ensure the database migration has been run (`supabase/migrations/001_initial_schema.sql`)
2. The database trigger `on_auth_user_created` must be active (automatically creates profiles in `public.users`)

## Files

- `users.json` - Contains 300 pre-generated user credentials
- `import-users.js` - Node.js script to bulk import users to Supabase

## Usage

### Run the Import Script

```bash
npm run import-users
```

This will:
1. Read all 300 users from `users.json`
2. Create each user in Supabase Auth
3. Set YLES-001 and YLES-300 as **admin** role
4. Set all other users (YLES-002 to YLES-299) as **player** role
5. Automatically create profiles in `public.users` table via database trigger
6. Skip users that already exist
7. Show progress and summary

### Expected Output

```
🚀 Starting bulk user import: 300 users

✅ [1/300] 👑 Created YLES-001 (admin)
✅ [2/300] 👤 Created YLES-002 (player)
✅ [3/300] 👤 Created YLES-003 (player)
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

## Credentials

After import, users can login with:

**Format:**
- Username: `YLES-XXX` (e.g., YLES-001, YLES-002)
- Email: `yles-xxx@investo.local`
- Password: (see `users.json`)

**Admin Accounts:**
- YLES-001 / Password: `Yagm0yHecHh0`
- YLES-300 / Password: `Ig2Ax2wCF5M3`

**Player Accounts:**
- YLES-002 through YLES-299 (passwords in `users.json`)

## Troubleshooting

### Users not appearing in public.users table

If users are created in auth.users but not in public.users:

1. Check that the trigger exists:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

2. Manually backfill if needed:
```sql
INSERT INTO public.users (id, username, role)
SELECT
  id,
  raw_user_meta_data->>'username' as username,
  COALESCE((raw_user_meta_data->>'role')::user_role, 'player') as role
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users);
```

### Admin role not set

If YLES-001 or YLES-300 don't have admin role:

```sql
UPDATE public.users
SET role = 'admin'
WHERE username IN ('YLES-001', 'YLES-300');
```

### Rate limiting errors

If you encounter rate limiting:
- The script includes automatic delays (1 second every 10 users)
- You can increase the delay in `import-users.js` if needed

### Import failed midway

The script skips existing users, so you can safely re-run it to continue from where it failed.

## Verifying Import

Check how many users were created:

```sql
-- Count by role
SELECT role, COUNT(*)
FROM public.users
GROUP BY role;

-- Expected output:
-- admin    | 2
-- player   | 298
```

List all admins:

```sql
SELECT username, role
FROM public.users
WHERE role = 'admin'
ORDER BY username;
```

## Security Note

The `users.json` file contains plaintext passwords. This is acceptable for a controlled event environment, but you should:

1. Keep this file secure and not commit it to public repositories
2. Consider rotating passwords after the event
3. Delete test accounts when no longer needed

## Clean Up (Optional)

To delete all imported users:

```sql
-- WARNING: This will delete all users!
DELETE FROM auth.users WHERE email LIKE '%@investo.local';
```

This will cascade delete from `public.users` as well.
