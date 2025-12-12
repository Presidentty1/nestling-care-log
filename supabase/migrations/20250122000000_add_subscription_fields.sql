-- Add subscription fields to profiles and enhance subscriptions table

-- Add subscription_tier to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium'));

-- Create subscription status enum
CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid', 'incomplete', 'incomplete_expired');

-- Update subscriptions table status column to use enum
ALTER TABLE public.subscriptions ALTER COLUMN status TYPE subscription_status USING status::subscription_status;

-- Add missing fields to subscriptions table for Stripe compatibility
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS trial_start TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS trial_end TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS canceled_at TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;

-- Update RLS policies for subscriptions table to allow service role updates
DROP POLICY IF EXISTS "Service role can manage subscriptions" ON public.subscriptions;
CREATE POLICY "Service role can manage subscriptions"
  ON public.subscriptions FOR ALL
  USING (auth.role() = 'service_role');

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_subscriptions_status_active ON public.subscriptions(status, current_period_end)
WHERE status IN ('trialing', 'active');

-- Function to check subscription status
CREATE OR REPLACE FUNCTION check_subscription_status(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    sub_status subscription_status;
    current_period_end TIMESTAMPTZ;
    trial_end TIMESTAMPTZ;
BEGIN
    SELECT s.status, s.current_period_end, s.trial_end
    INTO sub_status, current_period_end, trial_end
    FROM public.subscriptions s
    WHERE s.user_id = user_uuid
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Return 'premium' if active subscription exists
    IF sub_status IN ('trialing', 'active') THEN
        -- Check if trial has expired
        IF sub_status = 'trialing' AND trial_end < NOW() THEN
            RETURN 'free';
        -- Check if subscription has expired
        ELSIF sub_status = 'active' AND current_period_end < NOW() THEN
            RETURN 'free';
        ELSE
            RETURN 'premium';
        END IF;
    END IF;

    -- Default to free tier
    RETURN 'free';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;





