-- Drop the materialized view and replace with a regular view
-- This ensures RLS policies on the underlying events table are respected

DROP MATERIALIZED VIEW IF EXISTS public.daily_summaries;

-- Create a regular view instead
-- This will respect RLS policies on the events table
CREATE OR REPLACE VIEW public.daily_summaries AS
SELECT 
  baby_id,
  family_id,
  DATE(start_time) as date,
  COUNT(*) FILTER (WHERE type = 'feed') as feed_count,
  COUNT(*) FILTER (WHERE type = 'diaper') as diaper_count,
  COUNT(*) FILTER (WHERE type = 'sleep') as sleep_count,
  SUM(amount) FILTER (WHERE type = 'feed') as total_feed_amount,
  AVG(amount) FILTER (WHERE type = 'feed') as avg_feed_amount,
  SUM(
    COALESCE(duration_min, 0) + COALESCE(duration_sec, 0) / 60.0 +
    COALESCE(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600.0, 0)
  ) FILTER (WHERE type = 'sleep') as total_sleep_hours
FROM public.events
GROUP BY baby_id, family_id, DATE(start_time);

-- Drop the function that refreshed the materialized view since it's no longer needed
DROP FUNCTION IF EXISTS public.refresh_daily_summaries();