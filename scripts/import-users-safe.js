import { createClient } from '@supabase/supabase-js'
import fs from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Load environment variables from .env file
import dotenv from 'dotenv'
import { resolve } from 'path'

// Load .env from project root
dotenv.config({ path: resolve(__dirname, '../.env') })

const SUPABASE_URL = process.env.VITE_SUPABASE_URL
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY

// Validate environment variables
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('\n❌ Missing environment variables!\n')
  console.error('   VITE_SUPABASE_URL:', SUPABASE_URL ? '✓ Set' : '✗ Missing')
  console.error('   SUPABASE_SERVICE_ROLE_KEY:', SUPABASE_SERVICE_ROLE_KEY ? '✓ Set' : '✗ Missing')
  console.error('\n   Make sure .env file exists at project root with:')
  console.error('   VITE_SUPABASE_URL=https://mgjmzuodkpymffxsjilm.supabase.co')
  console.error('   SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>\n')
  process.exit(1)
}

console.log('📡 Connecting to:', SUPABASE_URL)
console.log('🔑 Service key:', SUPABASE_SERVICE_ROLE_KEY.substring(0, 30) + '...\n')

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

    console.log(`\n🚀 Starting safe user import: ${usersData.totalUsers} users\n`)

    let successCount = 0
    let errorCount = 0
    let skippedCount = 0

    // Import one user at a time for better error handling
    for (let i = 0; i < usersData.users.length; i++) {
      const user = usersData.users[i]
      const role = ADMIN_USERNAMES.includes(user.username) ? 'admin' : 'player'

      try {
        // Create user with Supabase Auth Admin API
        const { data, error } = await supabase.auth.admin.createUser({
          email: user.email.replace('@investo.local', '@racetounicorn.app'),
          password: user.password,
          email_confirm: true,
          user_metadata: {
            username: user.username,
            role: role
          }
        })

        if (error) {
          // If user already exists, that's OK - skip it
          if (error.code === 'email_exists' || (error.message && error.message.includes('already registered'))) {
            console.log(`⏭️  [${i + 1}/${usersData.totalUsers}] Skipped ${user.username} (already exists)`)
            skippedCount++
            continue // Skip to next user instead of throwing
          } else {
            throw error
          }
        } else {
          successCount++
          const badge = role === 'admin' ? '👑' : '👤'
          console.log(`✅ [${i + 1}/${usersData.totalUsers}] ${badge} Created ${user.username} (${role})`)
        }

        // Add a small delay to avoid rate limiting
        if (i > 0 && i % 5 === 0) {
          await new Promise(resolve => setTimeout(resolve, 1000))
        }

      } catch (err) {
        errorCount++
        console.error(`❌ [${i + 1}/${usersData.totalUsers}] Failed ${user.username}:`, err.message)

        // Show detailed error for first 3 failures
        if (errorCount <= 3) {
          console.error('   Details:', JSON.stringify(err, null, 2))
        }

        // If first 5 users all fail (not counting skips), stop
        if (i < 5 && errorCount >= 5 && successCount === 0 && skippedCount === 0) {
          console.error('\n⚠️  First 5 users all failed. Stopping import.')
          console.error('   Please check your Supabase configuration.')
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

    if (successCount > 0) {
      console.log('✨ User import completed successfully!\n')
    } else {
      console.error('⚠️  No users were created. Please check the errors above.\n')
    }

  } catch (error) {
    console.error('\n💥 Fatal error during import:', error.message)
    process.exit(1)
  }
}

// Run the import
importUsers()
