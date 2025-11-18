-- Migration: Add audit logging system
-- Creates audit log table and triggers for tracking data changes

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  user_id UUID REFERENCES auth.users(id),
  family_id UUID REFERENCES public.families(id),
  old_data JSONB,
  new_data JSONB,
  changed_fields TEXT[],
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_record ON public.audit_logs(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_family_id ON public.audit_logs(family_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- Enable RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view audit logs for their families
CREATE POLICY "Users can view audit logs for their families"
ON public.audit_logs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.family_members
    WHERE family_members.family_id = audit_logs.family_id
    AND family_members.user_id = auth.uid()
  )
);

-- Function to create audit log entry
CREATE OR REPLACE FUNCTION public.create_audit_log(
  p_table_name TEXT,
  p_record_id UUID,
  p_action TEXT,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_user_id UUID;
  v_family_id UUID;
  v_changed_fields TEXT[];
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  -- Extract family_id from new_data or old_data
  IF p_new_data IS NOT NULL AND p_new_data ? 'family_id' THEN
    v_family_id := (p_new_data->>'family_id')::UUID;
  ELSIF p_old_data IS NOT NULL AND p_old_data ? 'family_id' THEN
    v_family_id := (p_old_data->>'family_id')::UUID;
  END IF;
  
  -- Calculate changed fields for UPDATE
  IF p_action = 'UPDATE' AND p_old_data IS NOT NULL AND p_new_data IS NOT NULL THEN
    SELECT array_agg(key)
    INTO v_changed_fields
    FROM jsonb_each(p_new_data)
    WHERE value IS DISTINCT FROM (p_old_data->key);
  END IF;
  
  -- Insert audit log
  INSERT INTO public.audit_logs (
    table_name,
    record_id,
    action,
    user_id,
    family_id,
    old_data,
    new_data,
    changed_fields
  ) VALUES (
    p_table_name,
    p_record_id,
    p_action,
    v_user_id,
    v_family_id,
    p_old_data,
    p_new_data,
    v_changed_fields
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for events table
CREATE OR REPLACE FUNCTION public.audit_events()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.create_audit_log(
      'events',
      NEW.id,
      'INSERT',
      NULL,
      row_to_json(NEW)::JSONB
    );
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM public.create_audit_log(
      'events',
      NEW.id,
      'UPDATE',
      row_to_json(OLD)::JSONB,
      row_to_json(NEW)::JSONB
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM public.create_audit_log(
      'events',
      OLD.id,
      'DELETE',
      row_to_json(OLD)::JSONB,
      NULL
    );
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for events table
DROP TRIGGER IF EXISTS audit_events_trigger ON public.events;
CREATE TRIGGER audit_events_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.audit_events();

-- Trigger function for babies table
CREATE OR REPLACE FUNCTION public.audit_babies()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.create_audit_log(
      'babies',
      NEW.id,
      'INSERT',
      NULL,
      row_to_json(NEW)::JSONB
    );
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM public.create_audit_log(
      'babies',
      NEW.id,
      'UPDATE',
      row_to_json(OLD)::JSONB,
      row_to_json(NEW)::JSONB
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM public.create_audit_log(
      'babies',
      OLD.id,
      'DELETE',
      row_to_json(OLD)::JSONB,
      NULL
    );
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for babies table
DROP TRIGGER IF EXISTS audit_babies_trigger ON public.babies;
CREATE TRIGGER audit_babies_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.babies
  FOR EACH ROW EXECUTE FUNCTION public.audit_babies();

-- Function to query audit logs
CREATE OR REPLACE FUNCTION public.get_audit_logs(
  p_table_name TEXT DEFAULT NULL,
  p_record_id UUID DEFAULT NULL,
  p_family_id UUID DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  id UUID,
  table_name TEXT,
  record_id UUID,
  action TEXT,
  user_id UUID,
  family_id UUID,
  changed_fields TEXT[],
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    al.id,
    al.table_name,
    al.record_id,
    al.action,
    al.user_id,
    al.family_id,
    al.changed_fields,
    al.created_at
  FROM public.audit_logs al
  WHERE (p_table_name IS NULL OR al.table_name = p_table_name)
    AND (p_record_id IS NULL OR al.record_id = p_record_id)
    AND (p_family_id IS NULL OR al.family_id = p_family_id)
    AND (p_start_date IS NULL OR al.created_at >= p_start_date)
    AND (p_end_date IS NULL OR al.created_at <= p_end_date)
    AND EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = al.family_id
      AND family_members.user_id = auth.uid()
    )
  ORDER BY al.created_at DESC
  LIMIT 1000;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comment on table
COMMENT ON TABLE public.audit_logs IS 'Audit log for tracking all data changes. Used for compliance, debugging, and support.';


