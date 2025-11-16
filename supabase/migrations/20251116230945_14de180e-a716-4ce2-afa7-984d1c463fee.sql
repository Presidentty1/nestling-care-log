-- Create app_settings table for accessibility preferences
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  theme TEXT DEFAULT 'system',
  font_size TEXT DEFAULT 'medium',
  caregiver_mode BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Create user_feedback table
CREATE TABLE IF NOT EXISTS public.user_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feedback_type TEXT NOT NULL,
  subject TEXT,
  message TEXT NOT NULL,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create growth_records table (if not exists)
CREATE TABLE IF NOT EXISTS public.growth_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  recorded_at DATE NOT NULL,
  weight DECIMAL,
  length DECIMAL,
  head_circumference DECIMAL,
  unit_system TEXT DEFAULT 'metric',
  percentile_weight INTEGER,
  percentile_length INTEGER,
  percentile_head INTEGER,
  note TEXT,
  recorded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create health_records table (if not exists)
CREATE TABLE IF NOT EXISTS public.health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  record_type TEXT NOT NULL,
  title TEXT NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  temperature DECIMAL,
  vaccine_name TEXT,
  vaccine_dose TEXT,
  doctor_name TEXT,
  diagnosis TEXT,
  treatment TEXT,
  note TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create milestones table (if not exists)
CREATE TABLE IF NOT EXISTS public.milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  expected_age_months INTEGER,
  achieved_at DATE,
  photo_url TEXT,
  note TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;

-- RLS Policies for app_settings
CREATE POLICY "Users can view own settings"
  ON public.app_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
  ON public.app_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
  ON public.app_settings FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for user_feedback
CREATE POLICY "Users can view own feedback"
  ON public.user_feedback FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback"
  ON public.user_feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for growth_records
CREATE POLICY "Users can view growth records for their babies"
  ON public.growth_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = growth_records.baby_id AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert growth records for their babies"
  ON public.growth_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = growth_records.baby_id AND fm.user_id = auth.uid()
    )
  );

-- RLS Policies for health_records
CREATE POLICY "Users can view health records for their babies"
  ON public.health_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = health_records.baby_id AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert health records for their babies"
  ON public.health_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = health_records.baby_id AND fm.user_id = auth.uid()
    )
  );

-- RLS Policies for milestones
CREATE POLICY "Users can view milestones for their babies"
  ON public.milestones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = milestones.baby_id AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert milestones for their babies"
  ON public.milestones FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.babies b
      JOIN public.family_members fm ON b.family_id = fm.family_id
      WHERE b.id = milestones.baby_id AND fm.user_id = auth.uid()
    )
  );