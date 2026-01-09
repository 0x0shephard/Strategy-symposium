# Leaderboard Ranking System

## Overview
The leaderboard uses a **time-sensitive qualification ranking** system that prioritizes players who reach $1 billion valuation first, then ranks remaining players by their current valuation.

## Ranking Logic

### Primary Sort: Qualification Status
Players are divided into two groups:
1. **Qualified Players** - Reached $1B valuation
2. **Not Yet Qualified** - Below $1B valuation

### Secondary Sort: Time of Qualification (Qualified Players Only)
Among qualified players, ranking is determined by **who qualified first**:
- The first player to reach $1B = Rank #1 (Gold medal 🥇)
- The second player to reach $1B = Rank #2 (Silver medal 🥈)
- The third player to reach $1B = Rank #3 (Bronze medal 🥉)
- And so on...

**Important:** Once qualified, your rank among qualified players is **locked** based on qualification time, regardless of later valuation increases.

### Tertiary Sort: Current Valuation (Non-Qualified Players)
Among non-qualified players, ranking is by **highest current valuation**:
- Player with $980M = Rank #1 (in non-qualified section)
- Player with $950M = Rank #2 (in non-qualified section)
- And so on...

## SQL Query Order

```sql
SELECT *
FROM game_participants
WHERE game_id = 'xxx'
ORDER BY
  qualified DESC,           -- Qualified players first (true before false)
  qualified_at ASC,         -- Earliest qualification time first (nulls last)
  current_valuation DESC;   -- Highest valuation first (for non-qualified)
```

## Visual Representation

```
LEADERBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QUALIFIED (3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🥇 #1  YLES-042  ✓ QUALIFIED
       $1.25B (125.0%)
       Qualified 5 minutes ago

🥈 #2  YLES-015  ✓ QUALIFIED
       $1.18B (118.0%)
       Qualified 8 minutes ago

🥉 #3  YLES-089  ✓ QUALIFIED
       $1.02B (102.0%)
       Qualified 12 minutes ago

NOT YET QUALIFIED (47)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#1  YLES-123
    $980M (98.0%)

#2  YLES-067
    $945M (94.5%)

#3  YLES-201
    $920M (92.0%)
...
```

## Database Schema

### New Column: `qualified_at`
```sql
ALTER TABLE game_participants
ADD COLUMN qualified_at TIMESTAMP WITH TIME ZONE;
```

This timestamp is set **once** when a player first reaches $1B valuation and **never changes** afterward.

### Index for Performance
```sql
CREATE INDEX idx_game_participants_qualified_at
ON game_participants(game_id, qualified, qualified_at);
```

## How It Works

### Player Journey Example

**Scenario 1: Player A reaches $1B first**
```
T=0min  : Player A valuation = $320M, qualified = false, qualified_at = NULL
T=15min : Player A valuation = $1.05B, qualified = true, qualified_at = '2026-01-10 10:15:00'
                              ↳ Leaderboard Rank = #1 (first to qualify)
T=30min : Player A valuation = $1.25B, qualified = true, qualified_at = '2026-01-10 10:15:00'
                              ↳ Leaderboard Rank = #1 (still first, timestamp unchanged)
```

**Scenario 2: Player B reaches $1B second**
```
T=0min  : Player B valuation = $320M, qualified = false, qualified_at = NULL
T=20min : Player B valuation = $1.08B, qualified = true, qualified_at = '2026-01-10 10:20:00'
                              ↳ Leaderboard Rank = #2 (second to qualify, 5 min after Player A)
```

**Scenario 3: Player C never qualifies**
```
T=0min  : Player C valuation = $320M, qualified = false, qualified_at = NULL
T=45min : Player C valuation = $980M, qualified = false, qualified_at = NULL
                              ↳ Leaderboard Rank = #1 in "Not Yet Qualified" section
```

### Key Points

1. **Qualification is permanent**: Once `qualified = true`, it never goes back to false
2. **Timestamp is immutable**: `qualified_at` is set once and never updated
3. **Valuation can still change**: Players can continue increasing valuation after qualifying
4. **Ranking is time-based for qualified players**: Doesn't matter if you end with $1.5B or $1.01B - if you qualified first, you're rank #1

