import { LocalNotifications } from '@capacitor/local-notifications';
import { supabase } from '@/integrations/supabase/client';
import type { NotificationSettings, Medication } from './types';

class NotificationManager {
  private notificationIds = {
    feed: 1000,
    nap: 2000,
    diaper: 3000,
    medication: 4000,
  };

  async getSettings(babyId: string): Promise<NotificationSettings | null> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) return null;

    const { data } = await supabase
      .from('notification_settings')
      .select('*')
      .eq('baby_id', babyId)
      .eq('user_id', user.user.id)
      .maybeSingle();

    return data;
  }

  async scheduleNextFeedReminder(babyId: string, lastFeedTime: Date) {
    const settings = await this.getSettings(babyId);
    if (!settings?.enabled || !settings.feed_reminders_enabled) return;

    const nextFeedTime = new Date(lastFeedTime);
    nextFeedTime.setHours(nextFeedTime.getHours() + settings.feed_reminder_interval_hours);

    if (this.isQuietHours(nextFeedTime, settings)) {
      return;
    }

    await LocalNotifications.schedule({
      notifications: [
        {
          title: 'Feed Reminder',
          body: `It's been ${settings.feed_reminder_interval_hours} hours since last feeding`,
          id: this.notificationIds.feed,
          schedule: { at: nextFeedTime },
          extra: { type: 'feed', babyId },
          actionTypeId: 'FEED_ACTIONS',
        },
      ],
    });
  }

  async scheduleNapWindowReminder(babyId: string, napWindowStart: Date) {
    const settings = await this.getSettings(babyId);
    if (!settings?.enabled || !settings.nap_reminders_enabled) return;

    const reminderTime = new Date(napWindowStart);
    reminderTime.setMinutes(reminderTime.getMinutes() - settings.nap_window_reminder_minutes);

    if (this.isQuietHours(reminderTime, settings)) {
      return;
    }

    await LocalNotifications.schedule({
      notifications: [
        {
          title: 'Nap Window Approaching',
          body: `Nap window starts at ${napWindowStart.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`,
          id: this.notificationIds.nap,
          schedule: { at: reminderTime },
          extra: { type: 'nap', babyId },
          actionTypeId: 'NAP_ACTIONS',
        },
      ],
    });
  }

  async scheduleDiaperReminder(babyId: string, lastDiaperTime: Date) {
    const settings = await this.getSettings(babyId);
    if (!settings?.enabled || !settings.diaper_reminders_enabled) return;

    const nextReminderTime = new Date(lastDiaperTime);
    nextReminderTime.setHours(
      nextReminderTime.getHours() + settings.diaper_reminder_interval_hours
    );

    if (this.isQuietHours(nextReminderTime, settings)) {
      return;
    }

    await LocalNotifications.schedule({
      notifications: [
        {
          title: 'Diaper Check Reminder',
          body: `It's been ${settings.diaper_reminder_interval_hours} hours since last change`,
          id: this.notificationIds.diaper,
          schedule: { at: nextReminderTime },
          extra: { type: 'diaper', babyId },
          actionTypeId: 'DIAPER_ACTIONS',
        },
      ],
    });
  }

  async scheduleMedicationReminder(medication: Medication) {
    const settings = await this.getSettings(medication.baby_id);
    if (!settings?.enabled || !settings.medication_reminders_enabled) return;
    if (!medication.reminder_enabled || !medication.reminder_times) return;

    const notifications = medication.reminder_times.map((timeStr, idx) => {
      const [hours, minutes] = timeStr.split(':').map(Number);
      const reminderTime = new Date();
      reminderTime.setHours(hours, minutes, 0, 0);

      // If time has passed today, schedule for tomorrow
      if (reminderTime < new Date()) {
        reminderTime.setDate(reminderTime.getDate() + 1);
      }

      return {
        title: `Medication: ${medication.name}`,
        body: medication.dose ? `Time for ${medication.dose}` : 'Time for medication',
        id: this.notificationIds.medication + idx,
        schedule: { at: reminderTime },
        extra: { type: 'medication', medicationId: medication.id },
      };
    });

    await LocalNotifications.schedule({ notifications });
  }

  async cancelNotification(id: number) {
    try {
      await LocalNotifications.cancel({ notifications: [{ id }] });
    } catch (error) {
      console.error('Failed to cancel notification:', error);
    }
  }

  async cancelAllReminders(babyId: string) {
    await this.cancelNotification(this.notificationIds.feed);
    await this.cancelNotification(this.notificationIds.nap);
    await this.cancelNotification(this.notificationIds.diaper);
  }

  async requestPermission(): Promise<boolean> {
    try {
      const result = await LocalNotifications.requestPermissions();
      return result.display === 'granted';
    } catch (error) {
      console.error('Failed to request notification permission:', error);
      return false;
    }
  }

  private isQuietHours(time: Date, settings: NotificationSettings): boolean {
    if (!settings.quiet_hours_start || !settings.quiet_hours_end) {
      return false;
    }

    const hour = time.getHours();
    const minute = time.getMinutes();
    const timeStr = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;

    return timeStr >= settings.quiet_hours_start && timeStr <= settings.quiet_hours_end;
  }
}

export const notificationManager = new NotificationManager();
