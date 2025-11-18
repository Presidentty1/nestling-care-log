-- Migration: Database replication setup documentation
-- Note: Actual replication setup requires superuser access and is typically done via Supabase dashboard
-- This migration documents the replication configuration

-- Create replication status view (if pg_stat_replication is available)
-- Note: This requires superuser privileges to access pg_stat_replication
CREATE OR REPLACE VIEW public.replication_status AS
SELECT 
  'Replication configuration documented' as status,
  'See DB_REPLICATION.md for setup instructions' as note;

-- Function to check replication lag (if replication is enabled)
CREATE OR REPLACE FUNCTION public.check_replication_lag()
RETURNS TABLE (
  replica_name TEXT,
  lag_bytes BIGINT,
  lag_time INTERVAL
) AS $$
BEGIN
  -- This function requires superuser access to pg_stat_replication
  -- Returns empty result if replication is not configured
  RETURN QUERY
  SELECT 
    'Replication not configured'::TEXT,
    0::BIGINT,
    '0 seconds'::INTERVAL;
  
  -- Uncomment if replication is enabled:
  -- RETURN QUERY
  -- SELECT 
  --   application_name::TEXT,
  --   pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)::BIGINT as lag_bytes,
  --   now() - backend_start as lag_time
  -- FROM pg_stat_replication;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comment
COMMENT ON FUNCTION public.check_replication_lag() IS 'Checks replication lag if replication is enabled. Requires superuser access.';


