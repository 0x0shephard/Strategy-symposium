-- =====================================================
-- EMERGENCY FIX - DISABLE TRIGGER AND TEST
-- =====================================================

-- Drop the problematic trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Temporarily disable RLS on public.users
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

SELECT 'Emergency fix applied' as status;

DO $$
BEGIN
  RAISE NOTICE '✅ Trigger removed!';
  RAISE NOTICE '👉 Try creating a user in the Dashboard now.';
  RAISE NOTICE '👉 If it works, the trigger was the problem.';
END $$;
