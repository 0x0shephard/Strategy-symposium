import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import Login from './pages/Login'
import AdminDashboard from './pages/AdminDashboard'
import PlayerDashboard from './pages/PlayerDashboard'
import GamePlay from './pages/GamePlay'

function AppRoutes() {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-2xl font-bold text-gradient mb-4">Loading...</div>
          <p className="text-gray-400">Please wait</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <Login />
  }

  return (
    <Routes>
      <Route
        path="/"
        element={
          user.role === 'admin' ? (
            <Navigate to="/admin" replace />
          ) : (
            <Navigate to="/dashboard" replace />
          )
        }
      />
      <Route
        path="/admin"
        element={
          user.role === 'admin' ? (
            <AdminDashboard />
          ) : (
            <Navigate to="/dashboard" replace />
          )
        }
      />
      <Route path="/dashboard" element={<PlayerDashboard />} />
      <Route path="/game/:gameId" element={<GamePlay />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </Router>
  )
}

export default App
