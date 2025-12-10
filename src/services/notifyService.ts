import { LocalNotifications } from '@capacitor/local-notifications';
import { dataService } from './dataService';
import type { NotificationSettings } from '@/types/events';

class NotifyService {
  private checkInterval: NodeJS.Timeout | null = null;

  async startMonitoring(babyId: string): Promise<void> {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }

    this.checkInterval = setInterval(() => {
      this.checkReminders(babyId);
    }, 60000);

    this.checkReminders(babyId);
  }

  stopMonitoring(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }
  }

  private async checkReminders(babyId: string): Promise<void> {
    const settings = await dataService.getNotificationSettings(babyId);
    if (!settings) return;

    const now = new Date();

    if (this.isQuietHours(now, settings)) {
      return;
    }

    if (settings.feedReminderEnabled) {
      await this.checkFeedReminder(babyId, settings.feedReminderHours);
    }

    if (settings.napWindowAlertEnabled) {
      await this.checkNapWindowAlert(babyId);
    }

    if (settings.diaperReminderEnabled) {
      await this.checkDiaperReminder(babyId, settings.diaperReminderHours);
    }
  }

  private isQuietHours(now: Date, settings: NotificationSettings): boolean {
    const currentTime = now.getHours() * 60 + now.getMinutes();
    const [startHour, startMin] = settings.quietHoursStart.split(':').map(Number);
    const [endHour, endMin] = settings.quietHoursEnd.split(':').map(Number);

    const quietStart = startHour * 60 + startMin;
    const quietEnd = endHour * 60 + endMin;

    if (quietStart < quietEnd) {
      return currentTime >= quietStart && currentTime <= quietEnd;
    } else {
      return currentTime >= quietStart || currentTime <= quietEnd;
    }
  }

  private async checkFeedReminder(babyId: string, hours: number): Promise<void> {
    const lastFeed = await dataService.getLastEventByType(babyId, 'feed');
    if (!lastFeed) return;

    const hoursSinceLastFeed =
      (Date.now() - new Date(lastFeed.startTime).getTime()) / (1000 * 60 * 60);

    if (hoursSinceLastFeed >= hours) {
      await this.sendNotification(
        'Feed Reminder',
        `It's been ${Math.floor(hoursSinceLastFeed)} hours since last feed`
      );
    }
  }

  private async checkNapWindowAlert(babyId: string): Promise<void> {
    const prediction = await dataService.getNapPrediction(babyId);
    if (!prediction) return;

    const now = Date.now();
    const windowStart = new Date(prediction.nextWindowStartISO).getTime();
    const windowEnd = new Date(prediction.nextWindowEndISO).getTime();

    if (now >= windowStart && now < windowEnd) {
      await this.sendNotification('Nap Window', 'Ideal nap window is starting now!');
    }
  }

  private async checkDiaperReminder(babyId: string, hours: number): Promise<void> {
    const lastDiaper = await dataService.getLastEventByType(babyId, 'diaper');
    if (!lastDiaper) return;

    const hoursSinceLastDiaper =
      (Date.now() - new Date(lastDiaper.startTime).getTime()) / (1000 * 60 * 60);

    if (hoursSinceLastDiaper >= hours) {
      await this.sendNotification(
        'Diaper Reminder',
        `It's been ${Math.floor(hoursSinceLastDiaper)} hours since last diaper change`
      );
    }
  }

  async sendNotification(title: string, body: string): Promise<void> {
    try {
      const hasPermission = await this.checkPermission();
      if (hasPermission) {
        await LocalNotifications.schedule({
          notifications: [
            {
              title,
              body,
              id: Date.now(),
              schedule: { at: new Date(Date.now() + 1000) },
            },
          ],
        });
      }
    } catch (error) {
      console.error('Failed to send notification:', error);
    }
  }

  async checkPermission(): Promise<boolean> {
    try {
      const result = await LocalNotifications.checkPermissions();
      return result.display === 'granted';
    } catch {
      return false;
    }
  }

  async requestPermission(): Promise<boolean> {
    try {
      const result = await LocalNotifications.requestPermissions();
      return result.display === 'granted';
    } catch {
      return false;
    }
  }
}

export const notifyService = new NotifyService();
