-- Fix leaked password protection
-- Enable password breach detection for better security

-- Fix function search_path for all database functions
-- This prevents potential SQL injection via search_path manipulation

-- Get all functions and set secure search_path
DO $$
DECLARE
  func_record RECORD;
BEGIN
  FOR func_record IN 
    SELECT 
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
  LOOP
    EXECUTE format(
      'ALTER FUNCTION %I.%I(%s) SET search_path = public, pg_temp',
      func_record.schema_name,
      func_record.function_name,
      func_record.args
    );
  END LOOP;
END $$;

-- Note: Materialized views and leaked password protection
-- must be configured in Supabase dashboard settings