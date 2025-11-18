-- Add AI preferences to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ai_data_sharing_enabled BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ai_preferences_updated_at TIMESTAMPTZ DEFAULT now();

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_profiles_ai_sharing ON profiles(ai_data_sharing_enabled);

-- Add comment for documentation
COMMENT ON COLUMN profiles.ai_data_sharing_enabled IS 'User consent for AI features to use their baby data for predictions, cry analysis, and AI assistant';
COMMENT ON COLUMN profiles.ai_preferences_updated_at IS 'Timestamp when AI preferences were last updated';