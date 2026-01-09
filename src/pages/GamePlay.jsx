import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import Timer from '../components/Timer'
import Leaderboard from '../components/Leaderboard'

export default function GamePlay() {
  const { gameId } = useParams()
  const { user } = useAuth()
  const navigate = useNavigate()

  const [game, setGame] = useState(null)
  const [gameState, setGameState] = useState(null)
  const [currentScenario, setCurrentScenario] = useState(null)
  const [options, setOptions] = useState([])
  const [selectedOption, setSelectedOption] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const [hasSubmitted, setHasSubmitted] = useState(false)
  const [participation, setParticipation] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchGameData()

    // Subscribe to game state changes
    const channel = supabase
      .channel(`game_${gameId}_state`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'game_state',
          filter: `game_id=eq.${gameId}`
        },
        () => {
          fetchGameData()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [gameId])

  const fetchGameData = async () => {
    try {
      setLoading(true)

      // Fetch game
      const { data: gameData, error: gameError } = await supabase
        .from('games')
        .select('*')
        .eq('id', gameId)
        .single()

      if (gameError) throw gameError
      setGame(gameData)

      // Fetch participation
      const { data: partData, error: partError } = await supabase
        .from('game_participants')
        .select('*')
        .eq('game_id', gameId)
        .eq('user_id', user.id)
        .single()

      if (partError) throw partError
      setParticipation(partData)

      // Fetch game state
      const { data: stateData, error: stateError } = await supabase
        .from('game_state')
        .select('*')
        .eq('game_id', gameId)
        .single()

      if (stateError) {
        // Game might be completed
        if (gameData.status === 'completed') {
          setGameState(null)
          setLoading(false)
          return
        }
        throw stateError
      }
      setGameState(stateData)

      // Fetch current scenario
      if (stateData.current_scenario_id) {
        const { data: scenarioData, error: scenarioError } = await supabase
          .from('scenarios')
          .select('*')
          .eq('id', stateData.current_scenario_id)
          .single()

        if (scenarioError) throw scenarioError
        setCurrentScenario(scenarioData)

        // Fetch options
        const { data: optionsData, error: optionsError } = await supabase
          .from('options')
          .select('*')
          .eq('scenario_id', stateData.current_scenario_id)
          .order('option_number')

        if (optionsError) throw optionsError
        setOptions(optionsData || [])

        // Check if user has submitted for this scenario
        const { data: choiceData, error: choiceError } = await supabase
          .from('player_choices')
          .select('*')
          .eq('game_id', gameId)
          .eq('user_id', user.id)
          .eq('scenario_id', stateData.current_scenario_id)
          .maybeSingle()

        if (!choiceError && choiceData) {
          setHasSubmitted(true)
          setSelectedOption(choiceData.option_id)
        } else {
          setHasSubmitted(false)
          setSelectedOption(null)
        }
      }
    } catch (error) {
      console.error('Error fetching game data:', error)
      alert('Failed to load game: ' + error.message)
      navigate('/dashboard')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmitChoice = async () => {
    if (!selectedOption || hasSubmitted) return

    try {
      setSubmitting(true)

      const { data, error } = await supabase.rpc('submit_player_choice', {
        p_user_id: user.id,
        p_game_id: gameId,
        p_scenario_id: currentScenario.id,
        p_option_id: selectedOption
      })

      if (error) throw error

      setHasSubmitted(true)

      // Show result with qualified status
      const message = data.qualified
        ? `🎉 QUALIFIED! You've reached $${(data.valuation_after / 1000000).toFixed(2)}M and qualified for the final round!`
        : `Choice submitted! New valuation: $${(data.valuation_after / 1000000).toFixed(2)}M`

      alert(message)

      // Refresh data
      fetchGameData()
    } catch (error) {
      console.error('Error submitting choice:', error)
      alert('Failed to submit choice: ' + error.message)
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-2xl font-bold text-gradient mb-4">Loading game...</div>
        </div>
      </div>
    )
  }

  if (game?.status === 'completed') {
    return (
      <div className="min-h-screen">
        <div className="container py-8">
          <button
            onClick={() => navigate('/dashboard')}
            className="mb-6 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-colors"
          >
            ← Back to Dashboard
          </button>

          <div className="glass-panel rounded-xl p-8 text-center mb-8">
            <h1 className="text-3xl font-bold text-gradient mb-4">{game.title}</h1>
            <p className="text-xl text-gray-400 mb-6">Game Completed</p>

            {participation && (
              <div className="space-y-4">
                <div>
                  <p className="text-gray-400 mb-2">Your Final Valuation</p>
                  <p className="text-4xl font-bold text-green-400 font-mono">
                    ${(participation.current_valuation / 1000000).toFixed(2)}M
                  </p>
                </div>

                {participation.current_valuation >= game.target_valuation && (
                  <div className="mt-6">
                    <p className="text-2xl font-bold text-gradient">🎉 Congratulations! 🎉</p>
                    <p className="text-gray-400 mt-2">You reached unicorn status!</p>
                  </div>
                )}
              </div>
            )}
          </div>

          <Leaderboard gameId={gameId} />
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen pb-8">
      {/* Header */}
      <header className="glass-panel sticky top-0 z-10">
        <div className="container flex items-center justify-between py-4">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate('/dashboard')}
              className="text-gray-400 hover:text-white transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <div>
              <h1 className="text-xl font-bold">{game?.title}</h1>
              <p className="text-sm text-gray-400">{currentScenario?.title}</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-xs text-gray-400">Your Valuation</p>
              <p className="text-lg font-bold text-green-400 font-mono">
                ${(participation?.current_valuation / 1000000).toFixed(2)}M
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="container py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Scenario & Options */}
          <div className="lg:col-span-2 space-y-6">
            {/* Timer */}
            <div className="flex justify-center">
              <Timer endsAt={gameState?.scenario_ends_at} />
            </div>

            {/* Scenario Info */}
            {currentScenario && (
              <div className="glass-panel rounded-xl p-6">
                <h2 className="text-2xl font-bold mb-2">{currentScenario.title}</h2>
                {currentScenario.description && (
                  <p className="text-gray-400">{currentScenario.description}</p>
                )}
              </div>
            )}

            {/* Options Grid */}
            <div className="space-y-4">
              <h3 className="text-xl font-bold">Choose Your Strategy</h3>

              {hasSubmitted && (
                <div className="glass-panel rounded-lg p-4 bg-blue-500/10 border-blue-500/30">
                  <p className="text-blue-400">
                    ✓ Choice submitted! Waiting for scenario to end...
                  </p>
                </div>
              )}

              <div className="grid grid-cols-1 gap-4">
                {options.map((option) => (
                  <div
                    key={option.id}
                    onClick={() => !hasSubmitted && setSelectedOption(option.id)}
                    className={`glass-panel rounded-xl p-6 cursor-pointer transition-all ${
                      selectedOption === option.id
                        ? 'ring-2 ring-accent'
                        : hasSubmitted
                        ? 'opacity-50 cursor-not-allowed'
                        : 'hover:bg-white/10'
                    }`}
                  >
                    <div className="flex items-start justify-between mb-4">
                      <h4 className="text-lg font-bold">Option {option.option_number}</h4>
                      {selectedOption === option.id && (
                        <svg className="w-6 h-6 text-accent" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                      )}
                    </div>

                    {/* Option Statement */}
                    <p className="text-gray-300 leading-relaxed whitespace-pre-wrap">
                      {option.statement || 'No description provided'}
                    </p>
                  </div>
                ))}
              </div>

              {/* Submit Button */}
              {!hasSubmitted && (
                <button
                  onClick={handleSubmitChoice}
                  disabled={!selectedOption || submitting}
                  className="w-full bg-gradient text-white font-semibold py-4 px-6 rounded-lg hover:opacity-90 disabled:opacity-50 transition-all text-lg"
                >
                  {submitting ? 'Submitting...' : 'Submit Choice'}
                </button>
              )}
            </div>
          </div>

          {/* Right Column - Leaderboard */}
          <div className="lg:col-span-1">
            <Leaderboard gameId={gameId} />
          </div>
        </div>
      </div>
    </div>
  )
}
