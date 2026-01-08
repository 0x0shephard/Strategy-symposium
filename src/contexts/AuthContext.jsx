import { createContext, useContext, useState, useEffect } from 'react'
import { getCurrentUser, onAuthStateChange, signOut as supabaseSignOut } from '../lib/supabase'

const AuthContext = createContext({})

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check for existing session on mount
    checkUser()

    // Subscribe to auth changes
    const { data: { subscription } } = onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        await checkUser()
      } else if (event === 'SIGNED_OUT') {
        setUser(null)
      }
    })

    return () => {
      subscription?.unsubscribe()
    }
  }, [])

  const checkUser = async () => {
    try {
      setLoading(true)
      console.log('AuthContext: Checking user...')
      const { user: currentUser, error } = await getCurrentUser()

      console.log('AuthContext: User check result:', { user: currentUser, error })

      if (!error && currentUser) {
        console.log('AuthContext: User found:', currentUser.username)
        setUser(currentUser)
      } else {
        console.log('AuthContext: No user or error:', error?.message)
        setUser(null)
      }
    } catch (error) {
      console.error('AuthContext: Error checking user:', error)
      setUser(null)
    } finally {
      setLoading(false)
    }
  }

  const signOut = async () => {
    try {
      await supabaseSignOut()
      setUser(null)
    } catch (error) {
      console.error('Error signing out:', error)
    }
  }

  const value = {
    user,
    loading,
    signOut,
    refreshUser: checkUser,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
