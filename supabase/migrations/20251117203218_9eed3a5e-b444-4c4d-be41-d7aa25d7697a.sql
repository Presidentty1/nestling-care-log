-- Add duration_sec column to events table for precise duration tracking
ALTER TABLE public.events
ADD COLUMN duration_sec integer;

COMMENT ON COLUMN public.events.duration_sec IS 'Duration in seconds for precise time tracking';

-- Backfill existing records: convert duration_min to duration_sec
UPDATE public.events
SET duration_sec = duration_min * 60
WHERE duration_min IS NOT NULL AND duration_sec IS NULL;

-- For records with start_time and end_time but no duration_min, calculate duration_sec
UPDATE public.events
SET duration_sec = EXTRACT(EPOCH FROM (end_time - start_time))::integer
WHERE start_time IS NOT NULL 
  AND end_time IS NOT NULL 
  AND duration_sec IS NULL;