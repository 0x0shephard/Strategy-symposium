-- =====================================================
-- TEMPORARILY DISABLE TRIGGER FOR TESTING
-- =====================================================

-- Disable the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Verify it's gone
SELECT 'Triggers on auth.users:' as check_name, COUNT(*) as count
FROM information_schema.triggers
WHERE event_object_schema = 'auth' AND event_object_table = 'users';

DO $$
BEGIN
  RAISE NOTICE '✅ Trigger disabled!';
  RAISE NOTICE '👉 Try importing users now.';
  RAISE NOTICE '👉 We will manually create profiles after.';
END $$;
