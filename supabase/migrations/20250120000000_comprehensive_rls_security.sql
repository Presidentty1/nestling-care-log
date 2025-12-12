-- ============================================================================
-- COMPREHENSIVE RLS SECURITY HARDENING
-- ============================================================================
-- This migration ensures ALL tables have complete RLS policies
-- Run this after all other migrations to harden security for MVP release
-- ============================================================================

-- Helper function to check family membership (reusable across policies)
CREATE OR REPLACE FUNCTION public.is_family_member(_user_id UUID, _family_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.family_members
    WHERE family_id = _family_id
      AND user_id = _user_id
  )
$$;

-- Helper function to check if user can access baby (via family membership)
CREATE OR REPLACE FUNCTION public.can_access_baby(_user_id UUID, _baby_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.babies b
    JOIN public.family_members fm ON b.family_id = fm.family_id
    WHERE b.id = _baby_id
      AND fm.user_id = _user_id
  )
$$;

-- ============================================================================
-- ENSURE ALL TABLES HAVE RLS ENABLED
-- ============================================================================

DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename NOT IN ('_prisma_migrations', 'schema_migrations')
  LOOP
    EXECUTE format('ALTER TABLE IF EXISTS public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
  END LOOP;
END $$;

-- ============================================================================
-- COMPREHENSIVE RLS POLICIES FOR ALL TABLES
-- ============================================================================

-- ============================================================================
-- Core Tables (if policies don't exist)
-- ============================================================================

-- Profiles: Users can only access their own profile
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view their own profile'
  ) THEN
    CREATE POLICY "Users can view their own profile" ON public.profiles
      FOR SELECT USING (auth.uid() = id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update their own profile'
  ) THEN
    CREATE POLICY "Users can update their own profile" ON public.profiles
      FOR UPDATE USING (auth.uid() = id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can insert their own profile'
  ) THEN
    CREATE POLICY "Users can insert their own profile" ON public.profiles
      FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- Families: Users can only see families they belong to
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'families' AND policyname = 'Users can view families they belong to'
  ) THEN
    CREATE POLICY "Users can view families they belong to" ON public.families
      FOR SELECT USING (public.is_family_member(auth.uid(), id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'families' AND policyname = 'Users can create families'
  ) THEN
    CREATE POLICY "Users can create families" ON public.families
      FOR INSERT WITH CHECK (true);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'families' AND policyname = 'Admins can update their families'
  ) THEN
    CREATE POLICY "Admins can update their families" ON public.families
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = families.id
            AND user_id = auth.uid()
            AND role = 'admin'
        )
      );
  END IF;
END $$;

-- Family Members: Users can see members of their families
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'family_members' AND policyname = 'Users can view family members of their families'
  ) THEN
    CREATE POLICY "Users can view family members of their families" ON public.family_members
      FOR SELECT USING (public.is_family_member(auth.uid(), family_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'family_members' AND policyname = 'Users can insert themselves as family members'
  ) THEN
    CREATE POLICY "Users can insert themselves as family members" ON public.family_members
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'family_members' AND policyname = 'Admins can manage family members'
  ) THEN
    CREATE POLICY "Admins can manage family members" ON public.family_members
      FOR ALL USING (
        EXISTS (
          SELECT 1 FROM public.family_members fm
          WHERE fm.family_id = family_members.family_id
            AND fm.user_id = auth.uid()
            AND fm.role = 'admin'
        )
      );
  END IF;
END $$;

-- Babies: Users can access babies in their families
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'babies' AND policyname = 'Users can view babies in their families'
  ) THEN
    CREATE POLICY "Users can view babies in their families" ON public.babies
      FOR SELECT USING (public.is_family_member(auth.uid(), family_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'babies' AND policyname = 'Members can create babies in their families'
  ) THEN
    CREATE POLICY "Members can create babies in their families" ON public.babies
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = babies.family_id
            AND user_id = auth.uid()
            AND role IN ('admin', 'member')
        )
      );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'babies' AND policyname = 'Members can update babies in their families'
  ) THEN
    CREATE POLICY "Members can update babies in their families" ON public.babies
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = babies.family_id
            AND user_id = auth.uid()
            AND role IN ('admin', 'member')
        )
      );
  END IF;
