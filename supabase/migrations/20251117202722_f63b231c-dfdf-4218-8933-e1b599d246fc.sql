-- Add side column to events for breast feeding side selection
-- Nullable text: expected values like 'left', 'right', 'both'
ALTER TABLE public.events
ADD COLUMN side text;

COMMENT ON COLUMN public.events.side IS 'Breastfeeding side: left, right, or both';