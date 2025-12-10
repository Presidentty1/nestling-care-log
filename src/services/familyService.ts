import { supabase } from '@/integrations/supabase/client';

export interface Family {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface FamilyMember {
  id: string;
  user_id: string;
  family_id: string;
  role: 'admin' | 'member' | 'viewer';
  created_at: string;
}

export interface Invite {
  id: string;
  email: string;
  role: string;
  status: string;
  created_at: string;
}

class FamilyService {
  async getUserFamilies(): Promise<Family[]> {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: memberships } = await supabase
      .from('family_members')
      .select('family_id')
      .eq('user_id', user.id);

    if (!memberships || memberships.length === 0) return [];

    const familyIds = memberships.map(m => m.family_id);

    const { data: families, error } = await supabase
      .from('families')
      .select('*')
      .in('id', familyIds);

    if (error) throw error;
    return (families || []) as Family[];
  }

  async getUserFamilyMembership(userId: string) {
    const { data, error } = await supabase
      .from('family_members')
      .select('family_id, role')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async createFamily(name: string) {
    const { data, error } = await supabase.from('families').insert({ name }).select('id').single();

    if (error) throw error;
    return data;
  }

  async addFamilyMember(familyId: string, userId: string, role: 'admin' | 'member' | 'viewer') {
    const { error } = await supabase.from('family_members').insert({
      family_id: familyId,
      user_id: userId,
      role,
    });

    if (error) throw error;
  }

  async createFamilyWithBaby(familyName: string, babyName: string, dateOfBirth: string) {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Create family
    const family = await this.createFamily(familyName);

    // Add user as admin
    await this.addFamilyMember(family.id, user.id, 'admin');

    // Add role to user_roles (if needed)
    const { error: roleError } = await supabase.from('user_roles').insert({
      user_id: user.id,
      family_id: family.id,
      role: 'admin',
    });

    if (roleError) throw roleError;

    // Create baby
    const { data: baby, error: babyError } = await supabase
      .from('babies')
      .insert({
        family_id: family.id,
        name: babyName,
        date_of_birth: dateOfBirth,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      })
      .select('*')
      .single();

    if (babyError) throw babyError;

    return { family, baby };
  }

  async getFamilyMembers(familyId: string) {
    const { data, error } = await supabase
      .from('family_members')
      .select(
        `
        id,
        user_id,
        role,
        profiles (
          name,
          email
        )
      `
      )
      .eq('family_id', familyId);

    if (error) throw error;
    return data;
  }

  async getPendingInvites(familyId: string) {
    const { data, error } = await supabase
      .from('caregiver_invites')
      .select('*')
      .eq('family_id', familyId)
      .eq('status', 'pending');

    if (error) throw error;
    return data as Invite[];
  }

  async inviteCaregiver(
    familyId: string,
    email: string,
    role: 'admin' | 'member' | 'viewer' = 'member'
  ) {
    // Direct insert if not using edge function
    const { data, error } = await supabase
      .from('caregiver_invites')
      .insert({
        family_id: familyId,
        email,
        role,
      })
      .select('*')
      .single();

    if (error) throw error;
    return data;
  }

  async inviteCaregiverViaEdgeFunction(familyId: string, email: string, role: string) {
    const { data, error } = await supabase.functions.invoke('invite-caregiver', {
      body: {
        email,
        familyId,
        role,
      },
    });

    if (error) throw error;
    return data;
  }

  async removeMember(memberId: string) {
    const { error } = await supabase.from('family_members').delete().eq('id', memberId);

    if (error) throw error;
  }

  async getActivityFeed(familyId: string, limit = 50) {
    const { data, error } = await supabase
      .from('activity_feed')
      .select(
        `
        *,
        profiles:actor_id (name, email)
      `
      )
      .eq('family_id', familyId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data;
  }

  async getInviteByToken(token: string) {
    const { data, error } = await supabase
      .from('caregiver_invites')
      .select('*, families(name)')
      .eq('token', token)
      .eq('status', 'pending')
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data;
  }

  async acceptInvite(
    inviteId: string,
    userId: string,
    familyId: string,
    role: string
  ): Promise<void> {
    // Add user to family
    const { error: memberError } = await supabase.from('family_members').insert({
      family_id: familyId,
      user_id: userId,
      role,
    });

    if (memberError) throw memberError;

    // Mark invite as accepted
    const { error: updateError } = await supabase
      .from('caregiver_invites')
      .update({ status: 'accepted' })
      .eq('id', inviteId);

    if (updateError) throw updateError;
  }

  async declineInvite(inviteId: string): Promise<void> {
    const { error } = await supabase
      .from('caregiver_invites')
      .update({ status: 'declined' })
      .eq('id', inviteId);

    if (error) throw error;
  }
}

export const familyService = new FamilyService();
