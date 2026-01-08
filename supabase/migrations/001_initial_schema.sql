-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types (with existence checks)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('admin', 'player');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'game_status') THEN
    CREATE TYPE game_status AS ENUM ('draft', 'active', 'completed');
  END IF;
END $$;

-- 1. Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'player',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Games table
CREATE TABLE IF NOT EXISTS public.games (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  starting_valuation DECIMAL DEFAULT 320000000,
  target_valuation DECIMAL DEFAULT 1000000000,
  status game_status DEFAULT 'draft',
  created_by UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Scenarios table
CREATE TABLE IF NOT EXISTS public.scenarios (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE NOT NULL,
  scenario_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(game_id, scenario_number)
);

-- 4. Options table
CREATE TABLE IF NOT EXISTS public.options (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  scenario_id UUID REFERENCES public.scenarios(id) ON DELETE CASCADE NOT NULL,
  option_number INTEGER NOT NULL CHECK (option_number BETWEEN 1 AND 5),
  rgm DECIMAL NOT NULL,
  mre DECIMAL NOT NULL,
  ues DECIMAL NOT NULL,
  crq DECIMAL NOT NULL,
  rga DECIMAL NOT NULL,
  cem DECIMAL NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(scenario_id, option_number)
);

-- 5. Game participants table
CREATE TABLE IF NOT EXISTS public.game_participants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  current_valuation DECIMAL DEFAULT 320000000,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(game_id, user_id)
);

-- 6. Player choices table
CREATE TABLE IF NOT EXISTS public.player_choices (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  scenario_id UUID REFERENCES public.scenarios(id) ON DELETE CASCADE NOT NULL,
  option_id UUID REFERENCES public.options(id) ON DELETE CASCADE NOT NULL,
  valuation_before DECIMAL NOT NULL,
  valuation_after DECIMAL NOT NULL,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(game_id, user_id, scenario_id)
);

-- 7. Game state table
CREATE TABLE IF NOT EXISTS public.game_state (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE UNIQUE NOT NULL,
  current_scenario_id UUID REFERENCES public.scenarios(id) ON DELETE CASCADE,
  scenario_started_at TIMESTAMP WITH TIME ZONE,
  scenario_ends_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Drop all existing policies first (for idempotency)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname
              FROM pg_policies
              WHERE schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename);
    END LOOP;
END $$;

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_state ENABLE ROW LEVEL SECURITY;

-- Users policies
-- Allow both anon and authenticated to view profiles (needed for login and leaderboards)
CREATE POLICY "Anyone can view user profiles"
  ON public.users FOR SELECT
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Games policies
CREATE POLICY "Anyone can view active or completed games"
  ON public.games FOR SELECT
  USING (status IN ('active', 'completed') OR created_by = auth.uid());

CREATE POLICY "Admins can insert games"
  ON public.games FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update their own games"
  ON public.games FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "Admins can delete their own games"
  ON public.games FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
    AND created_by = auth.uid()
  );

-- Scenarios policies
CREATE POLICY "Anyone can view scenarios for accessible games"
  ON public.scenarios FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.games
      WHERE id = game_id AND (status IN ('active', 'completed') OR created_by = auth.uid())
    )
  );

CREATE POLICY "Admins can insert scenarios"
  ON public.scenarios FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.games g ON g.created_by = u.id
      WHERE u.id = auth.uid() AND u.role = 'admin' AND g.id = game_id
    )
  );

CREATE POLICY "Admins can update scenarios"
  ON public.scenarios FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.games g ON g.created_by = u.id
      WHERE u.id = auth.uid() AND u.role = 'admin' AND g.id = game_id
    )
  );

CREATE POLICY "Admins can delete scenarios"
  ON public.scenarios FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.games g ON g.created_by = u.id
      WHERE u.id = auth.uid() AND u.role = 'admin' AND g.id = game_id
    )
  );

-- Options policies
CREATE POLICY "Anyone can view options for accessible scenarios"
  ON public.options FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.scenarios s
      JOIN public.games g ON g.id = s.game_id
      WHERE s.id = scenario_id AND (g.status IN ('active', 'completed') OR g.created_by = auth.uid())
    )
  );

