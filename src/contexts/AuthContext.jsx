import { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react'
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
  const userRef = useRef(null)

  // Update ref whenever user changes
  useEffect(() => {
    userRef.current = user
  }, [user])

  const checkUser = useCallback(async () => {
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
  }, [])

  const signOut = useCallback(async () => {
    try {
      console.log('AuthContext: Signing out and clearing session...')
      await supabaseSignOut()
      setUser(null)
    } catch (error) {
      console.error('Error signing out:', error)
    }
  }, [])

  useEffect(() => {
    // Clear any existing session on mount (forces fresh login on every page load)
    const clearSessionOnMount = async () => {
      console.log('AuthContext: Clearing session on mount...')
      await supabaseSignOut()
      setUser(null)
      setLoading(false)
    }

    clearSessionOnMount()

    // Subscribe to auth changes
    const { data: { subscription } } = onAuthStateChange(async (event) => {
      if (event === 'SIGNED_IN') {
        await checkUser()
      } else if (event === 'SIGNED_OUT') {
        setUser(null)
      }
    })

    // Logout on visibility change (tab switch, window minimize, etc.)
    const handleVisibilityChange = () => {
      // Use ref to access current user without adding user to dependencies
      if (document.hidden && userRef.current) {
        console.log('AuthContext: Visibility change detected, logging out...')
        signOut()
      }
    }

    // Logout before page unload (refresh, close tab, navigate away)
    const handleBeforeUnload = () => {
      console.log('AuthContext: Page unload detected, logging out...')
      // Use synchronous localStorage clear since async won't complete
      localStorage.clear()
      sessionStorage.clear()
    }

    document.addEventListener('visibilitychange', handleVisibilityChange)
    window.addEventListener('beforeunload', handleBeforeUnload)

    return () => {
      subscription?.unsubscribe()
      document.removeEventListener('visibilitychange', handleVisibilityChange)
      window.removeEventListener('beforeunload', handleBeforeUnload)
    }
  }, [checkUser, signOut])

  const value = {
    user,
    loading,
    signOut,
    refreshUser: checkUser,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
