-- =====================================================
-- TEST RLS POLICIES
-- Run this to check if policies are configured correctly
-- =====================================================

-- Show all policies on public.users
SELECT
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users';

-- Test: Can we query users as anon?
SET ROLE anon;
SELECT 'Query as anon role:' as test, COUNT(*) as count FROM public.users;
RESET ROLE;

-- Test: Check if authenticated role can query
-- (Note: This won't work in SQL editor, but shows the policy exists)
SELECT
  'Policies allowing authenticated role:' as test,
  COUNT(*) as count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users'
  AND 'authenticated' = ANY(roles);

DO $$
BEGIN
  RAISE NOTICE '✅ RLS policy test complete. Check results above.';
END $$;
