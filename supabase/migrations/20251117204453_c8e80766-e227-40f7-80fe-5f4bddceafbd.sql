-- Phase 2: Add bottle_type column for feed tracking
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS bottle_type TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.events.bottle_type IS 'Type of bottle feed: formula, breast_milk, or mixed';

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_events_bottle_type ON public.events(bottle_type) WHERE bottle_type IS NOT NULL;