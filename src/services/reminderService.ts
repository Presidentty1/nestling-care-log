import { differenceInHours, differenceInMinutes, addMinutes } from 'date-fns';
import { toast } from 'sonner';
import type { EventRecord } from './eventsService';

interface ReminderSettings {
  feedReminderEnabled: boolean;
  feedReminderHours: number;
  napReminderEnabled: boolean;
  napReminderMinutes: number;
  quietHoursStart: string; // "22:00"
  quietHoursEnd: string; // "07:00"
}

class ReminderService {
  private intervalId: number | null = null;
  private settings: ReminderSettings = {
    feedReminderEnabled: false,
    feedReminderHours: 3,
    napReminderEnabled: false,
    napReminderMinutes: 10,
    quietHoursStart: '22:00',
    quietHoursEnd: '07:00',
  };
  private lastFeedEvent: EventRecord | null = null;
  private nextNapWindow: { start: Date; end: Date } | null = null;

  updateSettings(settings: Partial<ReminderSettings>) {
    this.settings = { ...this.settings, ...settings };
  }

  updateLastFeed(event: EventRecord | null) {
    this.lastFeedEvent = event;
  }

  updateNapWindow(window: { start: Date; end: Date } | null) {
    this.nextNapWindow = window;
  }

  private isQuietHours(): boolean {
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const currentTime = hours * 60 + minutes;

    const [startH, startM] = this.settings.quietHoursStart.split(':').map(Number);
    const [endH, endM] = this.settings.quietHoursEnd.split(':').map(Number);
    const startTime = startH * 60 + startM;
    const endTime = endH * 60 + endM;

    if (startTime < endTime) {
      return currentTime >= startTime && currentTime < endTime;
    } else {
      // Quiet hours span midnight
      return currentTime >= startTime || currentTime < endTime;
    }
  }

  private checkReminders() {
    if (this.isQuietHours()) return;

    const now = new Date();

    // Feed reminder
    if (this.settings.feedReminderEnabled && this.lastFeedEvent) {
      const hoursSinceLastFeed = differenceInHours(now, new Date(this.lastFeedEvent.start_time));

      if (hoursSinceLastFeed >= this.settings.feedReminderHours) {
        toast('🍼 Time for a feeding', {
          description: `It's been ${hoursSinceLastFeed} hours since the last feed`,
          duration: 5000,
        });
        // Reset to avoid repeated toasts
        this.lastFeedEvent = null;
      }
    }

    // Nap reminder
    if (this.settings.napReminderEnabled && this.nextNapWindow) {
      const minutesUntilNap = differenceInMinutes(this.nextNapWindow.start, now);

      if (minutesUntilNap <= this.settings.napReminderMinutes && minutesUntilNap > 0) {
        toast('😴 Nap time approaching', {
          description: `Nap window starts in ${minutesUntilNap} minutes`,
          duration: 5000,
        });
        // Reset to avoid repeated toasts
        this.nextNapWindow = null;
      }
    }
  }

  start() {
    if (this.intervalId) return;

    // Check every minute
    this.intervalId = window.setInterval(() => {
      this.checkReminders();
    }, 60000);

    // Initial check
    this.checkReminders();
  }

  stop() {
    if (this.intervalId) {
      window.clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }
}

export const reminderService = new ReminderService();
