import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';
import type { NotificationSettings } from '@/lib/types';

class NotificationSettingsService {
  async getNotificationSettings(
    babyId: string,
    userId?: string
  ): Promise<NotificationSettings | null> {
    const {
      data: { user },
    } = await authService.getUser();
    const targetUserId = userId || user?.id;
    if (!targetUserId) return null;

    const { data, error } = await supabase
      .from('notification_settings')
      .select('*')
      .eq('baby_id', babyId)
      .eq('user_id', targetUserId)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') throw error;

    if (!data) {
      // Create default settings
      const defaultSettings: Partial<NotificationSettings> = {
        baby_id: babyId,
        user_id: targetUserId,
        enabled: true,
        feed_reminders_enabled: false,
        feed_reminder_interval_hours: 3,
        nap_reminders_enabled: true,
        nap_window_reminder_minutes: 15,
        diaper_reminders_enabled: false,
        diaper_reminder_interval_hours: 3,
        medication_reminders_enabled: true,
      };

      const { data: newSettings, error: insertError } = await supabase
        .from('notification_settings')
        .insert(defaultSettings)
        .select()
        .single();

      if (insertError) throw insertError;
      return newSettings as NotificationSettings;
    }

    return data as NotificationSettings;
  }

  async updateNotificationSettings(
    id: string,
    updates: Partial<NotificationSettings>
  ): Promise<void> {
    const { error } = await supabase.from('notification_settings').update(updates).eq('id', id);

    if (error) throw error;
  }

  async createNotificationSettings(
    settings: Omit<NotificationSettings, 'id' | 'created_at' | 'updated_at'>
  ): Promise<NotificationSettings> {
    const { data, error } = await supabase
      .from('notification_settings')
      .insert(settings)
      .select()
      .single();

    if (error) throw error;
    return data as NotificationSettings;
  }

  async deleteNotificationSettings(id: string): Promise<void> {
    const { error } = await supabase.from('notification_settings').delete().eq('id', id);

    if (error) throw error;
  }
}

export const notificationSettingsService = new NotificationSettingsService();

