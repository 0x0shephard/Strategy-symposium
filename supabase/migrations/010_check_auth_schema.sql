-- =====================================================
-- CHECK AUTH SCHEMA HEALTH
-- Diagnose issues with Supabase Auth
-- =====================================================

-- 1. Check if auth schema exists
SELECT 'Auth schema exists:' as check_name,
       EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') as exists;

-- 2. List all tables in auth schema
SELECT 'Tables in auth schema:' as check_name, table_name
FROM information_schema.tables
WHERE table_schema = 'auth'
ORDER BY table_name;

-- 3. Check auth.users table structure
SELECT 'auth.users columns:' as check_name,
       column_name,
       data_type,
       is_nullable
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;

-- 4. Check for triggers on auth.users
SELECT 'Triggers on auth.users:' as check_name,
       trigger_name,
       event_manipulation,
       action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'auth' AND event_object_table = 'users';

-- 5. Check for constraints
SELECT 'Constraints on auth.users:' as check_name,
       constraint_name,
       constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'auth' AND table_name = 'users';

-- 6. Check if we can read from auth.users
SELECT 'Can query auth.users:' as check_name, COUNT(*) as user_count
FROM auth.users;

-- 7. Check auth schema permissions
SELECT 'Auth schema owner:' as check_name, schema_owner
FROM information_schema.schemata
WHERE schema_name = 'auth';

DO $$
BEGIN
  RAISE NOTICE '✅ Auth schema diagnostic complete.';
  RAISE NOTICE '👉 Review the results above to find issues.';
END $$;
