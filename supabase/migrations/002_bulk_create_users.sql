-- =====================================================
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
  v_user_id := create_user_with_password('yles-001@racetounicorn.local', 'Yagm0yHecHh0', 'YLES-001', 'admin');
  v_user_id := create_user_with_password('yles-002@racetounicorn.local', 'oQ0drKDyov13', 'YLES-002', 'player');
  v_user_id := create_user_with_password('yles-003@racetounicorn.local', 'wNdgsmdg2pCu', 'YLES-003', 'player');
  v_user_id := create_user_with_password('yles-004@racetounicorn.local', 'rt9Fc46v4XtN', 'YLES-004', 'player');
  v_user_id := create_user_with_password('yles-005@racetounicorn.local', 'kN6CSnBsIpWo', 'YLES-005', 'player');
  v_user_id := create_user_with_password('yles-006@racetounicorn.local', 'b8BJf8TyoeK0', 'YLES-006', 'player');
  v_user_id := create_user_with_password('yles-007@racetounicorn.local', '0ys2XpOG4k2b', 'YLES-007', 'player');
  v_user_id := create_user_with_password('yles-008@racetounicorn.local', 'Jmlpt25W6d8W', 'YLES-008', 'player');
  v_user_id := create_user_with_password('yles-009@racetounicorn.local', 'dTbGFamaxysq', 'YLES-009', 'player');
  v_user_id := create_user_with_password('yles-010@racetounicorn.local', 'PPE9SH7tvOCP', 'YLES-010', 'player');
  v_user_id := create_user_with_password('yles-011@racetounicorn.local', 'MGdihHJNQHNB', 'YLES-011', 'player');
  v_user_id := create_user_with_password('yles-012@racetounicorn.local', '8hVv7tXToOfR', 'YLES-012', 'player');
  v_user_id := create_user_with_password('yles-013@racetounicorn.local', 'VtcqZYOmzcoP', 'YLES-013', 'player');
  v_user_id := create_user_with_password('yles-014@racetounicorn.local', 'NoYDEp2pvX4b', 'YLES-014', 'player');
  v_user_id := create_user_with_password('yles-015@racetounicorn.local', 'TSbOaPHtI4Xq', 'YLES-015', 'player');
  v_user_id := create_user_with_password('yles-016@racetounicorn.local', 'uOK9DHQzxwtQ', 'YLES-016', 'player');
  v_user_id := create_user_with_password('yles-017@racetounicorn.local', 'duo45zBW1s8P', 'YLES-017', 'player');
  v_user_id := create_user_with_password('yles-018@racetounicorn.local', '9eQZZQmyA7RZ', 'YLES-018', 'player');
  v_user_id := create_user_with_password('yles-019@racetounicorn.local', 'ZLYOKGR4y23d', 'YLES-019', 'player');
  v_user_id := create_user_with_password('yles-020@racetounicorn.local', 'RKQFVG1P24rf', 'YLES-020', 'player');
  v_user_id := create_user_with_password('yles-021@racetounicorn.local', 'V84nvjOFvuFx', 'YLES-021', 'player');
  v_user_id := create_user_with_password('yles-022@racetounicorn.local', 'aMCo8YXmvf4x', 'YLES-022', 'player');
  v_user_id := create_user_with_password('yles-023@racetounicorn.local', 'rurhEQdHL30C', 'YLES-023', 'player');
  v_user_id := create_user_with_password('yles-024@racetounicorn.local', '281G1f8jki9j', 'YLES-024', 'player');
  v_user_id := create_user_with_password('yles-025@racetounicorn.local', 'RHQmaS4bCZke', 'YLES-025', 'player');
  v_user_id := create_user_with_password('yles-026@racetounicorn.local', 'tts3HF6hOS2J', 'YLES-026', 'player');
  v_user_id := create_user_with_password('yles-027@racetounicorn.local', '0sWwWZN4YJkw', 'YLES-027', 'player');
  v_user_id := create_user_with_password('yles-028@racetounicorn.local', '4aOsZWoZXPLr', 'YLES-028', 'player');
  v_user_id := create_user_with_password('yles-029@racetounicorn.local', '0ZEx7UHsqLcW', 'YLES-029', 'player');
  v_user_id := create_user_with_password('yles-030@racetounicorn.local', 'sugklwsQsqiV', 'YLES-030', 'player');
  v_user_id := create_user_with_password('yles-031@racetounicorn.local', 'jSLK6VrWjLie', 'YLES-031', 'player');
  v_user_id := create_user_with_password('yles-032@racetounicorn.local', 'fhlYZungz6Xs', 'YLES-032', 'player');
  v_user_id := create_user_with_password('yles-033@racetounicorn.local', 'sW9PWEqlBOAm', 'YLES-033', 'player');
  v_user_id := create_user_with_password('yles-034@racetounicorn.local', 'EOUSIhQVDPoJ', 'YLES-034', 'player');
  v_user_id := create_user_with_password('yles-035@racetounicorn.local', 'eeHPqeKIOIT4', 'YLES-035', 'player');
  v_user_id := create_user_with_password('yles-036@racetounicorn.local', 'wASiumZ88uHw', 'YLES-036', 'player');
  v_user_id := create_user_with_password('yles-037@racetounicorn.local', 'NjC2orVtUXih', 'YLES-037', 'player');
  v_user_id := create_user_with_password('yles-038@racetounicorn.local', 'lud3DMhOvVKe', 'YLES-038', 'player');
  v_user_id := create_user_with_password('yles-039@racetounicorn.local', 'zB8kPFo6pWIZ', 'YLES-039', 'player');
  v_user_id := create_user_with_password('yles-040@racetounicorn.local', '73Omto0hK6uW', 'YLES-040', 'player');
  v_user_id := create_user_with_password('yles-041@racetounicorn.local', 'BUIrB4aega3J', 'YLES-041', 'player');
  v_user_id := create_user_with_password('yles-042@racetounicorn.local', 'pTpF4ectN9pZ', 'YLES-042', 'player');
  v_user_id := create_user_with_password('yles-043@racetounicorn.local', 'Wmt8P35I3HhN', 'YLES-043', 'player');
  v_user_id := create_user_with_password('yles-044@racetounicorn.local', 'AomjqBHn1Umd', 'YLES-044', 'player');
  v_user_id := create_user_with_password('yles-045@racetounicorn.local', '8QvfQXeHj6g2', 'YLES-045', 'player');
  v_user_id := create_user_with_password('yles-046@racetounicorn.local', 'L8ct3EbWuBNL', 'YLES-046', 'player');
  v_user_id := create_user_with_password('yles-047@racetounicorn.local', '9EDQ7xKycndy', 'YLES-047', 'player');
  v_user_id := create_user_with_password('yles-048@racetounicorn.local', 'pOurx3JNYsun', 'YLES-048', 'player');
  v_user_id := create_user_with_password('yles-049@racetounicorn.local', 'CQj9iHny0hFF', 'YLES-049', 'player');
  v_user_id := create_user_with_password('yles-050@racetounicorn.local', 'X6YHK5PhX3bl', 'YLES-050', 'player');
  v_user_id := create_user_with_password('yles-051@racetounicorn.local', '3ZHiXOBLlu9J', 'YLES-051', 'player');
  v_user_id := create_user_with_password('yles-052@racetounicorn.local', 'CGYHus8MhSsO', 'YLES-052', 'player');
  v_user_id := create_user_with_password('yles-053@racetounicorn.local', '5CScBnbRUs5v', 'YLES-053', 'player');
  v_user_id := create_user_with_password('yles-054@racetounicorn.local', 'SAAo1fmXPqDu', 'YLES-054', 'player');
  v_user_id := create_user_with_password('yles-055@racetounicorn.local', 'PcK1NA4sYGh5', 'YLES-055', 'player');
  v_user_id := create_user_with_password('yles-056@racetounicorn.local', '0uvhI3IxDpku', 'YLES-056', 'player');
  v_user_id := create_user_with_password('yles-057@racetounicorn.local', 'RaLq5ml1gawn', 'YLES-057', 'player');
  v_user_id := create_user_with_password('yles-058@racetounicorn.local', 'BxxiUnQizvfd', 'YLES-058', 'player');
  v_user_id := create_user_with_password('yles-059@racetounicorn.local', 'T1Fq8VFwYxQl', 'YLES-059', 'player');
  v_user_id := create_user_with_password('yles-060@racetounicorn.local', 'dXeyzgFZ0qmW', 'YLES-060', 'player');
  v_user_id := create_user_with_password('yles-061@racetounicorn.local', 'qFnd6HFE6Qy6', 'YLES-061', 'player');
  v_user_id := create_user_with_password('yles-062@racetounicorn.local', 't8YjfA7Qq7ug', 'YLES-062', 'player');
  v_user_id := create_user_with_password('yles-063@racetounicorn.local', 'HO5ouRKGqmpJ', 'YLES-063', 'player');
  v_user_id := create_user_with_password('yles-064@racetounicorn.local', 'whGRetBLhwSp', 'YLES-064', 'player');
  v_user_id := create_user_with_password('yles-065@racetounicorn.local', '1F3qkmB55uQi', 'YLES-065', 'player');
  v_user_id := create_user_with_password('yles-066@racetounicorn.local', 'bwfdZTXHTNu6', 'YLES-066', 'player');
  v_user_id := create_user_with_password('yles-067@racetounicorn.local', 'IVC16xfRDZF8', 'YLES-067', 'player');
  v_user_id := create_user_with_password('yles-068@racetounicorn.local', 'DzoofUNv2jA3', 'YLES-068', 'player');
  v_user_id := create_user_with_password('yles-069@racetounicorn.local', 'fMMvr2s4HUms', 'YLES-069', 'player');
  v_user_id := create_user_with_password('yles-070@racetounicorn.local', 'IXVRJnKrYc0t', 'YLES-070', 'player');
  v_user_id := create_user_with_password('yles-071@racetounicorn.local', 'f9BN74IRUQPV', 'YLES-071', 'player');
  v_user_id := create_user_with_password('yles-072@racetounicorn.local', '3phcN6yM36Ty', 'YLES-072', 'player');
  v_user_id := create_user_with_password('yles-073@racetounicorn.local', '1cuVrIHv1Car', 'YLES-073', 'player');
  v_user_id := create_user_with_password('yles-074@racetounicorn.local', 'g98Ek9b70bAj', 'YLES-074', 'player');
  v_user_id := create_user_with_password('yles-075@racetounicorn.local', 'MEMv0DDuo5i2', 'YLES-075', 'player');
  v_user_id := create_user_with_password('yles-076@racetounicorn.local', 'Lx2JP0Ej3T9q', 'YLES-076', 'player');
  v_user_id := create_user_with_password('yles-077@racetounicorn.local', 'lLri09hpBEh3', 'YLES-077', 'player');
  v_user_id := create_user_with_password('yles-078@racetounicorn.local', 'OcwP16oWKcSv', 'YLES-078', 'player');
  v_user_id := create_user_with_password('yles-079@racetounicorn.local', 'vtTWbrfKzpis', 'YLES-079', 'player');
  v_user_id := create_user_with_password('yles-080@racetounicorn.local', 'flVcVjZu0fq6', 'YLES-080', 'player');
  v_user_id := create_user_with_password('yles-081@racetounicorn.local', 'fy035KwKTyXH', 'YLES-081', 'player');
  v_user_id := create_user_with_password('yles-082@racetounicorn.local', '7W7bSe2v5Qfq', 'YLES-082', 'player');
  v_user_id := create_user_with_password('yles-083@racetounicorn.local', 'rkT5KqnF3Th5', 'YLES-083', 'player');
  v_user_id := create_user_with_password('yles-084@racetounicorn.local', '4hx3A0BL2Us8', 'YLES-084', 'player');
  v_user_id := create_user_with_password('yles-085@racetounicorn.local', 'O6mqE44VgCLi', 'YLES-085', 'player');
  v_user_id := create_user_with_password('yles-086@racetounicorn.local', '2mN88HAJJzHU', 'YLES-086', 'player');
  v_user_id := create_user_with_password('yles-087@racetounicorn.local', 'vSoiFgWh72l9', 'YLES-087', 'player');
  v_user_id := create_user_with_password('yles-088@racetounicorn.local', 'oePGDMAsmf0o', 'YLES-088', 'player');
  v_user_id := create_user_with_password('yles-089@racetounicorn.local', 'oCwItyygc6vc', 'YLES-089', 'player');
  v_user_id := create_user_with_password('yles-090@racetounicorn.local', 'HpWgbbeJrgmZ', 'YLES-090', 'player');
  v_user_id := create_user_with_password('yles-091@racetounicorn.local', 'MU5fLleBRJqu', 'YLES-091', 'player');
  v_user_id := create_user_with_password('yles-092@racetounicorn.local', 'yN4jftVc6vtZ', 'YLES-092', 'player');
  v_user_id := create_user_with_password('yles-093@racetounicorn.local', 's8Z5Yx9Gx9g7', 'YLES-093', 'player');
  v_user_id := create_user_with_password('yles-094@racetounicorn.local', 'f1dcNyRS7trn', 'YLES-094', 'player');
  v_user_id := create_user_with_password('yles-095@racetounicorn.local', 'S2Y7fXGVm44a', 'YLES-095', 'player');
  v_user_id := create_user_with_password('yles-096@racetounicorn.local', '6AFXnvnVrLGs', 'YLES-096', 'player');
  v_user_id := create_user_with_password('yles-097@racetounicorn.local', 'ZFvxdBN31HmD', 'YLES-097', 'player');
  v_user_id := create_user_with_password('yles-098@racetounicorn.local', 'Sowt3lX1Ektt', 'YLES-098', 'player');
  v_user_id := create_user_with_password('yles-099@racetounicorn.local', 'ko7r7M4NbeG5', 'YLES-099', 'player');
  v_user_id := create_user_with_password('yles-100@racetounicorn.local', '7atK7VDytHhH', 'YLES-100', 'player');
  v_user_id := create_user_with_password('yles-101@racetounicorn.local', 'LiUdLvyNWq0f', 'YLES-101', 'player');
  v_user_id := create_user_with_password('yles-102@racetounicorn.local', '83IsZ1pysbh6', 'YLES-102', 'player');
  v_user_id := create_user_with_password('yles-103@racetounicorn.local', 'KUPL4PqExI8g', 'YLES-103', 'player');
  v_user_id := create_user_with_password('yles-104@racetounicorn.local', 'ner60M25VZa3', 'YLES-104', 'player');
  v_user_id := create_user_with_password('yles-105@racetounicorn.local', 'e0uMNV2qwJMN', 'YLES-105', 'player');
  v_user_id := create_user_with_password('yles-106@racetounicorn.local', 'nEnfJhb5ZDIQ', 'YLES-106', 'player');
  v_user_id := create_user_with_password('yles-107@racetounicorn.local', 'DlzC5tHdJ5bA', 'YLES-107', 'player');
  v_user_id := create_user_with_password('yles-108@racetounicorn.local', '6OiNiNWMNEea', 'YLES-108', 'player');
  v_user_id := create_user_with_password('yles-109@racetounicorn.local', 'C2ImMoNcROQx', 'YLES-109', 'player');
  v_user_id := create_user_with_password('yles-110@racetounicorn.local', 'uyVKM2Xjprij', 'YLES-110', 'player');
  v_user_id := create_user_with_password('yles-111@racetounicorn.local', 'OhPAjWWzLb6g', 'YLES-111', 'player');
  v_user_id := create_user_with_password('yles-112@racetounicorn.local', 'ffIJ8sa7kquL', 'YLES-112', 'player');
  v_user_id := create_user_with_password('yles-113@racetounicorn.local', 'YHtxav3RRyGm', 'YLES-113', 'player');
  v_user_id := create_user_with_password('yles-114@racetounicorn.local', 'c6MNjSnkCoVp', 'YLES-114', 'player');
  v_user_id := create_user_with_password('yles-115@racetounicorn.local', '1MJFpNwm6BK0', 'YLES-115', 'player');
  v_user_id := create_user_with_password('yles-116@racetounicorn.local', 'pdLswNvh0SiM', 'YLES-116', 'player');
  v_user_id := create_user_with_password('yles-117@racetounicorn.local', 'qhDk69e8NMAY', 'YLES-117', 'player');
  v_user_id := create_user_with_password('yles-118@racetounicorn.local', 'i5F8Lcrdbn3X', 'YLES-118', 'player');
  v_user_id := create_user_with_password('yles-119@racetounicorn.local', '5OoX1ylsfRAW', 'YLES-119', 'player');
  v_user_id := create_user_with_password('yles-120@racetounicorn.local', '3FcagetHG6vZ', 'YLES-120', 'player');
  v_user_id := create_user_with_password('yles-121@racetounicorn.local', 'GelfhaqsByF9', 'YLES-121', 'player');
  v_user_id := create_user_with_password('yles-122@racetounicorn.local', 'JT0Po2fou1Qw', 'YLES-122', 'player');
  v_user_id := create_user_with_password('yles-123@racetounicorn.local', 'DhIjHrD2yeXv', 'YLES-123', 'player');
  v_user_id := create_user_with_password('yles-124@racetounicorn.local', 'CFbrZKVgceXD', 'YLES-124', 'player');
  v_user_id := create_user_with_password('yles-125@racetounicorn.local', 'y0wV9Jr3qxA7', 'YLES-125', 'player');
  v_user_id := create_user_with_password('yles-126@racetounicorn.local', 'dBgRvLgQVHNf', 'YLES-126', 'player');
  v_user_id := create_user_with_password('yles-127@racetounicorn.local', '7pym6sp6j0HE', 'YLES-127', 'player');
  v_user_id := create_user_with_password('yles-128@racetounicorn.local', 'smFBQyDyzTfZ', 'YLES-128', 'player');
  v_user_id := create_user_with_password('yles-129@racetounicorn.local', '2gRKF7jhQBUF', 'YLES-129', 'player');
  v_user_id := create_user_with_password('yles-130@racetounicorn.local', '0vX3DQ89wdej', 'YLES-130', 'player');
  v_user_id := create_user_with_password('yles-131@racetounicorn.local', 'tXdm6DPWqRxG', 'YLES-131', 'player');
  v_user_id := create_user_with_password('yles-132@racetounicorn.local', 'LXQdfhRlZIcn', 'YLES-132', 'player');
  v_user_id := create_user_with_password('yles-133@racetounicorn.local', 'OKGWpOGNh8fS', 'YLES-133', 'player');
  v_user_id := create_user_with_password('yles-134@racetounicorn.local', 'fysyYP1DJWtN', 'YLES-134', 'player');
  v_user_id := create_user_with_password('yles-135@racetounicorn.local', 'BnQRSw7NUYfI', 'YLES-135', 'player');
  v_user_id := create_user_with_password('yles-136@racetounicorn.local', 'wuDzQylsYkRV', 'YLES-136', 'player');
  v_user_id := create_user_with_password('yles-137@racetounicorn.local', 'eLztAeu1KctE', 'YLES-137', 'player');
  v_user_id := create_user_with_password('yles-138@racetounicorn.local', 'spp1QpilahYd', 'YLES-138', 'player');
  v_user_id := create_user_with_password('yles-139@racetounicorn.local', 'F4QqCNDdXLLo', 'YLES-139', 'player');
  v_user_id := create_user_with_password('yles-140@racetounicorn.local', 'Uy56stbS5Zph', 'YLES-140', 'player');
  v_user_id := create_user_with_password('yles-141@racetounicorn.local', 'SQms54SPvksc', 'YLES-141', 'player');
  v_user_id := create_user_with_password('yles-142@racetounicorn.local', 'yX5t34nwjAeV', 'YLES-142', 'player');
  v_user_id := create_user_with_password('yles-143@racetounicorn.local', 'VvRkR6Ob2snV', 'YLES-143', 'player');
  v_user_id := create_user_with_password('yles-144@racetounicorn.local', '1OwlAiJFgRtQ', 'YLES-144', 'player');
  v_user_id := create_user_with_password('yles-145@racetounicorn.local', '9LzpYvCwHt3s', 'YLES-145', 'player');
  v_user_id := create_user_with_password('yles-146@racetounicorn.local', 'cKlUJEaQ20wN', 'YLES-146', 'player');
  v_user_id := create_user_with_password('yles-147@racetounicorn.local', 'nNDzpvJceLyL', 'YLES-147', 'player');
  v_user_id := create_user_with_password('yles-148@racetounicorn.local', 'beIZn76IctEo', 'YLES-148', 'player');
  v_user_id := create_user_with_password('yles-149@racetounicorn.local', 'XPzyav3EZCqu', 'YLES-149', 'player');
  v_user_id := create_user_with_password('yles-150@racetounicorn.local', 'd2VA4PXE6Qod', 'YLES-150', 'player');
  v_user_id := create_user_with_password('yles-151@racetounicorn.local', 'sNWHwzz2Gf7m', 'YLES-151', 'player');
  v_user_id := create_user_with_password('yles-152@racetounicorn.local', 'iuQmpTr8QZ2Q', 'YLES-152', 'player');
  v_user_id := create_user_with_password('yles-153@racetounicorn.local', 'LQbuWdjui2W0', 'YLES-153', 'player');
  v_user_id := create_user_with_password('yles-154@racetounicorn.local', 'WXsFOsSP4qJW', 'YLES-154', 'player');
  v_user_id := create_user_with_password('yles-155@racetounicorn.local', 'a7VjNOtUSoGi', 'YLES-155', 'player');
  v_user_id := create_user_with_password('yles-156@racetounicorn.local', 'YbbCpeWB8vtB', 'YLES-156', 'player');
  v_user_id := create_user_with_password('yles-157@racetounicorn.local', '8o6vPjLu8WBb', 'YLES-157', 'player');
  v_user_id := create_user_with_password('yles-158@racetounicorn.local', 'NMzNCh4v4WoI', 'YLES-158', 'player');
  v_user_id := create_user_with_password('yles-159@racetounicorn.local', 'tMAKGJn5svUq', 'YLES-159', 'player');
  v_user_id := create_user_with_password('yles-160@racetounicorn.local', 'Dn5wAx728dEV', 'YLES-160', 'player');
  v_user_id := create_user_with_password('yles-161@racetounicorn.local', 'uKM1kysPueui', 'YLES-161', 'player');
  v_user_id := create_user_with_password('yles-162@racetounicorn.local', 'zXLHy8spwu7Z', 'YLES-162', 'player');
  v_user_id := create_user_with_password('yles-163@racetounicorn.local', 'ZYvARLEN38kB', 'YLES-163', 'player');
  v_user_id := create_user_with_password('yles-164@racetounicorn.local', 'm2hv82vboewN', 'YLES-164', 'player');
  v_user_id := create_user_with_password('yles-165@racetounicorn.local', '4C5E3S6i0Gdo', 'YLES-165', 'player');
  v_user_id := create_user_with_password('yles-166@racetounicorn.local', 'dqDJUjigUOEr', 'YLES-166', 'player');
  v_user_id := create_user_with_password('yles-167@racetounicorn.local', 'ZyC7I2y6dtpl', 'YLES-167', 'player');
  v_user_id := create_user_with_password('yles-168@racetounicorn.local', 'krJY4asyObuP', 'YLES-168', 'player');
  v_user_id := create_user_with_password('yles-169@racetounicorn.local', 'cmsxdmYvodUS', 'YLES-169', 'player');
  v_user_id := create_user_with_password('yles-170@racetounicorn.local', 'VibLlIavX5xn', 'YLES-170', 'player');
  v_user_id := create_user_with_password('yles-171@racetounicorn.local', '1JrlbVbzvywT', 'YLES-171', 'player');
  v_user_id := create_user_with_password('yles-172@racetounicorn.local', 'ox7xLY6pDTsQ', 'YLES-172', 'player');
  v_user_id := create_user_with_password('yles-173@racetounicorn.local', 'YH8N5MDk1723', 'YLES-173', 'player');
  v_user_id := create_user_with_password('yles-174@racetounicorn.local', 'xcM1s1ZH3F4E', 'YLES-174', 'player');
  v_user_id := create_user_with_password('yles-175@racetounicorn.local', 'wxpnXMCCyOl3', 'YLES-175', 'player');
  v_user_id := create_user_with_password('yles-176@racetounicorn.local', 'r6hlnI7pbBb8', 'YLES-176', 'player');
  v_user_id := create_user_with_password('yles-177@racetounicorn.local', 'nptQlYefGsHm', 'YLES-177', 'player');
  v_user_id := create_user_with_password('yles-178@racetounicorn.local', 'X0IOBhUHGbsi', 'YLES-178', 'player');
  v_user_id := create_user_with_password('yles-179@racetounicorn.local', 'HYN2JtslkKpk', 'YLES-179', 'player');
  v_user_id := create_user_with_password('yles-180@racetounicorn.local', '9k0gTn99R4Th', 'YLES-180', 'player');
  v_user_id := create_user_with_password('yles-181@racetounicorn.local', 'k15D30yYe2g7', 'YLES-181', 'player');
  v_user_id := create_user_with_password('yles-182@racetounicorn.local', 'jrbr5BbyvdrK', 'YLES-182', 'player');
  v_user_id := create_user_with_password('yles-183@racetounicorn.local', 'LwKYpgstnI4Y', 'YLES-183', 'player');
  v_user_id := create_user_with_password('yles-184@racetounicorn.local', 'v2cuoVHwPd4D', 'YLES-184', 'player');
  v_user_id := create_user_with_password('yles-185@racetounicorn.local', 'AaPwBtl5fcgZ', 'YLES-185', 'player');
  v_user_id := create_user_with_password('yles-186@racetounicorn.local', 'AevISFASprdl', 'YLES-186', 'player');
  v_user_id := create_user_with_password('yles-187@racetounicorn.local', 'gRdQjzg74ret', 'YLES-187', 'player');
  v_user_id := create_user_with_password('yles-188@racetounicorn.local', 'KFiHITFFDl5L', 'YLES-188', 'player');
  v_user_id := create_user_with_password('yles-189@racetounicorn.local', 'RYgoCRiVjazY', 'YLES-189', 'player');
  v_user_id := create_user_with_password('yles-190@racetounicorn.local', 'bqML64f9xmZz', 'YLES-190', 'player');
  v_user_id := create_user_with_password('yles-191@racetounicorn.local', '8SjpQlKbjYly', 'YLES-191', 'player');
  v_user_id := create_user_with_password('yles-192@racetounicorn.local', 'pGGrZtdFn6yF', 'YLES-192', 'player');
  v_user_id := create_user_with_password('yles-193@racetounicorn.local', 'EdFocYvFzdDv', 'YLES-193', 'player');
  v_user_id := create_user_with_password('yles-194@racetounicorn.local', 'fcR7xTrfIBol', 'YLES-194', 'player');
  v_user_id := create_user_with_password('yles-195@racetounicorn.local', 'BQeTRQrGCryg', 'YLES-195', 'player');
  v_user_id := create_user_with_password('yles-196@racetounicorn.local', 'Fwk4HdvJkVYi', 'YLES-196', 'player');
  v_user_id := create_user_with_password('yles-197@racetounicorn.local', 'iQSH0Rv94M5g', 'YLES-197', 'player');
  v_user_id := create_user_with_password('yles-198@racetounicorn.local', '7Gsasdbgqocm', 'YLES-198', 'player');
  v_user_id := create_user_with_password('yles-199@racetounicorn.local', 'qRgXevXDKXYh', 'YLES-199', 'player');
  v_user_id := create_user_with_password('yles-200@racetounicorn.local', 'G36XTU4b3hfB', 'YLES-200', 'player');
  v_user_id := create_user_with_password('yles-201@racetounicorn.local', 'llhVbtRZCm3J', 'YLES-201', 'player');
  v_user_id := create_user_with_password('yles-202@racetounicorn.local', '46zbwkdwE5Tt', 'YLES-202', 'player');
  v_user_id := create_user_with_password('yles-203@racetounicorn.local', '1pt1ZqmMyv2Y', 'YLES-203', 'player');
  v_user_id := create_user_with_password('yles-204@racetounicorn.local', 'rlqeIZVuYGvQ', 'YLES-204', 'player');
  v_user_id := create_user_with_password('yles-205@racetounicorn.local', 'M1QSr1PVnaFo', 'YLES-205', 'player');
  v_user_id := create_user_with_password('yles-206@racetounicorn.local', '8ciO1e70KVW7', 'YLES-206', 'player');
  v_user_id := create_user_with_password('yles-207@racetounicorn.local', 'htL7RiHYnFau', 'YLES-207', 'player');
  v_user_id := create_user_with_password('yles-208@racetounicorn.local', 'L0kDxtd3AHEJ', 'YLES-208', 'player');
  v_user_id := create_user_with_password('yles-209@racetounicorn.local', 'JF9prur2lqbZ', 'YLES-209', 'player');
  v_user_id := create_user_with_password('yles-210@racetounicorn.local', 'TmvG82ZI0EAC', 'YLES-210', 'player');
  v_user_id := create_user_with_password('yles-211@racetounicorn.local', 'yhvi1hReqO88', 'YLES-211', 'player');
  v_user_id := create_user_with_password('yles-212@racetounicorn.local', 'l4RReTF50rqx', 'YLES-212', 'player');
  v_user_id := create_user_with_password('yles-213@racetounicorn.local', 'ISzvRbUEz8zM', 'YLES-213', 'player');
  v_user_id := create_user_with_password('yles-214@racetounicorn.local', 'YuFIz4xCsq34', 'YLES-214', 'player');
  v_user_id := create_user_with_password('yles-215@racetounicorn.local', 'GMjOV8ZdrBbY', 'YLES-215', 'player');
  v_user_id := create_user_with_password('yles-216@racetounicorn.local', 'F5Jm8Iq5jHnU', 'YLES-216', 'player');
  v_user_id := create_user_with_password('yles-217@racetounicorn.local', 'BYWW4pLGrY8h', 'YLES-217', 'player');
  v_user_id := create_user_with_password('yles-218@racetounicorn.local', '3pcUXLKKkm2U', 'YLES-218', 'player');
  v_user_id := create_user_with_password('yles-219@racetounicorn.local', 'Ms3xp3tEteqF', 'YLES-219', 'player');
  v_user_id := create_user_with_password('yles-220@racetounicorn.local', 'T2TLCSpJ2GqU', 'YLES-220', 'player');
  v_user_id := create_user_with_password('yles-221@racetounicorn.local', 'rXlQ2fk3cK4b', 'YLES-221', 'player');
  v_user_id := create_user_with_password('yles-222@racetounicorn.local', 'lTc5vaJWR8DS', 'YLES-222', 'player');
  v_user_id := create_user_with_password('yles-223@racetounicorn.local', 'cfNnvIMGRp6m', 'YLES-223', 'player');
  v_user_id := create_user_with_password('yles-224@racetounicorn.local', 'Bp0ERWTAQ4S0', 'YLES-224', 'player');
  v_user_id := create_user_with_password('yles-225@racetounicorn.local', 'lVSwpqpDqDn6', 'YLES-225', 'player');
  v_user_id := create_user_with_password('yles-226@racetounicorn.local', 'GxheuIQLwunZ', 'YLES-226', 'player');
  v_user_id := create_user_with_password('yles-227@racetounicorn.local', 'DLk5t0QFSApr', 'YLES-227', 'player');
  v_user_id := create_user_with_password('yles-228@racetounicorn.local', '7Z4x4TUKpXx4', 'YLES-228', 'player');
  v_user_id := create_user_with_password('yles-229@racetounicorn.local', 'ZWPafNiRY7BD', 'YLES-229', 'player');
  v_user_id := create_user_with_password('yles-230@racetounicorn.local', 'MB3MIrdiK1fO', 'YLES-230', 'player');
  v_user_id := create_user_with_password('yles-231@racetounicorn.local', 'rbUsiNb8O0zz', 'YLES-231', 'player');
  v_user_id := create_user_with_password('yles-232@racetounicorn.local', '073PrRYc4WFa', 'YLES-232', 'player');
  v_user_id := create_user_with_password('yles-233@racetounicorn.local', 'fsQbvag4WLxE', 'YLES-233', 'player');
  v_user_id := create_user_with_password('yles-234@racetounicorn.local', 'NMOToso4DSci', 'YLES-234', 'player');
  v_user_id := create_user_with_password('yles-235@racetounicorn.local', 'vlG2haVIXETn', 'YLES-235', 'player');
  v_user_id := create_user_with_password('yles-236@racetounicorn.local', 'rZ12fUsvAVGe', 'YLES-236', 'player');
  v_user_id := create_user_with_password('yles-237@racetounicorn.local', 'lMkvOpTw5YgB', 'YLES-237', 'player');
  v_user_id := create_user_with_password('yles-238@racetounicorn.local', 'efWRODvQhWBG', 'YLES-238', 'player');
  v_user_id := create_user_with_password('yles-239@racetounicorn.local', 'ZZ7kusgqUnkV', 'YLES-239', 'player');
  v_user_id := create_user_with_password('yles-240@racetounicorn.local', 'EBlq4Rcvgrxh', 'YLES-240', 'player');
  v_user_id := create_user_with_password('yles-241@racetounicorn.local', 'yw44L4nsWyzw', 'YLES-241', 'player');
  v_user_id := create_user_with_password('yles-242@racetounicorn.local', 'YZbsXS3H4H2G', 'YLES-242', 'player');
  v_user_id := create_user_with_password('yles-243@racetounicorn.local', '2N336O2nYR7i', 'YLES-243', 'player');
  v_user_id := create_user_with_password('yles-244@racetounicorn.local', 'nRj0mvt6d8Ad', 'YLES-244', 'player');
  v_user_id := create_user_with_password('yles-245@racetounicorn.local', 'AtSERKhDD9Lx', 'YLES-245', 'player');
  v_user_id := create_user_with_password('yles-246@racetounicorn.local', 'MlkGPs27DPlJ', 'YLES-246', 'player');
  v_user_id := create_user_with_password('yles-247@racetounicorn.local', 'c6PB4rqMlbGx', 'YLES-247', 'player');
  v_user_id := create_user_with_password('yles-248@racetounicorn.local', 'app0V6NMQ2nh', 'YLES-248', 'player');
  v_user_id := create_user_with_password('yles-249@racetounicorn.local', 'WuYoEnqeyKKM', 'YLES-249', 'player');
  v_user_id := create_user_with_password('yles-250@racetounicorn.local', 'ij8gyXoWKRkI', 'YLES-250', 'player');
  v_user_id := create_user_with_password('yles-251@racetounicorn.local', 'YKYjPGBqaQjs', 'YLES-251', 'player');
  v_user_id := create_user_with_password('yles-252@racetounicorn.local', 'VLb5ZEDhK6Wi', 'YLES-252', 'player');
  v_user_id := create_user_with_password('yles-253@racetounicorn.local', 'LVFg8q7o6KCO', 'YLES-253', 'player');
  v_user_id := create_user_with_password('yles-254@racetounicorn.local', 'DOFGh3qBNNC6', 'YLES-254', 'player');
  v_user_id := create_user_with_password('yles-255@racetounicorn.local', 'VPLaPygpIYsI', 'YLES-255', 'player');
  v_user_id := create_user_with_password('yles-256@racetounicorn.local', 'FCgfnZi3yzHC', 'YLES-256', 'player');
  v_user_id := create_user_with_password('yles-257@racetounicorn.local', 'LXuldncCTbzr', 'YLES-257', 'player');
  v_user_id := create_user_with_password('yles-258@racetounicorn.local', 'AIksWnmJM4XS', 'YLES-258', 'player');
  v_user_id := create_user_with_password('yles-259@racetounicorn.local', 'ZIlK3JZpcFMa', 'YLES-259', 'player');
  v_user_id := create_user_with_password('yles-260@racetounicorn.local', 'SMezW5bf4TDw', 'YLES-260', 'player');
  v_user_id := create_user_with_password('yles-261@racetounicorn.local', 'dR009J3SKYyl', 'YLES-261', 'player');
  v_user_id := create_user_with_password('yles-262@racetounicorn.local', 'xMnsBY3uw7za', 'YLES-262', 'player');
  v_user_id := create_user_with_password('yles-263@racetounicorn.local', 'anAEmxRy7rxp', 'YLES-263', 'player');
  v_user_id := create_user_with_password('yles-264@racetounicorn.local', 'olalHz2ipy8H', 'YLES-264', 'player');
  v_user_id := create_user_with_password('yles-265@racetounicorn.local', 'BWPBpjrvzxgd', 'YLES-265', 'player');
  v_user_id := create_user_with_password('yles-266@racetounicorn.local', 'hbpJNKZecpQm', 'YLES-266', 'player');
  v_user_id := create_user_with_password('yles-267@racetounicorn.local', 'jbWFp1hrq2Go', 'YLES-267', 'player');
  v_user_id := create_user_with_password('yles-268@racetounicorn.local', 'DWF014COTphb', 'YLES-268', 'player');
  v_user_id := create_user_with_password('yles-269@racetounicorn.local', 'ZbV3CuWo0J6N', 'YLES-269', 'player');
  v_user_id := create_user_with_password('yles-270@racetounicorn.local', 'ut3A8ThZFW5e', 'YLES-270', 'player');
  v_user_id := create_user_with_password('yles-271@racetounicorn.local', 'QgDDg0R6tX4X', 'YLES-271', 'player');
  v_user_id := create_user_with_password('yles-272@racetounicorn.local', 'bLAZSvY47p52', 'YLES-272', 'player');
  v_user_id := create_user_with_password('yles-273@racetounicorn.local', 'Ml3YD64G4EBp', 'YLES-273', 'player');
  v_user_id := create_user_with_password('yles-274@racetounicorn.local', 'EgAfZ4I1darj', 'YLES-274', 'player');
  v_user_id := create_user_with_password('yles-275@racetounicorn.local', 'Y2Ff54KWyIoT', 'YLES-275', 'player');
  v_user_id := create_user_with_password('yles-276@racetounicorn.local', 'uy8r9m5WulBS', 'YLES-276', 'player');
  v_user_id := create_user_with_password('yles-277@racetounicorn.local', 'qqM5EArJu0GW', 'YLES-277', 'player');
  v_user_id := create_user_with_password('yles-278@racetounicorn.local', 'jnCxnjlWFBHB', 'YLES-278', 'player');
  v_user_id := create_user_with_password('yles-279@racetounicorn.local', 'QBgjdKyg8Stf', 'YLES-279', 'player');
  v_user_id := create_user_with_password('yles-280@racetounicorn.local', 'u3R8L3DjBNkT', 'YLES-280', 'player');
  v_user_id := create_user_with_password('yles-281@racetounicorn.local', 'bNjJ6XxHMCxI', 'YLES-281', 'player');
  v_user_id := create_user_with_password('yles-282@racetounicorn.local', 'csLLoaA0QFx7', 'YLES-282', 'player');
  v_user_id := create_user_with_password('yles-283@racetounicorn.local', 'B9dCK40oyHx6', 'YLES-283', 'player');
  v_user_id := create_user_with_password('yles-284@racetounicorn.local', '10jGkcq7MM4M', 'YLES-284', 'player');
  v_user_id := create_user_with_password('yles-285@racetounicorn.local', 'E3kVR8t6Nhly', 'YLES-285', 'player');
  v_user_id := create_user_with_password('yles-286@racetounicorn.local', 'qOe7o8xiWdje', 'YLES-286', 'player');
  v_user_id := create_user_with_password('yles-287@racetounicorn.local', 'Az2fiyGTjhvf', 'YLES-287', 'player');
  v_user_id := create_user_with_password('yles-288@racetounicorn.local', 'eY35JSZtcLSb', 'YLES-288', 'player');
  v_user_id := create_user_with_password('yles-289@racetounicorn.local', 'd7FPCxC68Q2l', 'YLES-289', 'player');
  v_user_id := create_user_with_password('yles-290@racetounicorn.local', 'pOUaH7Ao7th8', 'YLES-290', 'player');
  v_user_id := create_user_with_password('yles-291@racetounicorn.local', 'h2PIWscBaMrY', 'YLES-291', 'player');
  v_user_id := create_user_with_password('yles-292@racetounicorn.local', 'mzeOBxGPwjsu', 'YLES-292', 'player');
  v_user_id := create_user_with_password('yles-293@racetounicorn.local', 'hHeI91DM5OGG', 'YLES-293', 'player');
  v_user_id := create_user_with_password('yles-294@racetounicorn.local', 'p74OxVFVHqqu', 'YLES-294', 'player');
  v_user_id := create_user_with_password('yles-295@racetounicorn.local', 'qx47wntCYUUD', 'YLES-295', 'player');
  v_user_id := create_user_with_password('yles-296@racetounicorn.local', '8witSx1thIwy', 'YLES-296', 'player');
  v_user_id := create_user_with_password('yles-297@racetounicorn.local', 'TH6QBsUiFQPD', 'YLES-297', 'player');
  v_user_id := create_user_with_password('yles-298@racetounicorn.local', 'uLjsCTNPhIC5', 'YLES-298', 'player');
  v_user_id := create_user_with_password('yles-299@racetounicorn.local', 'WOHV8q4ahc56', 'YLES-299', 'player');
  v_user_id := create_user_with_password('yles-300@racetounicorn.local', 'Ig2Ax2wCF5M3', 'YLES-300', 'admin');

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
