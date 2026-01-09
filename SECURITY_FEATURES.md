# Security Features - Strategy Symposium

## Automatic Logout on Visibility Change

### Overview
The application implements an automatic logout mechanism that triggers when the browser tab loses visibility. This ensures that user sessions are immediately terminated when users:
- Switch to a different browser tab
- Minimize the browser window
- Switch to a different application
- Lock their computer screen

### How It Works

#### 1. Visibility Detection
The application uses the browser's [Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API) to detect when the document becomes hidden.

```javascript
document.addEventListener('visibilitychange', handleVisibilityChange)
```

#### 2. Automatic Logout
When `document.hidden` becomes `true` and a user is logged in, the system:
1. Logs a message: `"AuthContext: Visibility change detected, logging out..."`
2. Calls the `signOut()` function
3. Clears the user session from state
4. Removes all authentication tokens from Supabase

#### 3. Session Regeneration
When the user logs back in:
1. Supabase automatically generates a **new authentication session**
2. Fresh JWT tokens are created (access token and refresh token)
3. The old session is completely invalidated
4. The new session is stored securely

### Implementation Details

**File: `src/contexts/AuthContext.jsx`**

```javascript
// Logout on visibility change (tab switch, window minimize, etc.)
const handleVisibilityChange = () => {
  if (document.hidden && user) {
    console.log('AuthContext: Visibility change detected, logging out...')
    signOut()
  }
}

document.addEventListener('visibilitychange', handleVisibilityChange)
```

**File: `src/lib/supabase.js`**

```javascript
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

// Sign out - completely clears the session and removes all authentication tokens
export const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  return { error }
}
```

### Security Benefits

1. **Prevents Unauthorized Access**: If a user forgets to logout and walks away, switching tabs automatically logs them out
2. **Session Hijacking Prevention**: Each login generates a new session, preventing reuse of old authentication tokens
3. **Multi-Tab Protection**: Each browser tab maintains its own session state
4. **Automatic Cleanup**: No lingering sessions that could be exploited

### User Experience Considerations

**What Users Will Experience:**
- ✅ Seamless login experience with automatic session creation
- ⚠️ **Important**: Users will be logged out if they switch tabs
- ✅ Login page will appear when they return to the tab
- ✅ Fast re-login process with fresh credentials

**When Logout Triggers:**
- Switching to a different browser tab
- Minimizing the browser window
- Alt+Tab to another application
- Locking the computer (Ctrl+Alt+Del or Cmd+Ctrl+Q)
- Switching virtual desktops

**When Logout Does NOT Trigger:**
- Scrolling within the page
- Opening DevTools
- Resizing the browser window
- Changing browser zoom level
- Idle time (no timeout, only visibility change)

### Testing the Feature

#### Manual Testing Steps:

1. **Test Tab Switch:**
   ```
   1. Login to the application
   2. Switch to a different browser tab
   3. Return to the application tab
   4. Verify you've been logged out and see login page
   ```

2. **Test Window Minimize:**
   ```
   1. Login to the application
   2. Minimize the browser window
   3. Restore the browser window
   4. Verify you've been logged out
   ```

3. **Test Application Switch:**
   ```
   1. Login to the application
   2. Press Alt+Tab (Windows/Linux) or Cmd+Tab (Mac) to switch apps
   3. Return to the browser
   4. Verify you've been logged out
   ```

4. **Test Multiple Sessions:**
   ```
   1. Open two browser tabs with the application
   2. Login in both tabs with the same user
   3. Switch away from one tab
   4. Verify only that tab logs out
   5. The other tab remains logged in until you switch away from it
   ```

#### Console Verification:

When visibility change triggers logout, you'll see:
```
AuthContext: Visibility change detected, logging out...
AuthContext: Signing out and clearing session...
```

When logging back in, you'll see:
```
AuthContext: Checking user...
Fetching profile for user: [user-id]
Profile found: { username: 'YLES-001', ... }
AuthContext: User found: YLES-001
```

### Technical Implementation Notes

- **Event Listener Cleanup**: The visibility change listener is properly cleaned up when the component unmounts to prevent memory leaks
- **Dependency Array**: The `useEffect` depends on `[user]` to ensure the handler always has access to the latest user state
- **Async Handling**: The `signOut` function is properly async and handles errors gracefully
- **Race Conditions**: The implementation handles race conditions where the user might be null during cleanup

### Configuration

Currently, the feature is **always enabled** for all users (both admin and players). There is no configuration option to disable it.

If you need to modify this behavior:

**Option 1: Disable for specific roles**
```javascript
const handleVisibilityChange = () => {
  if (document.hidden && user && user.role !== 'admin') {
    console.log('AuthContext: Visibility change detected, logging out...')
    signOut()
  }
}
```

**Option 2: Add a delay before logout**
```javascript
let timeoutId = null

const handleVisibilityChange = () => {
  if (document.hidden && user) {
    // Wait 5 seconds before logging out
    timeoutId = setTimeout(() => {
      console.log('AuthContext: Visibility change detected, logging out...')
      signOut()
    }, 5000)
  } else if (!document.hidden && timeoutId) {
    // User returned before timeout, cancel logout
    clearTimeout(timeoutId)
    timeoutId = null
  }
}
```

**Option 3: Make it configurable**
```javascript
// Add to .env
VITE_AUTO_LOGOUT_ON_VISIBILITY_CHANGE=true

// Use in code
const autoLogoutEnabled = import.meta.env.VITE_AUTO_LOGOUT_ON_VISIBILITY_CHANGE === 'true'

const handleVisibilityChange = () => {
  if (autoLogoutEnabled && document.hidden && user) {
    console.log('AuthContext: Visibility change detected, logging out...')
    signOut()
  }
}
```

### Browser Compatibility

The Page Visibility API is supported in all modern browsers:
- ✅ Chrome 33+
- ✅ Firefox 18+
- ✅ Safari 7+
- ✅ Edge 12+
- ✅ Opera 20+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

### Related Resources

- [MDN: Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [JWT Token Security Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