## Edge Cases

### What if two players qualify at the exact same second?
- Database timestamp precision is to the microsecond
- Extremely unlikely to have exact collision
- If it somehow happens, PostgreSQL will maintain insertion order

### What if a player's valuation drops below $1B after qualifying?
- This shouldn't happen in normal gameplay (valuations only go up)
- If it somehow occurs via manual database edit:
  - `qualified` should remain `true`
  - `qualified_at` should remain unchanged
  - Player keeps their qualified rank

### What if admin manually sets qualified = true?
- `qualified_at` won't be set automatically (migration only sets it via submit_player_choice)
- Player will appear in qualified section but without timestamp
- Will be ranked AFTER all players with timestamps (nullsFirst: false)

## UI Components

### Leaderboard Component (`src/components/Leaderboard.jsx`)

**Features:**
- Two sections: "QUALIFIED" and "NOT YET QUALIFIED"
- Gold/silver/bronze medals for top 3 qualified players
- Shows qualification time: "Qualified 5 minutes ago"
- Green ring around all qualified player cards
- Progress bar and valuation display for all players

**Sorting:**
```javascript
.order('qualified', { ascending: false })
.order('qualified_at', { ascending: true, nullsFirst: false })
.order('current_valuation', { ascending: false })
```

### Game Monitor Component (`src/components/GameMonitor.jsx`)

**Features:**
- Same ranking logic as public leaderboard
- Shows qualified badge next to player names
- Displays submission status for current scenario
- Real-time updates when players qualify

## Testing the Ranking

### Test Case 1: First Qualification
1. Create a game with 3 scenarios
2. Set option variables to reach $1B quickly (all 1.5x multipliers)
3. Have Player A submit choices
4. Verify Player A shows in "QUALIFIED" section with rank #1
5. Check `qualified_at` timestamp is set in database

### Test Case 2: Second Qualification
1. Have Player B submit choices and reach $1B
2. Verify Player A remains rank #1 (qualified first)
3. Verify Player B shows as rank #2 (qualified second)
4. Check both `qualified_at` timestamps, A's should be earlier

### Test Case 3: Higher Valuation, Later Qualification
1. Have Player C reach $1.5B but qualify AFTER Players A and B
2. Verify Player C shows as rank #3 despite highest valuation
3. This confirms ranking is by time, not final valuation

### Test Case 4: Non-Qualified Ranking
1. Have Player D reach $980M (not qualified)
2. Have Player E reach $850M (not qualified)
3. Verify they appear in "NOT YET QUALIFIED" section
4. Verify Player D ranks above Player E (higher valuation)

### SQL Verification
```sql
-- Check qualification order
SELECT
  u.username,
  gp.current_valuation / 1000000 as valuation_millions,
  gp.qualified,
  gp.qualified_at,
  RANK() OVER (
    PARTITION BY gp.game_id, gp.qualified
    ORDER BY
      CASE WHEN gp.qualified THEN gp.qualified_at END ASC,
      gp.current_valuation DESC
  ) as rank
FROM game_participants gp
JOIN users u ON u.id = gp.user_id
WHERE gp.game_id = 'YOUR_GAME_ID'
ORDER BY
  gp.qualified DESC,
  gp.qualified_at ASC NULLS LAST,
  gp.current_valuation DESC;
```

## Migration Notes

**Migration 019** adds:
- `qualified_at` column to `game_participants`
- Index on `(game_id, qualified, qualified_at)`
- Updated `submit_player_choice` function to set timestamp on first qualification

**Important:** This migration is **backward compatible**:
- Existing qualified players will have `qualified_at = NULL`
- They will appear at the bottom of qualified section (after all timestamped players)
- To fix: manually update their `qualified_at` based on `player_choices.submitted_at` when they crossed $1B

## Future Enhancements

Potential improvements:
1. **Trophy icons** for top 3 qualified players
2. **Qualification animation** when player crosses $1B threshold
3. **Qualification history** showing exact scenario where they qualified
4. **Photo finish** indicator if qualifications were within 1 minute
5. **Export qualified players** to CSV for prize distribution
