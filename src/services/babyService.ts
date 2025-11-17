import { supabase } from '@/integrations/supabase/client';

export interface Baby {
  id: string;
  family_id: string;
  name: string;
  date_of_birth: string;
  sex?: 'm' | 'f' | 'other' | null;
  primary_feeding_style?: 'breast' | 'bottle' | 'both' | null;
  timezone: string;
  created_at: string;
  updated_at: string;
}

class BabyService {
  async getUserBabies(): Promise<Baby[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    // Get user's families
    const { data: memberships } = await supabase
      .from('family_members')
      .select('family_id')
      .eq('user_id', user.id);

    if (!memberships || memberships.length === 0) return [];

    const familyIds = memberships.map(m => m.family_id);

    // Get babies from those families
    const { data: babies, error } = await supabase
      .from('babies')
      .select('*')
      .in('family_id', familyIds)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return (babies || []) as Baby[];
  }

  async getBaby(id: string): Promise<Baby | null> {
    const { data, error } = await supabase
      .from('babies')
      .select('*')
      .eq('id', id)
      .single();

    if (error) return null;
    return data as Baby;
  }

  async createBaby(baby: {
    family_id: string;
    name: string;
    date_of_birth: string;
    sex?: 'm' | 'f' | 'other';
    primary_feeding_style?: 'breast' | 'bottle' | 'both';
  }): Promise<Baby> {
    const { data, error } = await supabase
      .from('babies')
      .insert({
        ...baby,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      })
      .select('*')
      .single();

    if (error) throw error;
    return data as Baby;
  }

  async updateBaby(id: string, updates: Partial<Baby>): Promise<Baby> {
    const { data, error } = await supabase
      .from('babies')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data as Baby;
  }

  async deleteBaby(id: string): Promise<void> {
    const { error } = await supabase
      .from('babies')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const babyService = new BabyService();
