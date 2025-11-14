-- Migration 1: Enable Realtime on Events Table
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER TABLE public.events REPLICA IDENTITY FULL;

-- Migration 2: Create Caregiver Invites Table
CREATE TABLE IF NOT EXISTS caregiver_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer')),
  token UUID NOT NULL DEFAULT gen_random_uuid(),
  invited_by UUID REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '7 days'),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_caregiver_invites_token ON caregiver_invites(token);
CREATE INDEX idx_caregiver_invites_email ON caregiver_invites(email);
CREATE INDEX idx_caregiver_invites_family ON caregiver_invites(family_id);

-- RLS Policies for caregiver_invites
ALTER TABLE caregiver_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family admins can manage invites"
ON caregiver_invites FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM family_members
    WHERE family_members.family_id = caregiver_invites.family_id
    AND family_members.user_id = auth.uid()
    AND family_members.role = 'admin'
  )
);

CREATE POLICY "Users can view their own invites"
ON caregiver_invites FOR SELECT
USING (email = auth.email());

-- Trigger for updated_at
CREATE TRIGGER update_caregiver_invites_updated_at
BEFORE UPDATE ON caregiver_invites
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Migration 3: Update Events RLS for Viewer Role
DROP POLICY IF EXISTS "Members can create events in their families" ON events;
DROP POLICY IF EXISTS "Members can update events in their families" ON events;
DROP POLICY IF EXISTS "Members can delete events in their families" ON events;

-- New policies that respect viewer role
CREATE POLICY "Admins and members can create events"
ON events FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM family_members
    WHERE family_members.family_id = events.family_id
    AND family_members.user_id = auth.uid()
    AND family_members.role IN ('admin', 'member')
  )
);

CREATE POLICY "Admins and members can update events"
ON events FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM family_members
    WHERE family_members.family_id = events.family_id
    AND family_members.user_id = auth.uid()
    AND family_members.role IN ('admin', 'member')
  )
);

CREATE POLICY "Admins and members can delete events"
ON events FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM family_members
    WHERE family_members.family_id = events.family_id
    AND family_members.user_id = auth.uid()
    AND family_members.role IN ('admin', 'member')
  )
);