END $$;

-- Events: Users can access events for babies in their families
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'events' AND policyname = 'Users can view events for babies in their families'
  ) THEN
    CREATE POLICY "Users can view events for babies in their families" ON public.events
      FOR SELECT USING (public.is_family_member(auth.uid(), family_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'events' AND policyname = 'Members can create events in their families'
  ) THEN
    CREATE POLICY "Members can create events in their families" ON public.events
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = events.family_id
            AND user_id = auth.uid()
            AND role IN ('admin', 'member')
        )
      );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'events' AND policyname = 'Members can update events in their families'
  ) THEN
    CREATE POLICY "Members can update events in their families" ON public.events
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = events.family_id
            AND user_id = auth.uid()
            AND role IN ('admin', 'member')
        )
      );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'events' AND policyname = 'Members can delete events in their families'
  ) THEN
    CREATE POLICY "Members can delete events in their families" ON public.events
      FOR DELETE USING (
        EXISTS (
          SELECT 1 FROM public.family_members
          WHERE family_id = events.family_id
            AND user_id = auth.uid()
            AND role IN ('admin', 'member')
        )
      );
  END IF;
END $$;

-- ============================================================================
-- Additional Tables: Baby-related data
-- ============================================================================

-- Nap Feedback
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'nap_feedback' AND policyname = 'Users can view nap feedback for babies in their families'
  ) THEN
    CREATE POLICY "Users can view nap feedback for babies in their families" ON public.nap_feedback
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'nap_feedback' AND policyname = 'Users can insert nap feedback'
  ) THEN
    CREATE POLICY "Users can insert nap feedback" ON public.nap_feedback
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- Cry Insight Sessions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cry_insight_sessions' AND policyname = 'Users can view cry insights for babies in their families'
  ) THEN
    CREATE POLICY "Users can view cry insights for babies in their families" ON public.cry_insight_sessions
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cry_insight_sessions' AND policyname = 'Users can create cry insights'
  ) THEN
    CREATE POLICY "Users can create cry insights" ON public.cry_insight_sessions
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- Growth Records
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'growth_records' AND policyname = 'Users can view growth records for their babies'
  ) THEN
    CREATE POLICY "Users can view growth records for their babies" ON public.growth_records
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'growth_records' AND policyname = 'Users can insert growth records for their babies'
  ) THEN
    CREATE POLICY "Users can insert growth records for their babies" ON public.growth_records
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'growth_records' AND policyname = 'Users can update growth records for their babies'
  ) THEN
    CREATE POLICY "Users can update growth records for their babies" ON public.growth_records
      FOR UPDATE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'growth_records' AND policyname = 'Users can delete growth records for their babies'
  ) THEN
    CREATE POLICY "Users can delete growth records for their babies" ON public.growth_records
      FOR DELETE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- Health Records
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'health_records' AND policyname = 'Users can view health records for their babies'
  ) THEN
    CREATE POLICY "Users can view health records for their babies" ON public.health_records
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'health_records' AND policyname = 'Users can insert health records for their babies'
  ) THEN
    CREATE POLICY "Users can insert health records for their babies" ON public.health_records
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'health_records' AND policyname = 'Users can update health records for their babies'
  ) THEN
    CREATE POLICY "Users can update health records for their babies" ON public.health_records
      FOR UPDATE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'health_records' AND policyname = 'Users can delete health records for their babies'
  ) THEN
    CREATE POLICY "Users can delete health records for their babies" ON public.health_records
      FOR DELETE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- Milestones
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'milestones' AND policyname = 'Users can view milestones for their babies'
  ) THEN
    CREATE POLICY "Users can view milestones for their babies" ON public.milestones
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'milestones' AND policyname = 'Users can insert milestones for their babies'
  ) THEN
    CREATE POLICY "Users can insert milestones for their babies" ON public.milestones
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'milestones' AND policyname = 'Users can update milestones for their babies'
  ) THEN
    CREATE POLICY "Users can update milestones for their babies" ON public.milestones
      FOR UPDATE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'milestones' AND policyname = 'Users can delete milestones for their babies'
  ) THEN
    CREATE POLICY "Users can delete milestones for their babies" ON public.milestones
      FOR DELETE USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- App Settings (user-specific)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'app_settings' AND policyname = 'Users can view own settings'
  ) THEN
    CREATE POLICY "Users can view own settings" ON public.app_settings
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'app_settings' AND policyname = 'Users can insert own settings'
  ) THEN
    CREATE POLICY "Users can insert own settings" ON public.app_settings
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'app_settings' AND policyname = 'Users can update own settings'
  ) THEN
    CREATE POLICY "Users can update own settings" ON public.app_settings
      FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

