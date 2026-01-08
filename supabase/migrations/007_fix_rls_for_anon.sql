-- =====================================================
-- FIX RLS POLICIES - ALLOW ANON ACCESS
-- The app needs to query user profiles during login
-- Before the session is fully authenticated
-- =====================================================

-- Drop the authenticated-only policy
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.users;

-- Create policy that allows both anon and authenticated roles
-- Since usernames are not sensitive (they're like YLES-001, YLES-002, etc.)
-- and we need them for leaderboards anyway
CREATE POLICY "Anyone can view user profiles"
  ON public.users FOR SELECT
  USING (true);

-- Verify the policy
SELECT
  'Current policies on public.users:' as info,
  policyname,
  roles
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users';

DO $$
BEGIN
  RAISE NOTICE '✅ RLS policies updated to allow anon access!';
  RAISE NOTICE '👉 Both anon and authenticated users can now view profiles.';
END $$;
