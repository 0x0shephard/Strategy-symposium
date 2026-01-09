-- =====================================================
-- DIAGNOSTIC SCRIPT FOR GAME ISSUES
-- Run this to check why players can't see options
-- =====================================================

-- Check all games
SELECT
  'GAMES' as info,
  id,
  title,
  status,
  created_at
FROM public.games
ORDER BY created_at DESC;

-- Check game state for each game
SELECT
  'GAME STATE' as info,
  gs.game_id,
  g.title as game_name,
  g.status as game_status,
  gs.current_scenario_id,
  s.title as scenario_title,
  s.scenario_number,
  gs.scenario_started_at,
  gs.scenario_ends_at
FROM public.game_state gs
JOIN public.games g ON g.id = gs.game_id
LEFT JOIN public.scenarios s ON s.id = gs.current_scenario_id
ORDER BY gs.game_id;

-- Check scenarios for each game
SELECT
  'SCENARIOS' as info,
  s.game_id,
  g.title as game_name,
  s.id as scenario_id,
  s.scenario_number,
  s.title as scenario_title,
  s.duration_minutes,
  COUNT(o.id) as option_count
FROM public.scenarios s
JOIN public.games g ON g.id = s.game_id
LEFT JOIN public.options o ON o.scenario_id = s.id
GROUP BY s.id, g.title, s.game_id, s.scenario_number, s.title, s.duration_minutes
ORDER BY s.game_id, s.scenario_number;

-- Check options for each scenario
SELECT
  'OPTIONS' as info,
  s.game_id,
  g.title as game_name,
  s.scenario_number,
  s.title as scenario_title,
  o.id as option_id,
  o.option_number,
  CASE
    WHEN o.statement IS NULL OR o.statement = '' THEN '❌ NO STATEMENT'
    ELSE '✓ Has statement'
  END as has_statement,
  o.rgm,
  o.mre,
  o.ues,
  o.crq,
  o.rga,
  o.cem
FROM public.options o
JOIN public.scenarios s ON s.id = o.scenario_id
JOIN public.games g ON g.id = s.game_id
ORDER BY s.game_id, s.scenario_number, o.option_number;

-- Check for games with scenarios but no options
SELECT
  'MISSING OPTIONS' as info,
  s.game_id,
  g.title as game_name,
  s.id as scenario_id,
  s.scenario_number,
  s.title as scenario_title,
  COUNT(o.id) as option_count
FROM public.scenarios s
JOIN public.games g ON g.id = s.game_id
LEFT JOIN public.options o ON o.scenario_id = s.id
GROUP BY s.id, g.title, s.game_id, s.scenario_number, s.title
HAVING COUNT(o.id) = 0
ORDER BY s.game_id, s.scenario_number;

-- Check game participants
SELECT
  'PARTICIPANTS' as info,
  gp.game_id,
  g.title as game_name,
  g.status as game_status,
  u.username,
  gp.current_valuation,
  gp.qualified,
  gp.joined_at
FROM public.game_participants gp
JOIN public.games g ON g.id = gp.game_id
JOIN public.users u ON u.id = gp.user_id
ORDER BY gp.game_id, gp.joined_at;

-- Summary of issues
SELECT
  'SUMMARY' as check_type,
  (SELECT COUNT(*) FROM public.games WHERE status = 'active' AND id NOT IN (SELECT game_id FROM public.game_state)) as active_games_without_state,
  (SELECT COUNT(DISTINCT s.id) FROM public.scenarios s LEFT JOIN public.options o ON o.scenario_id = s.id WHERE o.id IS NULL) as scenarios_without_options,
  (SELECT COUNT(*) FROM public.games WHERE status = 'draft') as draft_games,
  (SELECT COUNT(*) FROM public.games WHERE status = 'active') as active_games,
  (SELECT COUNT(*) FROM public.games WHERE status = 'completed') as completed_games;

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'DIAGNOSTIC COMPLETE';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Check the results above to identify issues:';
  RAISE NOTICE '1. Active games without state = game not started properly';
  RAISE NOTICE '2. Scenarios without options = options not saved';
  RAISE NOTICE '3. Missing statement = players will see "No description"';
  RAISE NOTICE '==============================================';
END $$;
