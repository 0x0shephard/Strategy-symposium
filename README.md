# Strategy Symposium - Strategic Growth Simulation Game

A multiplayer game application where players compete to reach a 1 billion valuation by making strategic business decisions across multiple scenarios.

## Features

- **Admin Portal**: Create and manage games with multiple scenarios and options
- **Player Portal**: Join games, make strategic choices, track progress in real-time
- **Real-time Leaderboard**: See rankings update live as players make decisions
- **Auto-progression**: Games automatically advance through scenarios with countdown timers
- **Glassmorphic UI**: Modern, beautiful interface with dark theme

## Tech Stack

- **Frontend**: React 19 + Vite
- **Styling**: Tailwind CSS with custom glassmorphism design
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Routing**: React Router DOM
- **Date Handling**: date-fns

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Supabase Database

1. Log in to your Supabase project at https://supabase.com
2. Go to the SQL Editor
3. Run the migration file: `supabase/migrations/001_initial_schema.sql`
   - This creates all tables, RLS policies, functions, and triggers

### 3. Create Admin Users

After running the migration, you need to create the admin users:

1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add User" and create two admin accounts:

**Admin 1:**
- Email: `YLES-001@racetounicorn.local`
- Password: (choose a secure password)
- Metadata: Add `{"username": "YLES-001", "role": "admin"}`

**Admin 2:**
- Email: `YLES-300@racetounicorn.local`
- Password: (choose a secure password)
- Metadata: Add `{"username": "YLES-300", "role": "admin"}`

The trigger in the database will automatically create their profiles in the `public.users` table.

### 4. Create Player Users (Optional)

To create player accounts, repeat the same process:

**Example Player:**
- Email: `player1@racetounicorn.local`
- Password: (choose a password)
- Metadata: Add `{"username": "player1", "role": "player"}`

### 5. Environment Variables

The `.env` file is already configured with your Supabase credentials:

```
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 6. Run the Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

## Usage Guide

### For Admins

1. **Login**: Use admin credentials (YLES-001 or YLES-300)

2. **Create a Game**:
   - Click "Create New Game"
   - Fill in basic info (title, description, valuations)
   - Add scenarios (click "Add Scenario" for each)
   - For each scenario, configure 5 options with 6 variables each:
     - RGM, MRE, UES, CRQ, RGA, CEM
   - Save the game (status: Draft)

3. **Start a Game**:
   - Click "Start" on a draft game
   - Game status changes to "Active"
   - First scenario timer begins (10 minutes by default)
   - Players can now join

4. **Monitor a Game**:
   - View participants and their valuations
   - See who has submitted choices
   - Game auto-advances after each scenario timer expires

### For Players

1. **Login**: Use player credentials

2. **Join a Game**:
   - Browse available active games
   - Click "Join Game"
   - You're added to the game with starting valuation

3. **Play a Scenario**:
   - Click "Play Now" on an active game
   - Review the current scenario
   - View 5 options with their multiplier values
   - Select an option (values > 1 are positive, < 1 are negative)
   - Submit your choice
   - Your valuation updates based on: `new_valuation = current × RGM × MRE × UES × CRQ × RGA × CEM`

4. **Track Progress**:
   - View real-time leaderboard
   - Monitor your progress toward 1 billion target
   - Wait for scenario to end and next one to begin

### Game Flow Example

**Starting State:**
- All players start with 320M valuation
- Target is 1B (1000M)
- Game has 9 scenarios

**Scenario 1:**
- Timer: 10 minutes
- Player chooses Option 3
- Variables: RGM=1.01, MRE=1.03, UES=1.02, CRQ=1.01, RGA=1.01, CEM=1.02
- New valuation: 320M × 1.01 × 1.03 × 1.02 × 1.01 × 1.01 × 1.02 ≈ 333M

**Scenario 2:**
- Timer starts automatically
- Player makes another choice
- Valuation compounds on previous result
- Process continues...

**Game End:**
- After final scenario (or all scenarios complete)
- Game status → "Completed"
- Final leaderboard shows winners
- Players who reached 1B+ are marked as winners

## Database Schema Overview

### Main Tables

- **users**: User profiles (username, role)
- **games**: Game configurations
- **scenarios**: Scenarios within each game
- **options**: 5 options per scenario with 6 variables
- **game_participants**: Players in each game with current valuations
- **player_choices**: Historical record of choices and valuations
- **game_state**: Current scenario and timer for active games

### Key Functions

- `submit_player_choice()`: Submits choice and calculates new valuation
- `start_game()`: Initializes game state with first scenario
- `advance_scenario()`: Moves to next scenario or completes game

## Development

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

### Lint Code

```bash
npm run lint
```

## Troubleshooting

**Issue**: Can't login as admin
- **Solution**: Verify admin users were created in Supabase Auth with correct metadata

**Issue**: RLS policy errors
- **Solution**: Check that all policies in migration were created successfully

**Issue**: Game won't start
- **Solution**: Ensure game has at least one scenario with options

**Issue**: Valuation not updating
- **Solution**: Check that `submit_player_choice` function exists and player has joined game

## License

MIT

## Support

For issues or questions, please contact your administrator or check the Supabase logs for detailed error messages.
