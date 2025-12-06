-- Performance Optimization: Add composite indexes for common query patterns
-- Migration created: 2025-12-06
-- Purpose: Speed up timeline queries, calendar views, and analytics

-- Index for timeline queries (most common: get events for a baby, ordered by time)
CREATE INDEX IF NOT EXISTS idx_events_baby_starttime_desc 
ON public.events(baby_id, start_time DESC);

-- Index for calendar date queries (get events by baby and date)
CREATE INDEX IF NOT EXISTS idx_events_baby_date 
ON public.events(baby_id, DATE(start_time));

-- Index for analytics queries (aggregate by family, type, and time)
CREATE INDEX IF NOT EXISTS idx_events_family_type_time 
ON public.events(family_id, type, start_time);

-- Index for active sleep queries (frequently checked)
CREATE INDEX IF NOT EXISTS idx_events_baby_type_endtime 
ON public.events(baby_id, type, end_time) 
WHERE type = 'sleep' AND end_time IS NULL;

-- Index for recent events queries (used in AI predictions)
CREATE INDEX IF NOT EXISTS idx_events_baby_type_recent 
ON public.events(baby_id, type, start_time DESC) 
WHERE start_time >= NOW() - INTERVAL '7 days';

-- Index for family members queries (checking access)
CREATE INDEX IF NOT EXISTS idx_family_members_lookup 
ON public.family_members(user_id, family_id, role);

-- Index for subscription status lookups
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status 
ON public.subscriptions(user_id, status) 
WHERE status IN ('active', 'trialing');

-- Analyze tables to update query planner statistics
ANALYZE public.events;
ANALYZE public.family_members;
ANALYZE public.subscriptions;

-- Add comments for documentation
COMMENT ON INDEX idx_events_baby_starttime_desc IS 'Optimizes timeline queries: SELECT * FROM events WHERE baby_id = ? ORDER BY start_time DESC';
COMMENT ON INDEX idx_events_baby_date IS 'Optimizes calendar queries: SELECT DATE(start_time), COUNT(*) FROM events WHERE baby_id = ? GROUP BY DATE(start_time)';
COMMENT ON INDEX idx_events_family_type_time IS 'Optimizes analytics queries by family and event type';
COMMENT ON INDEX idx_events_baby_type_endtime IS 'Optimizes active sleep lookups: SELECT * FROM events WHERE baby_id = ? AND type = ''sleep'' AND end_time IS NULL';

