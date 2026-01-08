import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { format } from 'date-fns'
import GameEditor from '../components/GameEditor'

export default function AdminDashboard() {
  const { user, signOut } = useAuth()
  const [games, setGames] = useState([])
  const [loading, setLoading] = useState(true)
  const [showEditor, setShowEditor] = useState(false)
  const [editingGame, setEditingGame] = useState(null)

  useEffect(() => {
    fetchGames()
  }, [])

  const fetchGames = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('games')
        .select('*')
        .eq('created_by', user.id)
        .order('created_at', { ascending: false })

      if (error) throw error
      setGames(data || [])
    } catch (error) {
      console.error('Error fetching games:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleStartGame = async (gameId) => {
    try {
      const { error } = await supabase.rpc('start_game', { p_game_id: gameId })
      if (error) throw error
      fetchGames()
    } catch (error) {
      console.error('Error starting game:', error)
      alert('Failed to start game: ' + error.message)
    }
  }

  const handleDeleteGame = async (gameId) => {
    if (!confirm('Are you sure you want to delete this game? This action cannot be undone.')) {
      return
    }

    try {
      const { error } = await supabase
        .from('games')
        .delete()
        .eq('id', gameId)

      if (error) throw error
      fetchGames()
    } catch (error) {
      console.error('Error deleting game:', error)
      alert('Failed to delete game: ' + error.message)
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

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="glass-panel sticky top-0 z-10">
        <div className="container flex items-center justify-between py-4">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold text-gradient">STRATEGY SYMPOSIUM</h1>
            <span className="text-sm text-gray-400">Admin Portal</span>
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
      <div className="container py-8">
        {/* Header with Create Button */}
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold">My Games</h2>
          <button
            onClick={() => {
              setEditingGame(null)
              setShowEditor(true)
            }}
            className="px-6 py-3 bg-gradient text-white font-semibold rounded-lg hover:opacity-90 transition-all"
          >
            + Create New Game
          </button>
        </div>

        {/* Games Grid */}
        {loading ? (
          <div className="text-center py-12 text-gray-400">Loading games...</div>
        ) : games.length === 0 ? (
          <div className="glass-panel rounded-xl p-12 text-center">
            <svg className="w-16 h-16 mx-auto mb-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p className="text-gray-400 mb-4">No games created yet</p>
            <button
              onClick={() => setShowEditor(true)}
              className="px-6 py-2 bg-gradient text-white font-semibold rounded-lg hover:opacity-90 transition-all"
            >
              Create Your First Game
            </button>
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
                  <div className="flex justify-between">
                    <span className="text-gray-400">Created:</span>
                    <span>{format(new Date(game.created_at), 'MMM dd, yyyy')}</span>
                  </div>
                </div>

                <div className="flex gap-2">
                  {game.status === 'draft' && (
                    <>
                      <button
                        onClick={() => {
                          setEditingGame(game)
                          setShowEditor(true)
                        }}
                        className="flex-1 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-colors text-sm"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleStartGame(game.id)}
                        className="flex-1 px-4 py-2 bg-green-500/20 hover:bg-green-500/30 border border-green-500/30 text-green-400 rounded-lg transition-colors text-sm font-semibold"
                      >
                        Start
                      </button>
                    </>
                  )}
                  {game.status === 'active' && (
                    <button
                      className="flex-1 px-4 py-2 bg-blue-500/20 hover:bg-blue-500/30 border border-blue-500/30 text-blue-400 rounded-lg transition-colors text-sm font-semibold"
                    >
                      Monitor
                    </button>
                  )}
                  {game.status === 'completed' && (
                    <button
                      className="flex-1 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-colors text-sm"
                    >
                      View Results
                    </button>
                  )}
                  <button
                    onClick={() => handleDeleteGame(game.id)}
                    className="px-4 py-2 bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-400 rounded-lg transition-colors text-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Game Editor Modal */}
      {showEditor && (
        <GameEditor
          game={editingGame}
          onClose={() => {
            setShowEditor(false)
            setEditingGame(null)
            fetchGames()
          }}
        />
      )}
    </div>
  )
}
