-- PHASE 12: Sleep Training Tables

CREATE TABLE IF NOT EXISTS public.sleep_training_sessions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  method TEXT NOT NULL,
  start_date DATE NOT NULL,
  target_bedtime TIME,
  target_wake_time TIME,
  check_intervals JSONB,
  notes TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sleep_training_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL,
  night_date DATE NOT NULL,
  bedtime_started TIME,
  fell_asleep_at TIME,
  night_wakings INTEGER DEFAULT 0,
  total_crying_minutes INTEGER,
  intervention_notes TEXT,
  success_rating INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sleep_regressions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  detected_at DATE NOT NULL,
  regression_type TEXT,
  severity TEXT,
  symptoms JSONB,
  resolved_at DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.wake_windows (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  age_in_months INTEGER NOT NULL,
  recommended_window_minutes INTEGER,
  actual_window_minutes INTEGER,
  resulted_in_good_nap BOOLEAN,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- PHASE 13: Collaboration Tables

CREATE TABLE IF NOT EXISTS public.activity_feed (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id UUID NOT NULL,
  actor_id UUID NOT NULL,
  action_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  summary TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.handoff_reports (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  from_user_id UUID NOT NULL,
  to_user_id UUID,
  shift_start TIMESTAMP WITH TIME ZONE NOT NULL,
  shift_end TIMESTAMP WITH TIME ZONE NOT NULL,
  summary TEXT,
  events_summary JSONB,
  notes TEXT,
  highlights TEXT[],
  concerns TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.baby_books (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  cover_photo_url TEXT,
  is_public BOOLEAN DEFAULT false,
  share_token UUID DEFAULT gen_random_uuid(),
  password_hash TEXT,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.baby_book_pages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  book_id UUID NOT NULL,
  page_number INTEGER NOT NULL,
  title TEXT,
  date DATE,
  content TEXT,
  photos JSONB,
  layout_type TEXT DEFAULT 'standard',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.private_notes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  baby_id UUID NOT NULL,
  related_to_type TEXT,
  related_to_id UUID,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- PHASE 14: Predictions Tables

CREATE TABLE IF NOT EXISTS public.predictions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  prediction_type TEXT NOT NULL,
  predicted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  prediction_data JSONB NOT NULL,
  confidence_score NUMERIC(3,2),
  actual_outcome JSONB,
  was_accurate BOOLEAN,
  model_version TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.anomalies (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  anomaly_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  detected_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  description TEXT NOT NULL,
  metrics JSONB,
  suggested_actions TEXT[],
  acknowledged_by UUID,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.recommendations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  category TEXT NOT NULL,
  recommendation TEXT NOT NULL,
  reasoning TEXT,
  confidence NUMERIC(3,2),
  priority INTEGER DEFAULT 3,
  expires_at TIMESTAMP WITH TIME ZONE,
  dismissed_by UUID,
  dismissed_at TIMESTAMP WITH TIME ZONE,
  acted_on BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.prediction_feedback (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  prediction_id UUID NOT NULL,
  user_id UUID NOT NULL,
  feedback_type TEXT NOT NULL,
  comments TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- PHASE 15: Media Tables

CREATE TABLE IF NOT EXISTS public.videos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  title TEXT,
  description TEXT,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  duration_seconds INTEGER,
  file_size_bytes BIGINT,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
  tags TEXT[],
  milestone_id UUID,
  is_favorite BOOLEAN DEFAULT false,
  uploaded_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  entry_date DATE NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  mood TEXT,
  weather TEXT,
  activities TEXT[],
  firsts TEXT[],
  funny_moments TEXT[],
  media_ids JSONB,
  is_published BOOLEAN DEFAULT false,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.memory_tags (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  tag_name TEXT NOT NULL,
  color TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(baby_id, tag_name)
);

CREATE TABLE IF NOT EXISTS public.tagged_memories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tag_id UUID NOT NULL,
  memory_type TEXT NOT NULL,
  memory_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.comparison_snapshots (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  title TEXT NOT NULL,
  before_photo_url TEXT NOT NULL,
  before_date DATE NOT NULL,
  after_photo_url TEXT NOT NULL,
  after_date DATE NOT NULL,
  description TEXT,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.monthly_recaps (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  video_url TEXT,
  highlights JSONB,
  generated_at TIMESTAMP WITH TIME ZONE,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(baby_id, year, month)
);

CREATE TABLE IF NOT EXISTS public.family_shares (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  share_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  share_token UUID DEFAULT gen_random_uuid(),
  expires_at TIMESTAMP WITH TIME ZONE,
  password_hash TEXT,
  view_count INTEGER DEFAULT 0,
  max_views INTEGER,
  can_download BOOLEAN DEFAULT true,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all new tables

ALTER TABLE public.sleep_training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_training_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_regressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wake_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.handoff_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.baby_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.baby_book_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memory_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tagged_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comparison_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_recaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_shares ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Sleep Training

CREATE POLICY "Users can view sleep training for babies in their families"
  ON public.sleep_training_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = sleep_training_sessions.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create sleep training sessions"
  ON public.sleep_training_sessions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = sleep_training_sessions.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can update sleep training sessions"
  ON public.sleep_training_sessions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = sleep_training_sessions.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view sleep training logs"
  ON public.sleep_training_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM sleep_training_sessions
      JOIN babies ON babies.id = sleep_training_sessions.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE sleep_training_sessions.id = sleep_training_logs.session_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage sleep training logs"
  ON public.sleep_training_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM sleep_training_sessions
      JOIN babies ON babies.id = sleep_training_sessions.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE sleep_training_sessions.id = sleep_training_logs.session_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS for other Phase 12 tables
CREATE POLICY "Users can view sleep regressions"
  ON public.sleep_regressions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = sleep_regressions.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage sleep regressions"
  ON public.sleep_regressions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = sleep_regressions.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view wake windows"
  ON public.wake_windows FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = wake_windows.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage wake windows"
  ON public.wake_windows FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = wake_windows.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS Policies for Collaboration (Phase 13)

CREATE POLICY "Users can view activity feed for their families"
  ON public.activity_feed FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = activity_feed.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create activity feed entries"
  ON public.activity_feed FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = activity_feed.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view handoff reports"
  ON public.handoff_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = handoff_reports.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage handoff reports"
  ON public.handoff_reports FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = handoff_reports.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view baby books"
  ON public.baby_books FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = baby_books.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage baby books"
  ON public.baby_books FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = baby_books.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view baby book pages"
  ON public.baby_book_pages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM baby_books
      JOIN babies ON babies.id = baby_books.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE baby_books.id = baby_book_pages.book_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage baby book pages"
  ON public.baby_book_pages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM baby_books
      JOIN babies ON babies.id = baby_books.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE baby_books.id = baby_book_pages.book_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view their own private notes"
  ON public.private_notes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own private notes"
  ON public.private_notes FOR ALL
  USING (user_id = auth.uid());

-- RLS Policies for Predictions (Phase 14)

CREATE POLICY "Users can view predictions for babies in their families"
  ON public.predictions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = predictions.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create predictions"
  ON public.predictions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = predictions.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view anomalies"
  ON public.anomalies FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = anomalies.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage anomalies"
  ON public.anomalies FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = anomalies.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view recommendations"
  ON public.recommendations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = recommendations.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage recommendations"
  ON public.recommendations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = recommendations.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can submit prediction feedback"
  ON public.prediction_feedback FOR ALL
  USING (user_id = auth.uid());

-- RLS Policies for Media (Phase 15)

CREATE POLICY "Users can view videos for babies in their families"
  ON public.videos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = videos.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage videos"
  ON public.videos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = videos.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view journal entries"
  ON public.journal_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = journal_entries.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage journal entries"
  ON public.journal_entries FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = journal_entries.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view memory tags"
  ON public.memory_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = memory_tags.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage memory tags"
  ON public.memory_tags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = memory_tags.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view tagged memories"
  ON public.tagged_memories FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM memory_tags
      JOIN babies ON babies.id = memory_tags.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE memory_tags.id = tagged_memories.tag_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage tagged memories"
  ON public.tagged_memories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM memory_tags
      JOIN babies ON babies.id = memory_tags.baby_id
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE memory_tags.id = tagged_memories.tag_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view comparison snapshots"
  ON public.comparison_snapshots FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = comparison_snapshots.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage comparison snapshots"
  ON public.comparison_snapshots FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = comparison_snapshots.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view monthly recaps"
  ON public.monthly_recaps FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = monthly_recaps.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage monthly recaps"
  ON public.monthly_recaps FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = monthly_recaps.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view family shares"
  ON public.family_shares FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = family_shares.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can manage family shares"
  ON public.family_shares FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = family_shares.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- Triggers for updated_at

CREATE TRIGGER update_sleep_training_sessions_updated_at
  BEFORE UPDATE ON public.sleep_training_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Storage Buckets

INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('videos', 'videos', false),
  ('journal-media', 'journal-media', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for videos

CREATE POLICY "Users can upload videos for their babies"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'videos' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view their family's videos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'videos' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their family's videos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'videos' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- Storage policies for journal media

CREATE POLICY "Users can upload journal media for their babies"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'journal-media' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Users can view their family's journal media"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'journal-media' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their family's journal media"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'journal-media' AND
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id::text = (storage.foldername(name))[1]
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );