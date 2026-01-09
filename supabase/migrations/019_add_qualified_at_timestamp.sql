-- =====================================================
-- ADD QUALIFIED_AT TIMESTAMP FOR TIME-SENSITIVE RANKING
-- - Track when each player reaches $1B qualification
-- - Enable ranking by qualification time (first to qualify = rank 1)
-- =====================================================

-- Add qualified_at timestamp to game_participants
ALTER TABLE public.game_participants
ADD COLUMN IF NOT EXISTS qualified_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster leaderboard queries
CREATE INDEX IF NOT EXISTS idx_game_participants_qualified_at
ON public.game_participants(game_id, qualified, qualified_at);

-- Update submit_player_choice function to set qualified_at timestamp
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
  v_new_valuation DECIMAL;
  v_old_valuation DECIMAL;
  v_is_qualified BOOLEAN;
  v_was_qualified BOOLEAN;
BEGIN
  -- Get current valuation and qualification status
  SELECT current_valuation, qualified INTO v_old_valuation, v_was_qualified
  FROM public.game_participants
  WHERE user_id = p_user_id AND game_id = p_game_id;

  -- Calculate new valuation (only 3 parameters: user_id, game_id, option_id)
  v_new_valuation := calculate_new_valuation(p_user_id, p_game_id, p_option_id);

  -- Check if qualified (reached 1 billion)
  v_is_qualified := v_new_valuation >= 1000000000;

  -- Update participant's valuation and qualified status
  -- Set qualified_at timestamp only when first reaching qualification
  IF v_is_qualified AND NOT v_was_qualified THEN
    -- First time qualifying - set timestamp
    UPDATE public.game_participants
    SET
      current_valuation = v_new_valuation,
      qualified = v_is_qualified,
      qualified_at = NOW()
    WHERE user_id = p_user_id AND game_id = p_game_id;
  ELSE
    -- Either already qualified or not yet qualified - update valuation only
    UPDATE public.game_participants
    SET
      current_valuation = v_new_valuation,
      qualified = v_is_qualified
    WHERE user_id = p_user_id AND game_id = p_game_id;
  END IF;

  -- Record the choice
  INSERT INTO public.player_choices (
    game_id,
    user_id,
    scenario_id,
    option_id,
    valuation_before,
    valuation_after
  ) VALUES (
    p_game_id,
    p_user_id,
    p_scenario_id,
    p_option_id,
    v_old_valuation,
    v_new_valuation
  );

  -- Return result with qualified status
  RETURN jsonb_build_object(
    'valuation_before', v_old_valuation,
    'valuation_after', v_new_valuation,
    'qualified', v_is_qualified
  );
END;
$$;

DO $$
BEGIN
  RAISE NOTICE '✅ Added qualified_at timestamp for time-sensitive ranking!';
  RAISE NOTICE '👉 Leaderboard will now rank by:';
  RAISE NOTICE '   1. Qualified players first (those who reached $1B)';
  RAISE NOTICE '   2. Among qualified: earliest qualification time (first to reach = rank 1)';
  RAISE NOTICE '   3. Among non-qualified: highest current valuation';
END $$;
