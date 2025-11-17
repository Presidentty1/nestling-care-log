import { dataService } from './dataService';
import { notificationService } from '@/components/NotificationBanner';
import { differenceInHours, differenceInMinutes } from 'date-fns';

let monitorInterval: NodeJS.Timeout | null = null;
let currentBabyId: string | null = null;

export const notificationMonitor = {
  start: async (babyId: string) => {
    if (monitorInterval) {
      clearInterval(monitorInterval);
    }

    currentBabyId = babyId;
    
    // Check immediately
    await checkReminders();

    // Check every minute
    monitorInterval = setInterval(checkReminders, 60000);
  },

  stop: () => {
    if (monitorInterval) {
      clearInterval(monitorInterval);
      monitorInterval = null;
    }
    currentBabyId = null;
  },
};

async function checkReminders() {
  if (!currentBabyId) return;

  try {
    const settings = await dataService.getNotificationSettings(currentBabyId);
    if (!settings) return;

    const now = new Date();
    
    // Check quiet hours
    if (isQuietHours(now, settings)) return;

    // Check feed reminder
    if (settings.feedReminderEnabled) {
      const lastFeed = await dataService.getLastEventByType(currentBabyId, 'feed');
      if (lastFeed) {
        const hoursSinceLastFeed = differenceInHours(now, new Date(lastFeed.startTime));
        if (hoursSinceLastFeed >= settings.feedReminderHours) {
          notificationService.show(
            'feed',
            `Feed reminder: It's been ${hoursSinceLastFeed} hours since last feed`
          );
        }
      }
    }

    // Check nap window
    if (settings.napWindowAlertEnabled) {
      const napPrediction = localStorage.getItem(`nap_prediction_${currentBabyId}`);
      if (napPrediction) {
        try {
          const prediction = JSON.parse(napPrediction);
          const windowStart = new Date(prediction.nextWindowStartISO);
          const minutesUntilWindow = differenceInMinutes(windowStart, now);
          
          // Alert 15 minutes before nap window
          if (minutesUntilWindow === 15) {
            notificationService.show('nap', 'Nap window starting in 15 minutes');
          }
        } catch (error) {
          console.error('Failed to parse nap prediction:', error);
        }
      }
    }

    // Check diaper reminder
    if (settings.diaperReminderEnabled) {
      const lastDiaper = await dataService.getLastEventByType(currentBabyId, 'diaper');
      if (lastDiaper) {
        const hoursSinceLastDiaper = differenceInHours(now, new Date(lastDiaper.startTime));
        if (hoursSinceLastDiaper >= settings.diaperReminderHours) {
          notificationService.show(
            'diaper',
            `Diaper check: It's been ${hoursSinceLastDiaper} hours since last change`
          );
        }
      }
    }
  } catch (error) {
    console.error('Notification check failed:', error);
  }
}

function isQuietHours(time: Date, settings: any): boolean {
  const hour = time.getHours();
  const minute = time.getMinutes();
  const currentMinutes = hour * 60 + minute;

  const [startHour, startMin] = settings.quietHoursStart.split(':').map(Number);
  const [endHour, endMin] = settings.quietHoursEnd.split(':').map(Number);

  const startMinutes = startHour * 60 + startMin;
  const endMinutes = endHour * 60 + endMin;

  if (startMinutes < endMinutes) {
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  } else {
    // Quiet hours span midnight
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }
}