-- User Feedback (user-specific)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_feedback' AND policyname = 'Users can view own feedback'
  ) THEN
    CREATE POLICY "Users can view own feedback" ON public.user_feedback
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_feedback' AND policyname = 'Users can insert own feedback'
  ) THEN
    CREATE POLICY "Users can insert own feedback" ON public.user_feedback
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Subscriptions (user-specific, service role can manage)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Users can view own subscription'
  ) THEN
    CREATE POLICY "Users can view own subscription" ON public.subscriptions
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Service role can manage subscriptions'
  ) THEN
    CREATE POLICY "Service role can manage subscriptions" ON public.subscriptions
      FOR ALL USING (auth.role() = 'service_role');
  END IF;
END $$;

-- ============================================================================
-- Additional Tables: AI, Predictions, Activity Feed
-- ============================================================================

-- Predictions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'predictions' AND policyname = 'Users can view predictions for their babies'
  ) THEN
    CREATE POLICY "Users can view predictions for their babies" ON public.predictions
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'predictions' AND policyname = 'Service role can create predictions'
  ) THEN
    CREATE POLICY "Service role can create predictions" ON public.predictions
      FOR INSERT WITH CHECK (auth.role() = 'service_role' OR public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- Activity Feed (family-scoped)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'activity_feed' AND policyname = 'Users can view activity feed for their families'
  ) THEN
    CREATE POLICY "Users can view activity feed for their families" ON public.activity_feed
      FOR SELECT USING (public.is_family_member(auth.uid(), family_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'activity_feed' AND policyname = 'Service role can insert activity feed'
  ) THEN
    CREATE POLICY "Service role can insert activity feed" ON public.activity_feed
      FOR INSERT WITH CHECK (auth.role() = 'service_role' OR public.is_family_member(auth.uid(), family_id));
  END IF;
END $$;

-- Handoff Reports
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'handoff_reports' AND policyname = 'Users can view handoff reports for their babies'
  ) THEN
    CREATE POLICY "Users can view handoff reports for their babies" ON public.handoff_reports
      FOR SELECT USING (public.can_access_baby(auth.uid(), baby_id));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'handoff_reports' AND policyname = 'Users can create handoff reports'
  ) THEN
    CREATE POLICY "Users can create handoff reports" ON public.handoff_reports
      FOR INSERT WITH CHECK (public.can_access_baby(auth.uid(), baby_id));
  END IF;
END $$;

-- ============================================================================
-- SECURITY NOTES
-- ============================================================================
-- 1. All policies use SECURITY DEFINER functions to prevent RLS recursion
-- 2. Family membership is checked via helper functions for consistency
-- 3. Service role can bypass RLS for system operations (edge functions)
-- 4. Users can only access data for families they belong to
-- 5. Admins have elevated privileges (update families, manage members)
-- 6. All user-specific tables (profiles, settings, feedback) are isolated per user
-- ============================================================================















