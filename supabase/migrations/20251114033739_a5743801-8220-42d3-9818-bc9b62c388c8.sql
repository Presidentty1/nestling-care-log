-- Phase 8: Cry Insights & Pattern Analysis Tables
CREATE TABLE IF NOT EXISTS public.cry_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  family_id UUID NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  cry_type TEXT,
  confidence NUMERIC,
  context JSONB,
  resolved_by TEXT,
  note TEXT,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.behavior_patterns (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID NOT NULL,
  pattern_type TEXT NOT NULL,
  description TEXT,
  confidence NUMERIC,
  detected_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  occurrences INTEGER DEFAULT 1,
  last_occurrence TIMESTAMP WITH TIME ZONE,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Phase 9: AI Q&A Assistant Tables
CREATE TABLE IF NOT EXISTS public.ai_conversations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  baby_id UUID,
  user_id UUID NOT NULL,
  family_id UUID NOT NULL,
  title TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ai_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Phase 10: Analytics - Daily Summaries Materialized View
CREATE MATERIALIZED VIEW IF NOT EXISTS public.daily_summaries AS
SELECT 
  baby_id,
  family_id,
  DATE(start_time) as date,
  COUNT(*) FILTER (WHERE type = 'feed') as feed_count,
  COUNT(*) FILTER (WHERE type = 'sleep') as sleep_count,
  COUNT(*) FILTER (WHERE type = 'diaper') as diaper_count,
  SUM(EXTRACT(EPOCH FROM (end_time - start_time))/3600) FILTER (WHERE type = 'sleep') as total_sleep_hours,
  SUM(amount) FILTER (WHERE type = 'feed') as total_feed_amount,
  AVG(amount) FILTER (WHERE type = 'feed') as avg_feed_amount
FROM public.events
GROUP BY baby_id, family_id, DATE(start_time);

CREATE UNIQUE INDEX ON public.daily_summaries (baby_id, date);

-- Enable RLS
ALTER TABLE public.cry_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.behavior_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for cry_logs
CREATE POLICY "Users can view cry logs for babies in their families"
  ON public.cry_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = cry_logs.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create cry logs"
  ON public.cry_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = cry_logs.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can update cry logs"
  ON public.cry_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = cry_logs.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

CREATE POLICY "Members can delete cry logs"
  ON public.cry_logs FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = cry_logs.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS Policies for behavior_patterns
CREATE POLICY "Users can view behavior patterns for babies in their families"
  ON public.behavior_patterns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = behavior_patterns.baby_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create behavior patterns"
  ON public.behavior_patterns FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM babies
      JOIN family_members ON family_members.family_id = babies.family_id
      WHERE babies.id = behavior_patterns.baby_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );

-- RLS Policies for ai_conversations
CREATE POLICY "Users can view their own conversations"
  ON public.ai_conversations FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = ai_conversations.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own conversations"
  ON public.ai_conversations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own conversations"
  ON public.ai_conversations FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own conversations"
  ON public.ai_conversations FOR DELETE
  USING (user_id = auth.uid());

-- RLS Policies for ai_messages
CREATE POLICY "Users can view messages in their conversations"
  ON public.ai_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ai_conversations
      WHERE ai_conversations.id = ai_messages.conversation_id
      AND ai_conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create messages in their conversations"
  ON public.ai_messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM ai_conversations
      WHERE ai_conversations.id = ai_messages.conversation_id
      AND ai_conversations.user_id = auth.uid()
    )
  );

-- Triggers for updated_at
CREATE TRIGGER update_cry_logs_updated_at
  BEFORE UPDATE ON public.cry_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_ai_conversations_updated_at
  BEFORE UPDATE ON public.ai_conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Refresh materialized view function
CREATE OR REPLACE FUNCTION refresh_daily_summaries()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.daily_summaries;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;