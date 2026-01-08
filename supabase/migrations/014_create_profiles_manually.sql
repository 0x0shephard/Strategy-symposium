-- =====================================================
-- MANUALLY CREATE USER PROFILES
-- Creates public.users entries for all auth.users
-- =====================================================

-- Delete the test user we created
DELETE FROM auth.users WHERE email = 'test@test.com';

-- Create profiles for all users from auth.users
INSERT INTO public.users (id, username, role)
SELECT
  id,
  COALESCE(raw_user_meta_data->>'username', split_part(email, '@', 1)) as username,
  COALESCE((raw_user_meta_data->>'role')::user_role, 'player'::user_role) as role
FROM auth.users
WHERE email LIKE '%@racetounicorn.app'
ON CONFLICT (id) DO NOTHING;

-- Verify the results
SELECT 'Users in public.users:' as check_name, COUNT(*) as count
FROM public.users;

SELECT 'Users by role:' as check_name, role, COUNT(*) as count
FROM public.users
GROUP BY role
ORDER BY role;

SELECT 'Admin users:' as check_name, username, role
FROM public.users
WHERE role = 'admin'
ORDER BY username;

DO $$
BEGIN
  RAISE NOTICE '✅ User profiles created!';
  RAISE NOTICE '👉 Check the results above.';
  RAISE NOTICE '👉 You should see 2 admins and 298 players.';
END $$;
