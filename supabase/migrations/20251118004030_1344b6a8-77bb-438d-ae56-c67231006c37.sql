-- Create parent wellness tracking tables

-- Parent wellness logs table
CREATE TABLE IF NOT EXISTS public.parent_wellness_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  mood TEXT CHECK (mood IN ('great', 'good', 'okay', 'tired', 'stressed')),
  water_intake_ml INTEGER DEFAULT 0,
  sleep_quality TEXT CHECK (sleep_quality IN ('great', 'good', 'fair', 'poor')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, log_date)
);

-- Parent medications table
CREATE TABLE IF NOT EXISTS public.parent_medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_name TEXT NOT NULL,
  dosage TEXT,
  frequency TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.parent_wellness_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_medications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for parent_wellness_logs
CREATE POLICY "Users can view their own wellness logs"
  ON public.parent_wellness_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wellness logs"
  ON public.parent_wellness_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wellness logs"
  ON public.parent_wellness_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own wellness logs"
  ON public.parent_wellness_logs FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for parent_medications
CREATE POLICY "Users can view their own medications"
  ON public.parent_medications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own medications"
  ON public.parent_medications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own medications"
  ON public.parent_medications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own medications"
  ON public.parent_medications FOR DELETE
  USING (auth.uid() = user_id);

-- Triggers for updated_at
CREATE TRIGGER update_parent_wellness_logs_updated_at
  BEFORE UPDATE ON public.parent_wellness_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_medications_updated_at
  BEFORE UPDATE ON public.parent_medications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();