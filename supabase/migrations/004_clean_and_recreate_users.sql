-- =====================================================
-- CLEAN AND RECREATE ALL USERS
-- Deletes all existing users and recreates them fresh
-- This ensures triggers fire properly
-- =====================================================

-- 1. Delete all existing users (this cascades to public.users)
DELETE FROM auth.users WHERE email LIKE '%@racetounicorn.local';

-- 2. Verify they're gone
SELECT 'Auth users remaining:' as check_name, COUNT(*) as count
FROM auth.users WHERE email LIKE '%@racetounicorn.local';

SELECT 'Public users remaining:' as check_name, COUNT(*) as count
FROM public.users;

-- 3. Wait a moment for cascade to complete
SELECT pg_sleep(1);

-- Done - now run 002_bulk_create_users.sql to recreate all users
DO $$
BEGIN
  RAISE NOTICE '✅ All users deleted.';
  RAISE NOTICE '👉 Now run 002_bulk_create_users.sql to recreate them.';
END $$;
