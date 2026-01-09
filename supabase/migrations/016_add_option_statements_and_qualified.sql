-- =====================================================
-- ADD OPTION STATEMENTS AND QUALIFIED STATUS
-- - Add statement field to options (what players see)
-- - Add qualified status to game_participants
-- - Variables remain hidden from players
-- =====================================================

-- Add statement field to options table
ALTER TABLE public.options
ADD COLUMN IF NOT EXISTS statement TEXT;

-- Add qualified status to game_participants
ALTER TABLE public.game_participants
ADD COLUMN IF NOT EXISTS qualified BOOLEAN DEFAULT FALSE;

-- Add index for faster qualified queries
CREATE INDEX IF NOT EXISTS idx_game_participants_qualified
ON public.game_participants(game_id, qualified);

-- Update submit_player_choice function to set qualified status
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
BEGIN
  -- Get current valuation
  SELECT current_valuation INTO v_old_valuation
  FROM public.game_participants
  WHERE user_id = p_user_id AND game_id = p_game_id;

  -- Calculate new valuation using the function
  v_new_valuation := calculate_new_valuation(p_user_id, p_game_id, p_scenario_id, p_option_id);

  -- Check if qualified (reached 1 billion)
  v_is_qualified := v_new_valuation >= 1000000000;

  -- Update participant's valuation and qualified status
  UPDATE public.game_participants
  SET
    current_valuation = v_new_valuation,
    qualified = v_is_qualified
  WHERE user_id = p_user_id AND game_id = p_game_id;

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
  RAISE NOTICE '✅ Added option statements and qualified status!';
  RAISE NOTICE '👉 Players will now see only option statements, not variables.';
  RAISE NOTICE '👉 Players reaching 1B will be marked as qualified.';
END $$;