CREATE POLICY "Admins can insert options"
  ON public.options FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.scenarios s
      JOIN public.games g ON g.id = s.game_id
      JOIN public.users u ON u.id = g.created_by
      WHERE s.id = scenario_id AND u.id = auth.uid() AND u.role = 'admin'
    )
  );

CREATE POLICY "Admins can update options"
  ON public.options FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.scenarios s
      JOIN public.games g ON g.id = s.game_id
      JOIN public.users u ON u.id = g.created_by
      WHERE s.id = scenario_id AND u.id = auth.uid() AND u.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete options"
  ON public.options FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.scenarios s
      JOIN public.games g ON g.id = s.game_id
      JOIN public.users u ON u.id = g.created_by
      WHERE s.id = scenario_id AND u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Game participants policies
CREATE POLICY "Anyone can view participants for games they're in"
  ON public.game_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.games g
      WHERE g.id = game_id AND (
        g.status IN ('active', 'completed') OR
        g.created_by = auth.uid() OR
        user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Players can join active games"
  ON public.game_participants FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.games
      WHERE id = game_id AND status = 'active'
    )
  );

CREATE POLICY "System can update participants"
  ON public.game_participants FOR UPDATE
  USING (true);

-- Player choices policies
CREATE POLICY "Anyone can view choices for games they're in"
  ON public.player_choices FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = player_choices.game_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.games
      WHERE id = game_id AND created_by = auth.uid()
    )
  );

CREATE POLICY "Players can insert their own choices"
  ON public.player_choices FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = player_choices.game_id AND user_id = auth.uid()
    )
  );

