-- Migration: Data retention policies
-- Implements automatic data cleanup based on retention policies

-- Create retention_policies table
CREATE TABLE IF NOT EXISTS public.retention_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  retention_days INTEGER NOT NULL DEFAULT 365, -- Default: 1 year
  enabled BOOLEAN DEFAULT true,
  last_run TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(table_name)
);

-- Insert default retention policies
INSERT INTO public.retention_policies (table_name, retention_days, enabled)
VALUES
  ('events', 365, true), -- Keep events for 1 year
  ('cry_insight_sessions', 90, true), -- Keep cry insights for 90 days
  ('nap_feedback', 180, true), -- Keep nap feedback for 6 months
  ('predictions', 90, true), -- Keep predictions for 90 days
  ('anomalies', 180, true), -- Keep anomalies for 6 months
  ('recommendations', 90, true) -- Keep recommendations for 90 days
ON CONFLICT (table_name) DO NOTHING;

-- Function to clean up old data based on retention policy
CREATE OR REPLACE FUNCTION public.cleanup_old_data()
RETURNS TABLE (
  table_name TEXT,
  deleted_count BIGINT
) AS $$
DECLARE
  policy RECORD;
  deleted_count BIGINT;
BEGIN
  FOR policy IN SELECT * FROM public.retention_policies WHERE enabled = true
  LOOP
    EXECUTE format(
      'DELETE FROM public.%I WHERE created_at < NOW() - INTERVAL ''%s days''',
      policy.table_name,
      policy.retention_days
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Update last_run
    UPDATE public.retention_policies
    SET last_run = NOW(), updated_at = NOW()
    WHERE id = policy.id;
    
    RETURN QUERY SELECT policy.table_name, deleted_count;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get retention policy info
CREATE OR REPLACE FUNCTION public.get_retention_info()
RETURNS TABLE (
  table_name TEXT,
  retention_days INTEGER,
  enabled BOOLEAN,
  last_run TIMESTAMPTZ,
  estimated_records_to_delete BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.table_name,
    rp.retention_days,
    rp.enabled,
    rp.last_run,
    CASE 
      WHEN rp.table_name = 'events' THEN
        (SELECT COUNT(*) FROM public.events WHERE created_at < NOW() - (rp.retention_days || ' days')::INTERVAL)
      WHEN rp.table_name = 'cry_insight_sessions' THEN
        (SELECT COUNT(*) FROM public.cry_insight_sessions WHERE created_at < NOW() - (rp.retention_days || ' days')::INTERVAL)
      ELSE 0
    END as estimated_records_to_delete
  FROM public.retention_policies rp
  ORDER BY rp.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE public.retention_policies ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only service role can manage retention policies
CREATE POLICY "Service role can manage retention policies"
ON public.retention_policies FOR ALL
USING (auth.role() = 'service_role');

-- RLS Policy: Users can view retention policies
CREATE POLICY "Users can view retention policies"
ON public.retention_policies FOR SELECT
USING (true);

-- Create pg_cron job to run cleanup daily (requires pg_cron extension)
-- Note: This requires superuser access. Run manually or via Supabase dashboard.
-- SELECT cron.schedule('cleanup-old-data', '0 2 * * *', 'SELECT public.cleanup_old_data()');

-- Manual cleanup function (can be called from edge function or cron)
COMMENT ON FUNCTION public.cleanup_old_data() IS 'Cleans up old data based on retention policies. Should be run daily via cron or scheduled task.';

-- Comment on table
COMMENT ON TABLE public.retention_policies IS 'Defines data retention policies for automatic cleanup of old records.';


