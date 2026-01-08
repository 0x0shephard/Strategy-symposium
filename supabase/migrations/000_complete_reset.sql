-- =====================================================
-- COMPLETE DATABASE RESET
-- WARNING: This deletes EVERYTHING
-- =====================================================

-- 1. Drop all triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Drop all functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS calculate_new_valuation(UUID, UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS submit_player_choice(UUID, UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS advance_scenario(UUID) CASCADE;
DROP FUNCTION IF EXISTS start_game(UUID) CASCADE;
DROP FUNCTION IF EXISTS create_user_with_password(TEXT, TEXT, TEXT, user_role) CASCADE;

-- 3. Drop all tables (CASCADE will drop foreign keys)
DROP TABLE IF EXISTS public.game_state CASCADE;
DROP TABLE IF EXISTS public.player_choices CASCADE;
DROP TABLE IF EXISTS public.game_participants CASCADE;
DROP TABLE IF EXISTS public.options CASCADE;
DROP TABLE IF EXISTS public.scenarios CASCADE;
DROP TABLE IF EXISTS public.games CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 4. Delete all users from auth.users
DELETE FROM auth.users WHERE email LIKE '%@racetounicorn.local';
DELETE FROM auth.users WHERE email LIKE '%@investo.local';

-- 5. Drop enum types
DROP TYPE IF EXISTS game_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- 6. Verify everything is clean
SELECT 'Tables in public schema:' as check_name, COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

SELECT 'Users in auth.users:' as check_name, COUNT(*) as count
FROM auth.users;

DO $$
BEGIN
  RAISE NOTICE '✅ Complete reset done!';
  RAISE NOTICE '👉 Now run migrations in order:';
  RAISE NOTICE '   1. 001_initial_schema.sql';
  RAISE NOTICE '   2. 002_bulk_create_users.sql';
END $$;
