-- Seed data for local development and testing
-- Run with: supabase db reset (applies migrations + seed.sql)

-- Note: User must be created via Supabase Auth UI or API first
-- This script assumes a test user exists with ID: 00000000-0000-0000-0000-000000000001
-- Update the user_id below to match your test user

-- Create test family
INSERT INTO public.families (id, name)
VALUES ('11111111-1111-1111-1111-111111111111', 'Test Family')
ON CONFLICT (id) DO NOTHING;

-- Add test user to family (update user_id to match your test user)
-- Get user_id from Supabase Auth dashboard or via: SELECT id FROM auth.users LIMIT 1;
INSERT INTO public.family_members (family_id, user_id, role)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000001', -- UPDATE THIS to your test user ID
  'admin'
)
ON CONFLICT (family_id, user_id) DO NOTHING;

-- Create test baby
INSERT INTO public.babies (
  id, family_id, name, date_of_birth, timezone, primary_feeding_style, sex
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'Test Baby',
  CURRENT_DATE - INTERVAL '60 days',
  'UTC',
  'bottle',
  'm'
)
ON CONFLICT (id) DO NOTHING;

-- Create sample events for today
INSERT INTO public.events (
  id, baby_id, family_id, type, subtype, start_time, end_time, amount, unit, created_by
)
VALUES
  -- Feed events (today)
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'feed',
    'bottle',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '1 hour 45 minutes',
    120,
    'ml',
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'feed',
    'bottle',
    NOW() - INTERVAL '5 hours',
    NOW() - INTERVAL '4 hours 30 minutes',
    150,
    'ml',
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'feed',
    'breast_left',
    NOW() - INTERVAL '8 hours',
    NOW() - INTERVAL '7 hours 30 minutes',
    NULL,
    NULL,
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  
  -- Sleep events (today)
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'sleep',
    'nap',
    NOW() - INTERVAL '3 hours',
    NOW() - INTERVAL '2 hours',
    NULL,
    NULL,
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'sleep',
    'night',
    NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '8 hours',
    NULL,
    NULL,
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  
  -- Diaper events (today)
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'diaper',
    'wet',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour',
    NULL,
    NULL,
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'diaper',
    'both',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes',
    NULL,
    NULL,
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  ),
  
  -- Tummy time (today)
  (
    gen_random_uuid(),
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'tummy_time',
    NULL,
    NOW() - INTERVAL '4 hours',
    NOW() - INTERVAL '3 hours 45 minutes',
    15,
    'min',
    '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
  );

-- Create events for yesterday (for history testing)
INSERT INTO public.events (
  id, baby_id, family_id, type, subtype, start_time, end_time, amount, unit, created_by
)
SELECT
  gen_random_uuid(),
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  type,
  subtype,
  start_time - INTERVAL '1 day',
  end_time - INTERVAL '1 day',
  amount,
  unit,
  '00000000-0000-0000-0000-000000000001' -- UPDATE THIS
FROM public.events
WHERE baby_id = '22222222-2222-2222-2222-222222222222'
AND DATE(start_time) = CURRENT_DATE
LIMIT 5;

-- Create app settings for test user
INSERT INTO public.app_settings (user_id, units_preference, ai_data_sharing_enabled)
VALUES (
  '00000000-0000-0000-0000-000000000001', -- UPDATE THIS
  'metric',
  true
)
ON CONFLICT (user_id) DO NOTHING;