-- Game state policies
CREATE POLICY "Anyone can view game state for accessible games"
  ON public.game_state FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.games g
      WHERE g.id = game_id AND (
        g.status IN ('active', 'completed') OR
        g.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.game_participants
          WHERE game_id = g.id AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Admins can manage game state"
  ON public.game_state FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.games g
      JOIN public.users u ON u.id = g.created_by
      WHERE g.id = game_id AND u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- =====================================================
-- DATABASE FUNCTIONS
-- =====================================================

-- Function to calculate new valuation
CREATE OR REPLACE FUNCTION calculate_new_valuation(
  p_user_id UUID,
  p_game_id UUID,
  p_option_id UUID
)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_valuation DECIMAL;
  v_rgm DECIMAL;
  v_mre DECIMAL;
  v_ues DECIMAL;
  v_crq DECIMAL;
  v_rga DECIMAL;
  v_cem DECIMAL;
  v_new_valuation DECIMAL;
BEGIN
  -- Get current valuation
  SELECT current_valuation INTO v_current_valuation
  FROM public.game_participants
  WHERE user_id = p_user_id AND game_id = p_game_id;

  -- Get option multipliers
  SELECT rgm, mre, ues, crq, rga, cem
  INTO v_rgm, v_mre, v_ues, v_crq, v_rga, v_cem
  FROM public.options
  WHERE id = p_option_id;

  -- Calculate new valuation
  v_new_valuation := v_current_valuation * v_rgm * v_mre * v_ues * v_crq * v_rga * v_cem;

  RETURN v_new_valuation;
END;
$$;

-- Function to submit player choice and update valuation
CREATE OR REPLACE FUNCTION submit_player_choice(
  p_user_id UUID,
  p_game_id UUID,
  p_scenario_id UUID,
  p_option_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_valuation_before DECIMAL;
  v_valuation_after DECIMAL;
  v_choice_id UUID;
BEGIN
  -- Get current valuation
  SELECT current_valuation INTO v_valuation_before
  FROM public.game_participants
  WHERE user_id = p_user_id AND game_id = p_game_id;

  -- Calculate new valuation
  v_valuation_after := calculate_new_valuation(p_user_id, p_game_id, p_option_id);

  -- Insert player choice
  INSERT INTO public.player_choices (game_id, user_id, scenario_id, option_id, valuation_before, valuation_after)
  VALUES (p_game_id, p_user_id, p_scenario_id, p_option_id, v_valuation_before, v_valuation_after)
  RETURNING id INTO v_choice_id;

  -- Update participant's current valuation
  UPDATE public.game_participants
  SET current_valuation = v_valuation_after
  WHERE user_id = p_user_id AND game_id = p_game_id;

  RETURN jsonb_build_object(
    'choice_id', v_choice_id,
    'valuation_before', v_valuation_before,
    'valuation_after', v_valuation_after
  );
END;
$$;

-- Function to advance to next scenario
CREATE OR REPLACE FUNCTION advance_scenario(p_game_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_scenario_number INTEGER;
  v_next_scenario_id UUID;
  v_duration_minutes INTEGER;
BEGIN
  -- Get current scenario number
  SELECT s.scenario_number INTO v_current_scenario_number
  FROM public.game_state gs
  JOIN public.scenarios s ON s.id = gs.current_scenario_id
  WHERE gs.game_id = p_game_id;

  -- Get next scenario
  SELECT id, duration_minutes INTO v_next_scenario_id, v_duration_minutes
  FROM public.scenarios
  WHERE game_id = p_game_id AND scenario_number = v_current_scenario_number + 1;

  -- If no next scenario, mark game as completed
  IF v_next_scenario_id IS NULL THEN
    UPDATE public.games
    SET status = 'completed'
    WHERE id = p_game_id;

    DELETE FROM public.game_state
    WHERE game_id = p_game_id;

    RETURN FALSE;
  END IF;

  -- Update game state to next scenario
  UPDATE public.game_state
  SET
    current_scenario_id = v_next_scenario_id,
    scenario_started_at = NOW(),
    scenario_ends_at = NOW() + (v_duration_minutes || ' minutes')::INTERVAL,
    updated_at = NOW()
  WHERE game_id = p_game_id;

  RETURN TRUE;
END;
$$;

-- Function to start a game
CREATE OR REPLACE FUNCTION start_game(p_game_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_first_scenario_id UUID;
  v_duration_minutes INTEGER;
BEGIN
  -- Get first scenario
  SELECT id, duration_minutes INTO v_first_scenario_id, v_duration_minutes
  FROM public.scenarios
  WHERE game_id = p_game_id AND scenario_number = 1;

  IF v_first_scenario_id IS NULL THEN
    RAISE EXCEPTION 'No scenarios found for this game';
  END IF;

  -- Update game status
  UPDATE public.games
  SET status = 'active'
  WHERE id = p_game_id;

  -- Create game state
  INSERT INTO public.game_state (game_id, current_scenario_id, scenario_started_at, scenario_ends_at)
  VALUES (
    p_game_id,
    v_first_scenario_id,
    NOW(),
    NOW() + (v_duration_minutes || ' minutes')::INTERVAL
  );

  RETURN TRUE;
END;
$$;

-- =====================================================
-- SEED DATA
-- =====================================================

-- Note: You'll need to create these users in Supabase Auth first, then run this update
-- The passwords should be set through Supabase Auth dashboard or API

-- Example of how to insert users after auth accounts are created:
-- INSERT INTO public.users (id, username, role)
-- VALUES
--   ('auth-uuid-for-YLES-001', 'YLES-001', 'admin'),
--   ('auth-uuid-for-YLES-300', 'YLES-300', 'admin');

-- Create a function to automatically add user to public.users table on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.users (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'player')
  );
  RETURN NEW;
END;
$$;

-- Trigger to auto-create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_games_status ON public.games(status);
CREATE INDEX IF NOT EXISTS idx_games_created_by ON public.games(created_by);
CREATE INDEX IF NOT EXISTS idx_scenarios_game_id ON public.scenarios(game_id);
CREATE INDEX IF NOT EXISTS idx_options_scenario_id ON public.options(scenario_id);
CREATE INDEX IF NOT EXISTS idx_game_participants_game_id ON public.game_participants(game_id);
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id ON public.game_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_player_choices_game_user ON public.player_choices(game_id, user_id);
CREATE INDEX IF NOT EXISTS idx_game_state_game_id ON public.game_state(game_id);
