-- =====================================================
-- DIAGNOSE AUTH.USERS TABLE
-- Check what's actually in the table
-- =====================================================

-- 1. Get the actual instance_id from Supabase
SELECT DISTINCT 'Instance ID from existing auth:' as info, instance_id
FROM auth.users
LIMIT 1;

-- 2. Check if any users exist
SELECT 'Total users in auth.users:' as info, COUNT(*) as count
FROM auth.users;

-- 3. Check our created users
SELECT
  'Sample user from our import:' as info,
  id,
  instance_id,
  email,
  encrypted_password IS NOT NULL as has_password,
  email_confirmed_at IS NOT NULL as email_confirmed,
  aud,
  role,
  raw_user_meta_data
FROM auth.users
WHERE email = 'yles-001@racetounicorn.local'
LIMIT 1;

-- 4. Check all required columns
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;

-- 5. Compare with a properly created user (if any exist)
SELECT
  'Comparing field presence:' as info,
  COUNT(*) as total_users,
  COUNT(encrypted_password) as has_encrypted_password,
  COUNT(confirmation_token) as has_confirmation_token,
  COUNT(recovery_token) as has_recovery_token,
  COUNT(email_change_token_new) as has_email_change_token
FROM auth.users
WHERE email LIKE '%@racetounicorn.local';

DO $$
BEGIN
  RAISE NOTICE '✅ Diagnostic complete. Check results above.';
END $$;
