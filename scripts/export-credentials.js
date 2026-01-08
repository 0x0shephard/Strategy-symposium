import fs from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

function exportCredentials() {
  try {
    // Read users JSON file
    const usersFile = join(__dirname, 'users.json')
    const usersData = JSON.parse(fs.readFileSync(usersFile, 'utf-8'))

    // Create CSV content
    let csvContent = 'Username,Email,Password,Role,Login Instructions\n'

    usersData.users.forEach(user => {
      const role = (user.username === 'YLES-001' || user.username === 'YLES-300') ? 'Admin' : 'Player'
      const loginInstructions = 'Login with username (not email) at the app'

      csvContent += `${user.username},${user.email},${user.password},${role},"${loginInstructions}"\n`
    })

    // Save to CSV file
    const csvFile = join(__dirname, 'credentials.csv')
    fs.writeFileSync(csvFile, csvContent)

    console.log('✅ Credentials exported successfully!')
    console.log(`📄 File: ${csvFile}`)
    console.log(`📊 Total: ${usersData.users.length} users`)

    // Create admin-only file
    const adminUsers = usersData.users.filter(u => u.username === 'YLES-001' || u.username === 'YLES-300')
    let adminCsvContent = 'Username,Email,Password,Role\n'
    adminUsers.forEach(user => {
      adminCsvContent += `${user.username},${user.email},${user.password},Admin\n`
    })

    const adminCsvFile = join(__dirname, 'credentials-admin.csv')
    fs.writeFileSync(adminCsvFile, adminCsvContent)

    console.log(`👑 Admin credentials: ${adminCsvFile}`)
    console.log(`\n📋 Next steps:`)
    console.log(`  1. Keep these files secure`)
    console.log(`  2. Distribute credentials to participants`)
    console.log(`  3. Delete CSV files after distribution for security`)

  } catch (error) {
    console.error('❌ Error exporting credentials:', error.message)
    process.exit(1)
  }
}

exportCredentials()
