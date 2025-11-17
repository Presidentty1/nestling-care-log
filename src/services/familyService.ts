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

class FamilyService {
  async getUserFamilies(): Promise<Family[]> {
    const { data: { user } } = await supabase.auth.getUser();
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

  async createFamilyWithBaby(familyName: string, babyName: string, dateOfBirth: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Create family
    const { data: family, error: familyError } = await supabase
      .from('families')
      .insert({ name: familyName })
      .select('*')
      .single();

    if (familyError) throw familyError;

    // Add user as admin
    const { error: memberError } = await supabase
      .from('family_members')
      .insert({
        family_id: family.id,
        user_id: user.id,
        role: 'admin',
      });

    if (memberError) throw memberError;

    // Add role to user_roles
    const { error: roleError } = await supabase
      .from('user_roles')
      .insert({
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
      .select(`
        *,
        profiles:profiles(email, name)
      `)
      .eq('family_id', familyId);

    if (error) throw error;
    return data;
  }

  async inviteCaregiver(familyId: string, email: string, role: 'admin' | 'member' | 'viewer' = 'member') {
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

  async removeMember(memberId: string) {
    const { error } = await supabase
      .from('family_members')
      .delete()
      .eq('id', memberId);

    if (error) throw error;
  }
}

export const familyService = new FamilyService();
