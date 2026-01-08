-- =====================================================
-- VERIFICATION AND FIX SCRIPT
-- Checks auth.users and public.users sync
-- Creates missing profiles if needed
-- =====================================================

-- 1. Check how many users are in auth.users
SELECT 'Users in auth.users:' as check_name, COUNT(*) as count
FROM auth.users
WHERE email LIKE '%@racetounicorn.local';

-- 2. Check how many users are in public.users
SELECT 'Users in public.users:' as check_name, COUNT(*) as count
FROM public.users;

-- 3. Find users in auth.users but missing from public.users
SELECT 'Missing profiles:' as check_name, COUNT(*) as count
FROM auth.users au
WHERE email LIKE '%@racetounicorn.local'
  AND NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
  );

-- 4. Create missing profiles
INSERT INTO public.users (id, username, role)
SELECT
  au.id,
  (au.raw_user_meta_data->>'username') as username,
  ((au.raw_user_meta_data->>'role')::user_role) as role
FROM auth.users au
WHERE au.email LIKE '%@racetounicorn.local'
  AND NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
  )
ON CONFLICT (id) DO NOTHING;

-- 5. Verify admin users
SELECT 'Admin users:' as check_name, username, role
FROM public.users
WHERE role = 'admin'
ORDER BY username;

-- 6. Count by role
SELECT 'Users by role:' as check_name, role, COUNT(*) as count
FROM public.users
GROUP BY role
ORDER BY role;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Verification complete! Check results above.';
END $$;
