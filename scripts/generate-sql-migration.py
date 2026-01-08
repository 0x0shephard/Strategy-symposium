#!/usr/bin/env python3
import json

# Email domain must match src/lib/supabase.js
EMAIL_DOMAIN = 'racetounicorn.app'

# Read users JSON
with open('scripts/users.json', 'r') as f:
    data = json.load(f)

# Start SQL file
sql = """-- =====================================================
-- BULK USER CREATION SCRIPT
-- Creates all 300 users (YLES-001 to YLES-300)
-- YLES-001 and YLES-300 are admins, rest are players
-- =====================================================

-- Enable pgcrypto extension for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Function to create a user with hashed password
CREATE OR REPLACE FUNCTION create_user_with_password(
  p_email TEXT,
  p_password TEXT,
  p_username TEXT,
  p_role user_role
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_encrypted_password TEXT;
  v_existing_user_id UUID;
BEGIN
  -- Check if user already exists
  SELECT id INTO v_existing_user_id
  FROM auth.users
  WHERE email = p_email;

  -- If user exists, return their ID and skip creation
  IF v_existing_user_id IS NOT NULL THEN
    RETURN v_existing_user_id;
  END IF;

  -- Generate a new UUID
  v_user_id := gen_random_uuid();

  -- Hash the password using crypt
  v_encrypted_password := crypt(p_password, gen_salt('bf'));

  -- Insert into auth.users
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    aud,
    role
  ) VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    p_email,
    v_encrypted_password,
    NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('username', p_username, 'role', p_role),
    NOW(),
    NOW(),
    '',
    'authenticated',
    'authenticated'
  );

  RETURN v_user_id;
END;
$$;

-- Create all users
DO $$
DECLARE
  v_user_id UUID;
BEGIN
"""

# Add all users
for user in data['users']:
    username = user['username']
    # Convert username to correct email format (must match src/lib/supabase.js)
    email = f"{username.lower()}@{EMAIL_DOMAIN}"
    password = user['password']

    # Determine role
    role = 'admin' if username in ['YLES-001', 'YLES-300'] else 'player'

    sql += f"  v_user_id := create_user_with_password('{email}', '{password}', '{username}', '{role}');\n"

sql += """
  RAISE NOTICE 'Successfully created all 300 users!';
END $$;

-- Verify user count
SELECT role, COUNT(*) as count
FROM public.users
GROUP BY role
ORDER BY role;

-- List admin users
SELECT username, role
FROM public.users
WHERE role = 'admin'
ORDER BY username;

-- Clean up the temporary function
DROP FUNCTION IF EXISTS create_user_with_password(TEXT, TEXT, TEXT, user_role);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ All 300 users created successfully!';
  RAISE NOTICE '👑 Admins: YLES-001, YLES-300';
  RAISE NOTICE '👤 Players: YLES-002 through YLES-299';
END $$;
"""

# Write to file
with open('supabase/migrations/002_bulk_create_users.sql', 'w') as f:
    f.write(sql)

print("✅ SQL migration file generated: supabase/migrations/002_bulk_create_users.sql")
print(f"📊 Total users: {len(data['users'])}")
print("👉 Copy and run this file in Supabase SQL Editor")
