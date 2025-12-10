import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';

export interface AppSettings {
  id: string;
  user_id: string;
  theme?: 'light' | 'dark' | 'system';
  font_size?: 'small' | 'medium' | 'large' | 'xlarge';
  caregiver_mode?: boolean;
  created_at: string;
  updated_at: string;
}

class AppSettingsService {
  async getAppSettings(userId?: string): Promise<AppSettings | null> {
    const { data: { user } } = await authService.getUser();
    const targetUserId = userId || user?.id;
    if (!targetUserId) return null;

    const { data, error } = await supabase
      .from('app_settings')
      .select('*')
      .eq('user_id', targetUserId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as AppSettings;
  }

  async createOrUpdateAppSettings(settings: Partial<AppSettings>): Promise<AppSettings> {
    const { data: { user } } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    // Try to get existing settings
    const existing = await this.getAppSettings(user.id);

    if (existing) {
      // Update existing
      const { data, error } = await supabase
        .from('app_settings')
        .update(settings)
        .eq('id', existing.id)
        .select()
        .single();

      if (error) throw error;
      return data as AppSettings;
    } else {
      // Create new
      const { data, error } = await supabase
        .from('app_settings')
        .insert({
          user_id: user.id,
          ...settings,
        })
        .select()
        .single();

      if (error) throw error;
      return data as AppSettings;
    }
  }
}

export const appSettingsService = new AppSettingsService();


