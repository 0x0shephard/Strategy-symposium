import { useState, useEffect } from 'react'

export default function Timer({ endsAt }) {
  const [timeLeft, setTimeLeft] = useState(0)

  useEffect(() => {
    if (!endsAt) return

    const calculateTimeLeft = () => {
      const now = new Date().getTime()
      const end = new Date(endsAt).getTime()
      const difference = end - now
      return Math.max(0, Math.floor(difference / 1000)) // seconds
    }

    // Initial calculation
    setTimeLeft(calculateTimeLeft())

    // Update every second
    const interval = setInterval(() => {
      const newTimeLeft = calculateTimeLeft()
      setTimeLeft(newTimeLeft)

      if (newTimeLeft <= 0) {
        clearInterval(interval)
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [endsAt])

  const minutes = Math.floor(timeLeft / 60)
  const seconds = timeLeft % 60

  const getColorClass = () => {
    if (minutes >= 5) return 'text-green-400'
    if (minutes >= 1) return 'text-yellow-400'
    return 'text-red-400'
  }

  const getBackgroundClass = () => {
    if (minutes >= 5) return 'bg-green-500/20 border-green-500/30'
    if (minutes >= 1) return 'bg-yellow-500/20 border-yellow-500/30'
    return 'bg-red-500/20 border-red-500/30'
  }

  if (!endsAt) {
    return (
      <div className="glass-panel rounded-lg px-4 py-2 border border-white/10">
        <span className="text-gray-400">Waiting to start...</span>
      </div>
    )
  }

  return (
    <div className={`rounded-lg px-6 py-3 border ${getBackgroundClass()}`}>
      <div className="text-center">
        <div className="text-xs font-medium text-gray-400 mb-1">Time Remaining</div>
        <div className={`text-3xl font-bold font-mono ${getColorClass()}`}>
          {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
        </div>
      </div>
    </div>
  )
}
