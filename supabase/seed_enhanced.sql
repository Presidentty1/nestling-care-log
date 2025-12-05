-- ============================================================================
-- ENHANCED SEED SCRIPT FOR MVP RELEASE
-- ============================================================================
-- This script creates realistic test data for development and QA
-- Run with: supabase db reset (applies migrations + seed.sql)
-- ============================================================================

-- ============================================================================
-- SETUP: Create test users via Supabase Auth API first
-- ============================================================================
-- This script assumes test users exist. To create them:
-- 1. Use Supabase Dashboard → Authentication → Add User
-- 2. Or use: SELECT auth.users FROM auth.users LIMIT 1;
-- 3. Update user IDs below to match your test users
-- ============================================================================

-- Get first user from auth.users (for automated seeding)
DO $$
DECLARE
  test_user_id UUID;
  test_family_id UUID := '11111111-1111-1111-1111-111111111111';
  test_baby_id UUID := '22222222-2222-2222-2222-222222222222';
BEGIN
  -- Get first authenticated user
  SELECT id INTO test_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE NOTICE 'No users found in auth.users. Please create a test user first.';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Using test user: %', test_user_id;
  
  -- ============================================================================
  -- CREATE TEST FAMILY
  -- ============================================================================
  INSERT INTO public.families (id, name)
  VALUES (test_family_id, 'Test Family')
  ON CONFLICT (id) DO NOTHING;
  
  -- Add test user to family as admin
  INSERT INTO public.family_members (family_id, user_id, role)
  VALUES (test_family_id, test_user_id, 'admin')
  ON CONFLICT (family_id, user_id) DO NOTHING;
  
  -- ============================================================================
  -- CREATE TEST BABY
  -- ============================================================================
  INSERT INTO public.babies (
    id, family_id, name, date_of_birth, timezone, primary_feeding_style, sex
  )
  VALUES (
    test_baby_id,
    test_family_id,
    'Test Baby',
    CURRENT_DATE - INTERVAL '60 days',
    'America/New_York',
    'combo',
    'prefer_not_to_say'
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- ============================================================================
  -- CREATE SAMPLE EVENTS FOR TODAY
  -- ============================================================================
  
  -- Feed events (last 12 hours)
  INSERT INTO public.events (
    baby_id, family_id, type, subtype, start_time, end_time, amount, unit, created_by
  )
  VALUES
    -- Recent feed (2 hours ago)
    (
      test_baby_id,
      test_family_id,
      'feed',
      'bottle',
      NOW() - INTERVAL '2 hours',
      NOW() - INTERVAL '1 hour 45 minutes',
      120,
      'ml',
      test_user_id
    ),
    -- Earlier feed (5 hours ago)
    (
      test_baby_id,
      test_family_id,
      'feed',
      'breast',
      NOW() - INTERVAL '5 hours',
      NOW() - INTERVAL '4 hours 30 minutes',
      NULL,
      NULL,
      test_user_id
    ),
    -- Morning feed (8 hours ago)
    (
      test_baby_id,
      test_family_id,
      'feed',
      'bottle',
      NOW() - INTERVAL '8 hours',
      NOW() - INTERVAL '7 hours 30 minutes',
      150,
      'ml',
      test_user_id
    ),
    
    -- Sleep events
    (
      test_baby_id,
      test_family_id,
      'sleep',
      'nap',
      NOW() - INTERVAL '3 hours',
      NOW() - INTERVAL '2 hours',
      NULL,
      NULL,
      test_user_id
    ),
    (
      test_baby_id,
      test_family_id,
      'sleep',
      'night',
      NOW() - INTERVAL '12 hours',
      NOW() - INTERVAL '8 hours',
      NULL,
      NULL,
      test_user_id
    ),
    
    -- Diaper events
    (
      test_baby_id,
      test_family_id,
      'diaper',
      'wet',
      NOW() - INTERVAL '1 hour',
      NOW() - INTERVAL '1 hour',
      NULL,
      NULL,
      test_user_id
    ),
    (
      test_baby_id,
      test_family_id,
      'diaper',
      'both',
      NOW() - INTERVAL '30 minutes',
      NOW() - INTERVAL '30 minutes',
      NULL,
      NULL,
      test_user_id
    ),
    
    -- Tummy time
    (
      test_baby_id,
      test_family_id,
      'tummy_time',
      NULL,
      NOW() - INTERVAL '4 hours',
      NOW() - INTERVAL '3 hours 45 minutes',
      15,
      'min',
      test_user_id
    );
  
  -- ============================================================================
  -- CREATE EVENTS FOR YESTERDAY (for history testing)
  -- ============================================================================
  INSERT INTO public.events (
    baby_id, family_id, type, subtype, start_time, end_time, amount, unit, created_by
  )
  SELECT
    test_baby_id,
    test_family_id,
    type,
    subtype,
    start_time - INTERVAL '1 day',
    end_time - INTERVAL '1 day',
    amount,
    unit,
    test_user_id
  FROM public.events
  WHERE baby_id = test_baby_id
    AND DATE(start_time) = CURRENT_DATE
  LIMIT 8;
  
  -- ============================================================================
  -- CREATE EVENTS FOR LAST WEEK (for analytics testing)
  -- ============================================================================
  INSERT INTO public.events (
    baby_id, family_id, type, subtype, start_time, end_time, amount, unit, created_by
  )
  SELECT
    test_baby_id,
    test_family_id,
    type,
    subtype,
    start_time - INTERVAL '7 days',
    end_time - INTERVAL '7 days',
    amount,
    unit,
    test_user_id
  FROM public.events
  WHERE baby_id = test_baby_id
    AND DATE(start_time) = CURRENT_DATE
  LIMIT 5;
  
  -- ============================================================================
  -- CREATE APP SETTINGS
  -- ============================================================================
  INSERT INTO public.app_settings (user_id, units_preference, ai_data_sharing_enabled)
  VALUES (
    test_user_id,
    'metric',
    true
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  -- ============================================================================
  -- CREATE PROFILE
  -- ============================================================================
  INSERT INTO public.profiles (id, email, name, ai_data_sharing_enabled)
  SELECT 
    id,
    email,
    'Test User',
    true
  FROM auth.users
  WHERE id = test_user_id
  ON CONFLICT (id) DO NOTHING;
  
  -- ============================================================================
  -- CREATE SAMPLE GROWTH RECORDS
  -- ============================================================================
  INSERT INTO public.growth_records (baby_id, recorded_at, weight_kg, height_cm, head_circumference_cm)
  VALUES
    (test_baby_id, CURRENT_DATE - INTERVAL '30 days', 3.5, 50, 35),
    (test_baby_id, CURRENT_DATE - INTERVAL '15 days', 4.2, 53, 36),
    (test_baby_id, CURRENT_DATE, 4.8, 56, 37)
  ON CONFLICT DO NOTHING;
  
  -- ============================================================================
  -- CREATE SAMPLE MILESTONES
  -- ============================================================================
  INSERT INTO public.milestones (baby_id, category, title, description, achieved_at, created_by)
  VALUES
    (test_baby_id, 'motor', 'First Smile', 'Baby smiled for the first time', CURRENT_DATE - INTERVAL '45 days', test_user_id),
    (test_baby_id, 'social', 'Eye Contact', 'Baby made sustained eye contact', CURRENT_DATE - INTERVAL '40 days', test_user_id),
    (test_baby_id, 'motor', 'Head Control', 'Baby can hold head up during tummy time', CURRENT_DATE - INTERVAL '20 days', test_user_id)
  ON CONFLICT DO NOTHING;
  
  -- ============================================================================
  -- CREATE SAMPLE NAP FEEDBACK
  -- ============================================================================
  INSERT INTO public.nap_feedback (baby_id, predicted_start, predicted_end, rating)
  VALUES
    (test_baby_id, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '2 hours', 'just_right'),
    (test_baby_id, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '2 hours', 'too_early')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Seed data created successfully!';
  RAISE NOTICE 'Family ID: %', test_family_id;
  RAISE NOTICE 'Baby ID: %', test_baby_id;
  
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (for manual checking)
-- ============================================================================
-- Run these to verify seed data:
-- SELECT COUNT(*) FROM public.families;
-- SELECT COUNT(*) FROM public.babies;
-- SELECT COUNT(*) FROM public.events;
-- SELECT COUNT(*) FROM public.growth_records;
-- SELECT COUNT(*) FROM public.milestones;
-- ============================================================================









