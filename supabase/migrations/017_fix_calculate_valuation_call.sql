-- =====================================================
-- FIX CALCULATE_NEW_VALUATION FUNCTION CALL
-- - Fix incorrect parameter count in submit_player_choice
-- - Original function takes 3 params, not 4
-- =====================================================

-- Recreate submit_player_choice function with correct parameter count
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

  -- Calculate new valuation using the function (only 3 parameters: user_id, game_id, option_id)
  v_new_valuation := calculate_new_valuation(p_user_id, p_game_id, p_option_id);

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
  RAISE NOTICE '✅ Fixed submit_player_choice function!';
  RAISE NOTICE '👉 Now calling calculate_new_valuation with correct parameter count (3 params).';
END $$;
