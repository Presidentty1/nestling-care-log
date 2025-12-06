import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';
import { Profile } from '@/lib/types';

class ProfileService {
  async getProfile(userId: string): Promise<Profile | null> {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as Profile;
  }

  async updateProfile(userId: string, updates: Partial<Profile>): Promise<Profile> {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data as Profile;
  }

  async deleteProfile(userId: string): Promise<void> {
    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', userId);

    if (error) throw error;
  }

  async deleteAppSettings(userId: string): Promise<void> {
    const { error } = await supabase
      .from('app_settings')
      .delete()
      .eq('user_id', userId);

    if (error) throw error;
  }
}

export const profileService = new ProfileService();
