-- ============================================================================
-- CRITICAL SECURITY FIX: Implement Secure Role Architecture
-- ============================================================================
-- This migration creates a dedicated user_roles table with security definer
-- functions to prevent privilege escalation and recursive RLS issues.

-- 1. Create role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'member', 'viewer');

-- 2. Create user_roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id, family_id)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. Create security definer function for single role check
CREATE OR REPLACE FUNCTION public.has_family_role(_user_id UUID, _family_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id
      AND family_id = _family_id
      AND role = _role
  )
$$;

-- 4. Create security definer function for multiple role check
CREATE OR REPLACE FUNCTION public.has_any_family_role(_user_id UUID, _family_id UUID, _roles app_role[])
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id
      AND family_id = _family_id
      AND role = ANY(_roles)
  )
$$;

-- 5. Migrate existing data from family_members to user_roles
INSERT INTO public.user_roles (user_id, family_id, role)
SELECT 
  user_id, 
  family_id, 
  role::app_role
FROM public.family_members
ON CONFLICT (user_id, family_id) DO NOTHING;

-- 6. Create RLS policies for user_roles table
CREATE POLICY "Users can view their own roles"
ON public.user_roles FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Family admins can view family roles"
ON public.user_roles FOR SELECT
USING (public.has_family_role(auth.uid(), family_id, 'admin'));

CREATE POLICY "Family admins can manage roles"
ON public.user_roles FOR ALL
USING (public.has_family_role(auth.uid(), family_id, 'admin'));

-- 7. Update family_members policies
DROP POLICY IF EXISTS "Admins can manage family members" ON public.family_members;
DROP POLICY IF EXISTS "Users can insert themselves as family members" ON public.family_members;
DROP POLICY IF EXISTS "Users can view family members of their families" ON public.family_members;

CREATE POLICY "Family admins can manage members"
ON public.family_members FOR ALL
USING (public.has_family_role(auth.uid(), family_id, 'admin'));

CREATE POLICY "Users can insert themselves"
ON public.family_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Family members can view members"
ON public.family_members FOR SELECT
USING (EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND family_id = family_members.family_id));

-- 8. Update babies table policies
DROP POLICY IF EXISTS "Members can create babies in their families" ON public.babies;
DROP POLICY IF EXISTS "Members can update babies in their families" ON public.babies;
DROP POLICY IF EXISTS "Users can view babies in their families" ON public.babies;

CREATE POLICY "Members can create babies"
ON public.babies FOR INSERT
WITH CHECK (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Members can update babies"
ON public.babies FOR UPDATE
USING (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Admins can delete babies"
ON public.babies FOR DELETE
USING (public.has_family_role(auth.uid(), family_id, 'admin'));

CREATE POLICY "Family members can view babies"
ON public.babies FOR SELECT
USING (EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND family_id = babies.family_id));

-- 9. Update events table policies
DROP POLICY IF EXISTS "Admins and members can create events" ON public.events;
DROP POLICY IF EXISTS "Admins and members can update events" ON public.events;
DROP POLICY IF EXISTS "Admins and members can delete events" ON public.events;
DROP POLICY IF EXISTS "Users can view events for babies in their families" ON public.events;

CREATE POLICY "Members can create events"
ON public.events FOR INSERT
WITH CHECK (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Members can update events"
ON public.events FOR UPDATE
USING (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Members can delete events"
ON public.events FOR DELETE
USING (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Family members can view events"
ON public.events FOR SELECT
USING (EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND family_id = events.family_id));

-- 10. Update activity_feed policies
DROP POLICY IF EXISTS "Members can create activity feed entries" ON public.activity_feed;
DROP POLICY IF EXISTS "Users can view activity feed for their families" ON public.activity_feed;

CREATE POLICY "Members can create activity entries"
ON public.activity_feed FOR INSERT
WITH CHECK (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Family members can view activity"
ON public.activity_feed FOR SELECT
USING (EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND family_id = activity_feed.family_id));

-- 11. Update cry_logs policies
DROP POLICY IF EXISTS "Members can create cry logs" ON public.cry_logs;
DROP POLICY IF EXISTS "Members can update cry logs" ON public.cry_logs;
DROP POLICY IF EXISTS "Members can delete cry logs" ON public.cry_logs;
DROP POLICY IF EXISTS "Users can view cry logs for babies in their families" ON public.cry_logs;

CREATE POLICY "Members can create cry logs"
ON public.cry_logs FOR INSERT
WITH CHECK (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Members can update cry logs"
ON public.cry_logs FOR UPDATE
USING (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Members can delete cry logs"
ON public.cry_logs FOR DELETE
USING (public.has_any_family_role(auth.uid(), family_id, ARRAY['admin', 'member']::app_role[]));

CREATE POLICY "Family members can view cry logs"
ON public.cry_logs FOR SELECT
USING (EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND family_id = cry_logs.family_id));

-- 12. Create trigger to keep family_members.role in sync with user_roles
CREATE OR REPLACE FUNCTION public.sync_family_member_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    INSERT INTO public.user_roles (user_id, family_id, role)
    VALUES (NEW.user_id, NEW.family_id, NEW.role::app_role)
    ON CONFLICT (user_id, family_id) 
    DO UPDATE SET role = NEW.role::app_role;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.user_roles 
    WHERE user_id = OLD.user_id AND family_id = OLD.family_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER sync_to_user_roles
AFTER INSERT OR UPDATE OR DELETE ON public.family_members
FOR EACH ROW EXECUTE FUNCTION public.sync_family_member_role();