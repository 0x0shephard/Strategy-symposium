-- =====================================================
-- CREATE SAFE TRIGGER FOR FUTURE USERS
-- Uses exception handling to not break auth
-- =====================================================

-- Create a safe trigger function that won't break user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Try to insert, but if it fails, don't stop the user creation
  BEGIN
    INSERT INTO public.users (id, username, role)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
      COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'player'::user_role)
    );
  EXCEPTION
    WHEN OTHERS THEN
      -- Just log it, don't fail the auth.users insert
      RAISE WARNING 'Could not create profile for user %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Re-enable RLS with proper policy
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policy and create a simple one
DROP POLICY IF EXISTS "Anyone can view user profiles" ON public.users;
CREATE POLICY "Anyone can view user profiles"
  ON public.users FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

DO $$
BEGIN
  RAISE NOTICE '✅ Safe trigger created and RLS re-enabled!';
  RAISE NOTICE '👉 Future users will auto-create profiles.';
END $$;
