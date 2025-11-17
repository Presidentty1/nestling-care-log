-- Add duration_min column to events table for storing calculated durations
-- This column stores the duration in minutes calculated from start_time and end_time
-- Nullable because not all event types have durations (e.g., bottle feeds, diaper changes)
ALTER TABLE public.events 
ADD COLUMN duration_min integer;

COMMENT ON COLUMN public.events.duration_min IS 'Duration in minutes, calculated from start_time and end_time for timer-based events';