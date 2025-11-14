-- Create users table extension for profile data
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create families table
CREATE TABLE IF NOT EXISTS public.families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create family_members junction table
CREATE TABLE IF NOT EXISTS public.family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(family_id, user_id)
);

-- Create babies table
CREATE TABLE IF NOT EXISTS public.babies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  due_date DATE,
  sex TEXT CHECK (sex IN ('male', 'female', 'other', 'prefer_not_to_say')),
  timezone TEXT DEFAULT 'UTC',
  primary_feeding_style TEXT CHECK (primary_feeding_style IN ('breast', 'formula', 'combo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create events table for all baby activities
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('feed', 'sleep', 'diaper', 'tummy_time', 'medication', 'other')),
  subtype TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  amount DECIMAL,
  unit TEXT,
  note TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create nap_feedback table
CREATE TABLE IF NOT EXISTS public.nap_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  predicted_start TIMESTAMP WITH TIME ZONE NOT NULL,
  predicted_end TIMESTAMP WITH TIME ZONE NOT NULL,
  rating TEXT CHECK (rating IN ('too_early', 'just_right', 'too_late')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cry_insight_sessions table (metadata only, no audio storage)
CREATE TABLE IF NOT EXISTS public.cry_insight_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  created_by UUID REFERENCES auth.users(id),
  category TEXT CHECK (category IN ('tired', 'hungry', 'uncomfortable', 'pain_possible', 'unknown')),
  confidence DECIMAL(3, 2) CHECK (confidence >= 0 AND confidence <= 1),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON public.family_members(user_id);
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON public.family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_babies_family_id ON public.babies(family_id);
CREATE INDEX IF NOT EXISTS idx_events_baby_id ON public.events(baby_id);
CREATE INDEX IF NOT EXISTS idx_events_family_id ON public.events(family_id);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON public.events(start_time DESC);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nap_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cry_insight_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
  
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for families (users can see families they belong to)
CREATE POLICY "Users can view families they belong to" ON public.families
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create families" ON public.families
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can update their families" ON public.families
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
      AND family_members.role = 'admin'
    )
  );

-- RLS Policies for family_members
CREATE POLICY "Users can view family members of their families" ON public.family_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert themselves as family members" ON public.family_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage family members" ON public.family_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
      AND fm.role = 'admin'
    )
  );

-- RLS Policies for babies
CREATE POLICY "Users can view babies in their families" ON public.babies
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = babies.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create babies in their families" ON public.babies
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = babies.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can update babies in their families" ON public.babies
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = babies.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS Policies for events
CREATE POLICY "Users can view events for babies in their families" ON public.events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create events in their families" ON public.events
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can update events in their families" ON public.events
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can delete events in their families" ON public.events
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS Policies for nap_feedback
CREATE POLICY "Users can view nap feedback for babies in their families" ON public.nap_feedback
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.babies
      JOIN public.family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = nap_feedback.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert nap feedback" ON public.nap_feedback
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.babies
      JOIN public.family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = nap_feedback.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

-- RLS Policies for cry_insight_sessions
CREATE POLICY "Users can view cry insights for babies in their families" ON public.cry_insight_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.babies
      JOIN public.family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = cry_insight_sessions.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create cry insights" ON public.cry_insight_sessions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.babies
      JOIN public.family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = cry_insight_sessions.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_families_updated_at BEFORE UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_babies_updated_at BEFORE UPDATE ON public.babies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();