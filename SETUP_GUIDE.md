# Setup Guide - Strategy Symposium

## Quick Start (2 Steps!)

### Step 1: Run Database Migration

1. Open your Supabase project: https://amjbqilkjkeihaaawkpr.supabase.co
2. Navigate to: **SQL Editor**
3. Click **New Query**
4. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
5. Paste into the query editor
6. Click **Run** (or press Cmd/Ctrl + Enter)
7. You should see "Success. No rows returned" - this is correct!

### Step 2: Import All 300 Users (RECOMMENDED)

We've created a bulk import script that automatically creates all 300 users with pre-assigned credentials!

**Run this command:**

```bash
npm run import-users
```

This will:
- ✅ Create all 300 users (YLES-001 to YLES-300)
- ✅ Set YLES-001 and YLES-300 as **admin** role
- ✅ Set all other users as **player** role
- ✅ Skip users that already exist
- ✅ Show progress and summary

**That's it!** All users are ready to login.

To get a list of all credentials in CSV format:

```bash
npm run export-credentials
```

This creates `scripts/credentials.csv` with all 300 username/password combinations.

---

## Alternative: Manual User Creation

If you prefer to create users manually instead of using the bulk import:

### Step 2a: Create Admin Users Manually

You need to create the two admin accounts manually in Supabase Auth:

1. Go to: **Authentication** → **Users** → **Add User**

2. Create **YLES-001** (Admin):
   - Email: `YLES-001@racetounicorn.local`
   - Password: Choose a secure password (save it somewhere safe!)
   - Auto Confirm User: **✓ Yes**
   - Click **Create User**

3. Edit the user metadata:
   - Find the newly created user in the list
   - Click on the user
   - Scroll to **User Metadata** section
   - Click **Edit**
   - Replace the JSON with:
   ```json
   {
     "username": "YLES-001",
     "role": "admin"
   }
   ```
   - Click **Save**

4. Repeat for **YLES-300**:
   - Email: `YLES-300@racetounicorn.local`
   - Password: Choose a secure password
   - Auto Confirm User: **✓ Yes**
   - User Metadata:
   ```json
   {
     "username": "YLES-300",
     "role": "admin"
   }
   ```

### Step 3: Create Test Player (Optional)

To test the player experience:

1. Go to: **Authentication** → **Users** → **Add User**
2. Create a player:
   - Email: `testplayer@racetounicorn.local`
   - Password: Choose a password
   - Auto Confirm User: **✓ Yes**
   - User Metadata:
   ```json
   {
     "username": "testplayer",
     "role": "player"
   }
   ```

## Verify Setup

After creating the users, verify the database trigger worked:

1. Go to **Table Editor**
2. Select the `users` table
3. You should see 2-3 rows (your admin users and optional test player)
4. Each should have:
   - `id` matching the auth.users UUID
   - `username` (YLES-001, YLES-300, etc.)
   - `role` (admin or player)

## Run the Application

```bash
cd ss
npm run dev
```

Open http://localhost:5173 and login with:
- Username: `YLES-001`
- Password: (the password you set)

## Creating Your First Game

As an admin (YLES-001 or YLES-300):

1. Click **"Create New Game"**
2. Fill in:
   - Title: "Test Game"
   - Description: "My first game"
   - Starting Valuation: 320000000 (320M)
   - Target Valuation: 1000000000 (1B)
3. Click **"Save Basic Info"**
4. Go to **"Scenarios"** tab
5. Click **"Add Scenario"** to create Scenario 1
6. Click the scenario to select it
7. Go to **"Options"** tab
8. Enter values for all 5 options (6 variables each)
   - Example values from your data:
     - Option 1: RGM=1.18, MRE=0.92, UES=0.88, CRQ=0.94, RGA=0.95, CEM=0.87
     - Option 2: RGM=1.04, MRE=1.02, UES=1.05, CRQ=1.01, RGA=1.01, CEM=1.06
     - Option 3: RGM=1.01, MRE=1.03, UES=1.02, CRQ=1.01, RGA=1.01, CEM=1.02
     - Option 4: RGM=0.96, MRE=1.05, UES=1.02, CRQ=1.01, RGA=1.01, CEM=1.03
     - Option 5: RGM=1.14, MRE=0.88, UES=0.90, CRQ=0.95, RGA=0.93, CEM=0.90
9. Click **"Save All Options"**
10. Repeat steps 5-9 for more scenarios (up to 9 total)
11. Close the editor
12. Click **"Start"** to activate the game

## Testing the Full Flow

1. **As Admin**:
   - Start a game (as above)
   - Keep this window open to monitor

2. **As Player** (open incognito/private window):
   - Login as testplayer
   - Click **"Join Game"**
   - Click **"Play Now"**
   - Select an option
   - Click **"Submit Choice"**
   - Watch your valuation update

3. **Back to Admin Window**:
   - View the leaderboard update in real-time
   - Wait for the 10-minute timer (or reduce scenario duration to 1 minute for testing)
   - Game auto-advances to next scenario

## Bulk User Creation (Optional)

If you need to create many players, you can use SQL:

```sql
-- First, create the auth users in the Supabase dashboard
-- Then verify they appear in the users table automatically via trigger

-- To manually add users to the public.users table (if trigger doesn't work):
INSERT INTO public.users (id, username, role)
VALUES
  ('auth-user-uuid-1', 'player1', 'player'),
  ('auth-user-uuid-2', 'player2', 'player');
-- Replace auth-user-uuid-X with actual UUIDs from auth.users
```

## Troubleshooting

### Can't see user in `public.users` table?
- Check that the trigger `on_auth_user_created` exists
- Manually insert: `INSERT INTO public.users (id, username, role) VALUES ('user-uuid', 'username', 'role')`

### RLS errors when creating game?
- Verify user.role = 'admin' in the users table
- Check that RLS policies were created correctly

### Timer not working?
- Check that `scenario_ends_at` is set in `game_state` table
- Ensure game status is 'active'

### Valuation not updating?
- Verify `submit_player_choice` function exists
- Check that player has joined the game (exists in `game_participants`)

## Next Steps

- Create all 9 scenarios with your data
- Invite players to join (share login credentials)
- Run the game!
- Monitor progress on the admin dashboard
- View final results when game completes

## Support

If you encounter issues:
1. Check the browser console (F12) for errors
2. Check Supabase logs: Dashboard → Logs → Postgres Logs
3. Verify all tables were created in Table Editor
4. Ensure RLS policies exist: Go to table → RLS Policies tab
