import { createClient } from '@supabase/supabase-js'
import fs from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Load environment variables
const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'https://amjbqilkjkeihaaawkpr.supabase.co'
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFtamJxaWxramtlaWhhYWF3a3ByIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzgxNzIwMiwiZXhwIjoyMDgzMzkzMjAyfQ.Uq_q5Uxob3ElcuOWxdIpPQFYPO4EE-SHWgUj1lokkD8'

// Create Supabase admin client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

// Admin usernames
const ADMIN_USERNAMES = ['YLES-001', 'YLES-300']

async function importUsers() {
  try {
    // Read users JSON file
    const usersFile = join(__dirname, 'users.json')
    const usersData = JSON.parse(fs.readFileSync(usersFile, 'utf-8'))

    console.log(`\n🚀 Starting bulk user import: ${usersData.totalUsers} users\n`)

    // Pre-check: Verify database is set up
    console.log('🔍 Checking database setup...')
    const { data: tableCheck, error: tableError } = await supabase
      .from('users')
      .select('count')
      .limit(1)

    if (tableError) {
      console.error('\n❌ Database not set up correctly!')
      console.error('Error:', tableError.message)
      console.error('\n⚠️  Did you run the database migration?')
      console.error('👉 Run: supabase/migrations/001_initial_schema.sql in Supabase SQL Editor\n')
      process.exit(1)
    }
    console.log('✅ Database connection OK\n')

    let successCount = 0
    let errorCount = 0
    let skippedCount = 0

    for (let i = 0; i < usersData.users.length; i++) {
      const user = usersData.users[i]
      const role = ADMIN_USERNAMES.includes(user.username) ? 'admin' : 'player'

      try {
        // Check if user already exists
        const { data: existingUsers } = await supabase.auth.admin.listUsers()
        const userExists = existingUsers?.users?.find(u => u.email === user.email)

        if (userExists) {
          console.log(`⏭️  [${i + 1}/${usersData.totalUsers}] Skipped ${user.username} (already exists)`)
          skippedCount++
          continue
        }

        // Create user with Supabase Auth Admin API
        const { data, error } = await supabase.auth.admin.createUser({
          email: user.email,
          password: user.password,
          email_confirm: true,
          user_metadata: {
            username: user.username,
            role: role
          }
        })

        if (error) {
          throw error
        }

        successCount++
        const badge = role === 'admin' ? '👑' : '👤'
        console.log(`✅ [${i + 1}/${usersData.totalUsers}] ${badge} Created ${user.username} (${role})`)

        // Add a small delay to avoid rate limiting
        if (i > 0 && i % 10 === 0) {
          await new Promise(resolve => setTimeout(resolve, 1000))
        }

      } catch (err) {
        errorCount++
        console.error(`❌ [${i + 1}/${usersData.totalUsers}] Failed ${user.username}: ${err.message}`)

        // Show detailed error for first failure only
        if (errorCount === 1) {
          console.error('\n📋 Detailed error information:')
          console.error(JSON.stringify(err, null, 2))
          console.error('\n⚠️  Stopping import. Fix the issue and try again.\n')
          process.exit(1)
        }
      }
    }

    // Summary
    console.log(`\n${'='.repeat(60)}`)
    console.log('📊 IMPORT SUMMARY')
    console.log(`${'='.repeat(60)}`)
    console.log(`✅ Successfully created: ${successCount} users`)
    console.log(`⏭️  Skipped (already exist): ${skippedCount} users`)
    console.log(`❌ Failed: ${errorCount} users`)
    console.log(`📈 Total processed: ${successCount + errorCount + skippedCount}/${usersData.totalUsers}`)
    console.log(`${'='.repeat(60)}\n`)

    // Verify admin users
    console.log('🔍 Verifying admin users...\n')
    for (const adminUsername of ADMIN_USERNAMES) {
      const { data: profile } = await supabase
        .from('users')
        .select('*')
        .eq('username', adminUsername)
        .single()

      if (profile && profile.role === 'admin') {
        console.log(`👑 ${adminUsername}: Admin role confirmed`)
      } else {
        console.log(`⚠️  ${adminUsername}: Admin role NOT set (check database trigger)`)
      }
    }

    console.log('\n✨ User import completed!\n')

  } catch (error) {
    console.error('\n💥 Fatal error during import:', error.message)
    process.exit(1)
  }
}

// Run the import
importUsers()
