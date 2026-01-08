-- =====================================================
-- TEMPORARILY DISABLE RLS ON USERS TABLE
-- For debugging purposes only
-- =====================================================

-- Disable RLS on users table
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Show current status
SELECT
  'RLS status for public.users:' as info,
  relname as table_name,
  relrowsecurity as rls_enabled
FROM pg_class
WHERE relname = 'users' AND relnamespace = 'public'::regnamespace;

DO $$
BEGIN
  RAISE NOTICE '⚠️  RLS DISABLED on public.users table!';
  RAISE NOTICE '👉 This is for debugging only. Try logging in now.';
  RAISE NOTICE '👉 If login works, the issue is with RLS policies.';
END $$;
