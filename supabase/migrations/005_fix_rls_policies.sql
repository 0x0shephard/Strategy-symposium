-- =====================================================
-- FIX RLS POLICIES FOR USER PROFILES
-- Allow authenticated users to view all profiles
-- (needed for login and leaderboards)
-- =====================================================

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;

-- Create more permissive policy for authenticated users
CREATE POLICY "Authenticated users can view all profiles"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

-- Keep the update policy restrictive (users can only update their own profile)
-- Policy already exists, no need to recreate

-- Verify policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

DO $$
BEGIN
  RAISE NOTICE '✅ RLS policies updated!';
  RAISE NOTICE '👉 Authenticated users can now view all profiles.';
END $$;
