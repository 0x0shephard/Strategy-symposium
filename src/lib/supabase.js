import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Helper function to convert username to email format
const usernameToEmail = (username) => `${username.toLowerCase()}@racetounicorn.app`

// Sign in with username and password
// Generates a new authentication session with fresh JWT tokens on each login
export const signIn = async (username, password) => {
  const email = usernameToEmail(username)
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })
  return { data, error }
}

// Sign up with username and password
export const signUp = async (username, password, role = 'player') => {
  const email = usernameToEmail(username)
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        username,
        role,
      },
    },
  })
  return { data, error }
}

// Sign out - completely clears the session and removes all authentication tokens
export const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  return { error }
}

// Get current user
export const getCurrentUser = async () => {
  try {
    const { data: { user }, error } = await supabase.auth.getUser()
    if (error || !user) {
      console.error('Error getting auth user:', error)
      return { user: null, error }
    }

    console.log('Fetching profile for user:', user.id)

    // Get user profile from public.users table
    try {
      const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single()

      if (profileError) {
        console.error('Error getting user profile:', profileError)
        console.error('User ID:', user.id)
        console.error('User email:', user.email)
        return { user: null, error: profileError }
      }

      console.log('Profile found:', profile)
      return { user: profile, error: null }
    } catch (profileErr) {
      console.error('Profile query exception:', profileErr)
      return { user: null, error: profileErr }
    }
  } catch (err) {
    console.error('Unexpected error in getCurrentUser:', err)
    return { user: null, error: err }
  }
}

// Get current session
export const getSession = async () => {
  const { data: { session }, error } = await supabase.auth.getSession()
  return { session, error }
}

// Subscribe to auth state changes
export const onAuthStateChange = (callback) => {
  return supabase.auth.onAuthStateChange(callback)
}
