import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { format } from 'date-fns'
import { useNavigate } from 'react-router-dom'

export default function PlayerDashboard() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const [games, setGames] = useState([])
  const [myGames, setMyGames] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchGames()
  }, [user])

  const fetchGames = async () => {
    try {
      setLoading(true)

      // Fetch all active games
      const { data: allGames, error: gamesError } = await supabase
        .from('games')
        .select('*')
        .in('status', ['active', 'completed'])
        .order('created_at', { ascending: false })

      if (gamesError) throw gamesError

      // Fetch games user has joined
      const { data: participations, error: partError } = await supabase
        .from('game_participants')
        .select('*, games(*)')
        .eq('user_id', user.id)

      if (partError) throw partError

      setGames(allGames || [])
      setMyGames(participations || [])
    } catch (error) {
      console.error('Error fetching games:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleJoinGame = async (gameId) => {
    try {
      const { error } = await supabase
        .from('game_participants')
        .insert({
          game_id: gameId,
          user_id: user.id
        })

      if (error) {
        if (error.code === '23505') {
          alert('You have already joined this game!')
        } else {
          throw error
        }
      } else {
        alert('Successfully joined the game!')
        fetchGames()
      }
    } catch (error) {
      console.error('Error joining game:', error)
      alert('Failed to join game: ' + error.message)
    }
  }

  const getStatusBadge = (status) => {
    switch (status) {
      case 'active':
        return <span className="badge-live">Live</span>
      case 'completed':
        return <span className="badge-completed">Completed</span>
      default:
        return <span className="badge-draft">Draft</span>
    }
  }

  const isJoined = (gameId) => {
    return myGames.some(mg => mg.game_id === gameId)
  }

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="glass-panel sticky top-0 z-10">
        <div className="container flex items-center justify-between py-4">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold text-gradient">STRATEGY SYMPOSIUM</h1>
            <span className="text-sm text-gray-400">Player Portal</span>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-sm font-medium">{user?.username}</p>
              <p className="text-xs text-gray-400 capitalize">{user?.role}</p>
            </div>
            <button
              onClick={signOut}
              className="px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-colors"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="container py-8 space-y-8">
        {/* My Active Games */}
        {myGames.length > 0 && (
          <div>
            <h2 className="text-2xl font-bold mb-6">My Active Games</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {myGames.map((participation) => (
                <div key={participation.id} className="glass-panel rounded-xl p-6 animate-fadeIn">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="text-xl font-bold">{participation.games.title}</h3>
                    {getStatusBadge(participation.games.status)}
                  </div>

                  <div className="space-y-2 mb-4 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Current Valuation:</span>
                      <span className="font-mono text-green-400">
                        ${(participation.current_valuation / 1000000).toFixed(2)}M
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Target:</span>
                      <span className="font-mono">
                        ${(participation.games.target_valuation / 1000000).toFixed(0)}M
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Progress:</span>
                      <span className="font-mono">
                        {((participation.current_valuation / participation.games.target_valuation) * 100).toFixed(1)}%
                      </span>
                    </div>
                  </div>

                  <div className="w-full bg-white/5 rounded-full h-2 mb-4">
                    <div
                      className="bg-gradient h-2 rounded-full transition-all"
                      style={{
                        width: `${Math.min((participation.current_valuation / participation.games.target_valuation) * 100, 100)}%`
                      }}
                    ></div>
                  </div>

                  {participation.games.status === 'active' ? (
                    <button
                      onClick={() => navigate(`/game/${participation.game_id}`)}
                      className="w-full bg-gradient text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 transition-all"
                    >
                      Play Now
                    </button>
                  ) : (
                    <button
                      className="w-full bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg py-3 px-6 transition-colors"
                    >
                      View Results
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Available Games */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold">Available Games</h2>
            <button
              onClick={fetchGames}
              className="px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </button>
          </div>

          {loading ? (
            <div className="text-center py-12 text-gray-400">Loading games...</div>
          ) : games.length === 0 ? (
            <div className="glass-panel rounded-xl p-12 text-center">
              <p className="text-gray-400">No games available at the moment</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {games.map((game) => (
                <div key={game.id} className="glass-panel rounded-xl p-6 animate-fadeIn">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="text-xl font-bold">{game.title}</h3>
                    {getStatusBadge(game.status)}
                  </div>

                  <p className="text-gray-400 text-sm mb-4 line-clamp-2">
                    {game.description || 'No description'}
                  </p>

                  <div className="space-y-2 mb-4 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Starting Valuation:</span>
                      <span className="font-mono">${(game.starting_valuation / 1000000).toFixed(0)}M</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Target:</span>
                      <span className="font-mono text-green-400">${(game.target_valuation / 1000000).toFixed(0)}M</span>
                    </div>
                  </div>

                  {game.status === 'active' && !isJoined(game.id) && (
                    <button
                      onClick={() => handleJoinGame(game.id)}
                      className="w-full bg-gradient text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 transition-all"
                    >
                      Join Game
                    </button>
                  )}
                  {game.status === 'active' && isJoined(game.id) && (
                    <button
                      onClick={() => navigate(`/game/${game.id}`)}
                      className="w-full bg-blue-500/20 hover:bg-blue-500/30 border border-blue-500/30 text-blue-400 font-semibold py-3 px-6 rounded-lg transition-all"
                    >
                      Continue Playing
                    </button>
                  )}
                  {game.status === 'completed' && (
                    <button
                      className="w-full bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg py-3 px-6 transition-colors"
                    >
                      View Results
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
