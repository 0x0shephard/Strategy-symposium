import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'
import { formatDistanceToNow } from 'date-fns'

export default function Leaderboard({ gameId }) {
  const { user } = useAuth()
  const [participants, setParticipants] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchLeaderboard()

    // Subscribe to real-time updates
    const channel = supabase
      .channel(`game_${gameId}_leaderboard`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'game_participants',
          filter: `game_id=eq.${gameId}`
        },
        () => {
          fetchLeaderboard()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [gameId])

  const fetchLeaderboard = async () => {
    try {
      setLoading(true)

      const { data, error } = await supabase
        .from('game_participants')
        .select(`
          *,
          users (
            username
          ),
          games (
            target_valuation
          )
        `)
        .eq('game_id', gameId)
        .order('qualified', { ascending: false })
        .order('qualified_at', { ascending: true, nullsFirst: false })
        .order('current_valuation', { ascending: false })

      if (error) throw error

      setParticipants(data || [])
    } catch (error) {
      console.error('Error fetching leaderboard:', error)
    } finally {
      setLoading(false)
    }
  }

  const getRankBadge = (rank) => {
    switch (rank) {
      case 1:
        return (
          <div className="flex items-center gap-2">
            <svg className="w-6 h-6 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
            <span className="text-lg font-bold text-yellow-400">1st</span>
          </div>
        )
      case 2:
        return (
          <div className="flex items-center gap-2">
            <svg className="w-6 h-6 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
            <span className="text-lg font-bold text-gray-300">2nd</span>
          </div>
        )
      case 3:
        return (
          <div className="flex items-center gap-2">
            <svg className="w-6 h-6 text-orange-400" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
            <span className="text-lg font-bold text-orange-400">3rd</span>
          </div>
        )
      default:
        return <span className="text-lg font-bold text-gray-400">#{rank}</span>
    }
  }

  if (loading) {
    return (
      <div className="glass-panel rounded-xl p-6">
        <h3 className="text-xl font-bold mb-4">Leaderboard</h3>
        <div className="text-center py-8 text-gray-400">Loading...</div>
      </div>
    )
  }

  return (
    <div className="glass-panel rounded-xl p-6">
      <h3 className="text-xl font-bold mb-4">Leaderboard</h3>

      {participants.length === 0 ? (
        <div className="text-center py-8 text-gray-400">No participants yet</div>
      ) : (
        <div className="space-y-3">
          {(() => {
            const qualifiedParticipants = participants.filter(p => p.qualified)
            const nonQualifiedParticipants = participants.filter(p => !p.qualified)

            return (
              <>
                {/* Qualified Players Section */}
                {qualifiedParticipants.length > 0 && (
                  <>
                    <div className="text-xs font-semibold text-green-400 uppercase tracking-wider px-2">
                      Qualified ({qualifiedParticipants.length})
                    </div>
                    {qualifiedParticipants.map((participant, index) => {
                      const qualifiedRank = index + 1
                      const progress = (participant.current_valuation / participant.games.target_valuation) * 100
                      const isCurrentUser = participant.user_id === user.id

                      return (
                        <div
                          key={participant.id}
                          className={`glass-panel rounded-lg p-4 transition-all ring-2 ring-green-400 ${
                            isCurrentUser ? 'ring-accent ring-4' : ''
                          }`}
                        >
                          <div className="flex items-center gap-4">
                            <div className="flex-shrink-0 w-16">
                              {getRankBadge(qualifiedRank)}
                            </div>

                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between mb-1">
                                <p className="font-semibold truncate flex items-center gap-2">
                                  {participant.users.username}
                                  {isCurrentUser && (
                                    <span className="text-xs text-accent">(You)</span>
                                  )}
                                  <span className="text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full font-medium">
                                    ✓ QUALIFIED
                                  </span>
                                </p>
                                <p className="font-mono text-sm">
                                  {progress.toFixed(1)}%
                                </p>
                              </div>

                              <div className="w-full bg-white/5 rounded-full h-2 mb-2">
                                <div
                                  className="bg-gradient h-2 rounded-full transition-all"
                                  style={{ width: `${Math.min(progress, 100)}%` }}
                                ></div>
                              </div>

                              <div className="flex items-center justify-between text-xs">
                                <span className="text-gray-400">Valuation:</span>
                                <span className="font-mono text-green-400">
                                  ${(participant.current_valuation / 1000000).toFixed(2)}M
                                </span>
                              </div>

                              {participant.qualified_at && (
                                <div className="mt-2 text-xs text-gray-400">
                                  Qualified {formatDistanceToNow(new Date(participant.qualified_at), { addSuffix: true })}
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      )
                    })}
                  </>
                )}

                {/* Non-Qualified Players Section */}
                {nonQualifiedParticipants.length > 0 && (
                  <>
                    {qualifiedParticipants.length > 0 && (
                      <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider px-2 mt-4">
                        Not Yet Qualified ({nonQualifiedParticipants.length})
                      </div>
                    )}
                    {nonQualifiedParticipants.map((participant, index) => {
                      const rank = index + 1
                      const progress = (participant.current_valuation / participant.games.target_valuation) * 100
                      const isCurrentUser = participant.user_id === user.id

                      return (
                        <div
                          key={participant.id}
                          className={`glass-panel rounded-lg p-4 transition-all ${
                            isCurrentUser ? 'ring-2 ring-accent' : ''
                          }`}
                        >
                          <div className="flex items-center gap-4">
                            <div className="flex-shrink-0 w-16">
                              <span className="text-lg font-bold text-gray-400">#{rank}</span>
                            </div>

                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between mb-1">
                                <p className="font-semibold truncate flex items-center gap-2">
                                  {participant.users.username}
                                  {isCurrentUser && (
                                    <span className="text-xs text-accent">(You)</span>
                                  )}
                                </p>
                                <p className="font-mono text-sm">
                                  {progress.toFixed(1)}%
                                </p>
                              </div>

                              <div className="w-full bg-white/5 rounded-full h-2 mb-2">
                                <div
                                  className="bg-gradient h-2 rounded-full transition-all"
                                  style={{ width: `${Math.min(progress, 100)}%` }}
                                ></div>
                              </div>

                              <div className="flex items-center justify-between text-xs">
                                <span className="text-gray-400">Valuation:</span>
                                <span className="font-mono text-green-400">
                                  ${(participant.current_valuation / 1000000).toFixed(2)}M
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      )
                    })}
                  </>
                )}
              </>
            )
          })()}
        </div>
      )}
    </div>
  )
}
