import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { format } from 'date-fns'

export default function GameMonitor({ game, onClose }) {
  const [gameState, setGameState] = useState(null)
  const [currentScenario, setCurrentScenario] = useState(null)
  const [participants, setParticipants] = useState([])
  const [scenarios, setScenarios] = useState([])
  const [choices, setChoices] = useState([])
  const [loading, setLoading] = useState(true)
  const [advancing, setAdvancing] = useState(false)

  useEffect(() => {
    fetchGameData()

    // Subscribe to real-time updates
    const channel = supabase
      .channel(`game_${game.id}_monitor`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'game_state',
          filter: `game_id=eq.${game.id}`
        },
        () => {
          fetchGameData()
        }
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'player_choices',
          filter: `game_id=eq.${game.id}`
        },
        () => {
          fetchGameData()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [game.id])

  const fetchGameData = async () => {
    try {
      setLoading(true)

      // Fetch game state
      const { data: stateData, error: stateError } = await supabase
        .from('game_state')
        .select('*')
        .eq('game_id', game.id)
        .single()

      if (stateError && stateError.code !== 'PGRST116') throw stateError
      setGameState(stateData)

      // Fetch scenarios
      const { data: scenariosData, error: scenariosError } = await supabase
        .from('scenarios')
        .select('*')
        .eq('game_id', game.id)
        .order('scenario_number')

      if (scenariosError) throw scenariosError
      setScenarios(scenariosData || [])

      // Fetch current scenario details
      if (stateData?.current_scenario_id) {
        const { data: scenarioData, error: scenarioError } = await supabase
          .from('scenarios')
          .select('*')
          .eq('id', stateData.current_scenario_id)
          .single()

        if (scenarioError) throw scenarioError
        setCurrentScenario(scenarioData)
      }

      // Fetch participants with proper ranking order
      const { data: participantsData, error: participantsError } = await supabase
        .from('game_participants')
        .select(`
          *,
          users (
            username
          )
        `)
        .eq('game_id', game.id)
        .order('qualified', { ascending: false })
        .order('qualified_at', { ascending: true, nullsFirst: false })
        .order('current_valuation', { ascending: false })

      if (participantsError) throw participantsError
      setParticipants(participantsData || [])

      // Fetch choices for current scenario
      if (stateData?.current_scenario_id) {
        const { data: choicesData, error: choicesError } = await supabase
          .from('player_choices')
          .select('user_id')
          .eq('game_id', game.id)
          .eq('scenario_id', stateData.current_scenario_id)

        if (choicesError) throw choicesError
        setChoices(choicesData || [])
      }
    } catch (error) {
      console.error('Error fetching game data:', error)
      alert('Failed to load game data: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const handleAdvanceScenario = async () => {
    if (!confirm('Advance to the next scenario? This will end the current scenario immediately.')) {
      return
    }

    try {
      setAdvancing(true)

      const { data, error } = await supabase.rpc('advance_scenario', {
        p_game_id: game.id
      })

      if (error) throw error

      if (data === false) {
        alert('This was the last scenario. The game has been completed.')
      } else {
        alert('Successfully advanced to the next scenario!')
      }

      fetchGameData()
    } catch (error) {
      console.error('Error advancing scenario:', error)
      alert('Failed to advance scenario: ' + error.message)
    } finally {
      setAdvancing(false)
    }
  }

  const handleEndGame = async () => {
    if (!confirm('End this game now? This will mark it as completed and prevent further submissions.')) {
      return
    }

    try {
      const { error } = await supabase
        .from('games')
        .update({ status: 'completed' })
        .eq('id', game.id)

      if (error) throw error

      alert('Game ended successfully!')
      onClose()
    } catch (error) {
      console.error('Error ending game:', error)
      alert('Failed to end game: ' + error.message)
    }
  }

  const hasSubmitted = (userId) => {
    return choices.some(choice => choice.user_id === userId)
  }

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
        <div className="glass-panel rounded-2xl p-8 text-center">
          <div className="text-xl font-bold text-gradient mb-4">Loading game data...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="glass-panel rounded-2xl w-full max-w-6xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-6 border-b border-white/10 flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gradient">{game.title}</h2>
            <p className="text-sm text-gray-400 mt-1">Game Monitor & Control</p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Column - Current Status */}
            <div className="space-y-6">
              {/* Current Scenario */}
              <div className="glass-panel rounded-xl p-6">
                <h3 className="text-lg font-bold mb-4">Current Scenario</h3>
                {currentScenario ? (
                  <div className="space-y-3">
                    <div>
                      <p className="text-sm text-gray-400">Scenario #{currentScenario.scenario_number}</p>
                      <p className="text-xl font-semibold">{currentScenario.title}</p>
                    </div>
                    {currentScenario.description && (
                      <p className="text-sm text-gray-400">{currentScenario.description}</p>
                    )}
                    {gameState?.scenario_ends_at && (
                      <div className="mt-4 p-3 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                        <p className="text-sm text-blue-400">
                          Timer set until: {format(new Date(gameState.scenario_ends_at), 'MMM dd, yyyy HH:mm:ss')}
                        </p>
                        <p className="text-xs text-gray-400 mt-1">
                          Note: Timer is for display only. Advance manually when ready.
                        </p>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-gray-400">No active scenario</p>
                )}
              </div>

              {/* All Scenarios Overview */}
              <div className="glass-panel rounded-xl p-6">
                <h3 className="text-lg font-bold mb-4">All Scenarios ({scenarios.length})</h3>
                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {scenarios.map((scenario) => (
                    <div
                      key={scenario.id}
                      className={`p-3 rounded-lg border ${
                        scenario.id === gameState?.current_scenario_id
                          ? 'bg-accent/10 border-accent'
                          : 'bg-white/5 border-white/10'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-medium">
                          #{scenario.scenario_number} - {scenario.title}
                        </span>
                        {scenario.id === gameState?.current_scenario_id && (
                          <span className="text-xs bg-accent text-white px-2 py-1 rounded-full">
                            ACTIVE
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Control Actions */}
              <div className="glass-panel rounded-xl p-6">
                <h3 className="text-lg font-bold mb-4">Game Controls</h3>
                <div className="space-y-3">
                  <button
                    onClick={handleAdvanceScenario}
                    disabled={advancing || !currentScenario}
                    className="w-full bg-gradient text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 disabled:opacity-50 transition-all"
                  >
                    {advancing ? 'Advancing...' : 'Advance to Next Scenario'}
                  </button>
                  <button
                    onClick={handleEndGame}
                    className="w-full bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-400 font-semibold py-3 px-6 rounded-lg transition-all"
                  >
                    End Game Now
                  </button>
                </div>
              </div>
            </div>

            {/* Right Column - Participants */}
            <div className="glass-panel rounded-xl p-6">
              <h3 className="text-lg font-bold mb-4">
                Participants ({participants.length})
              </h3>

              {participants.length === 0 ? (
                <p className="text-center py-8 text-gray-400">No participants yet</p>
              ) : (
                <div className="space-y-3 max-h-[600px] overflow-y-auto">
                  {participants.map((participant, index) => {
                    const submitted = hasSubmitted(participant.user_id)
                    const rank = index + 1

                    return (
                      <div
                        key={participant.id}
                        className={`glass-panel rounded-lg p-4 ${
                          participant.qualified ? 'ring-2 ring-green-400' : ''
                        }`}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-3">
                            <span className="text-sm font-bold text-gray-400">#{rank}</span>
                            <div>
                              <p className="font-semibold flex items-center gap-2">
                                {participant.users.username}
                                {participant.qualified && (
                                  <span className="text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full">
                                    ✓ QUALIFIED
                                  </span>
                                )}
                              </p>
                              <p className="text-xs text-gray-400">
                                ${(participant.current_valuation / 1000000).toFixed(2)}M
                              </p>
                            </div>
                          </div>
                          <div>
                            {currentScenario && (
                              submitted ? (
                                <span className="text-xs bg-green-500/20 text-green-400 px-3 py-1 rounded-full font-medium">
                                  ✓ Submitted
                                </span>
                              ) : (
                                <span className="text-xs bg-yellow-500/20 text-yellow-400 px-3 py-1 rounded-full font-medium">
                                  Waiting...
                                </span>
                              )
                            )}
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}

              {currentScenario && participants.length > 0 && (
                <div className="mt-4 p-3 bg-white/5 rounded-lg">
                  <p className="text-sm text-gray-400">
                    Submissions: <span className="text-white font-semibold">
                      {choices.length} / {participants.length}
                    </span>
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
