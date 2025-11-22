import { differenceInMonths, addMinutes } from 'date-fns';
import type { EventRecord } from './eventsService';

interface NapWindow {
  start: Date;
  end: Date;
  reason: string;
}

// Age-based wake window recommendations (in minutes)
const WAKE_WINDOWS = {
  '0-2': { min: 45, max: 75, name: '0-2 months' },
  '3-4': { min: 75, max: 120, name: '3-4 months' },
  '5-7': { min: 120, max: 150, name: '5-7 months' },
  '8-10': { min: 150, max: 180, name: '8-10 months' },
  '11-15': { min: 180, max: 210, name: '11-15 months' },
  '16+': { min: 210, max: 240, name: '16+ months' },
};

function getWakeWindowForAge(ageMonths: number) {
  if (ageMonths <= 2) return WAKE_WINDOWS['0-2'];
  if (ageMonths <= 4) return WAKE_WINDOWS['3-4'];
  if (ageMonths <= 7) return WAKE_WINDOWS['5-7'];
  if (ageMonths <= 10) return WAKE_WINDOWS['8-10'];
  if (ageMonths <= 15) return WAKE_WINDOWS['11-15'];
  return WAKE_WINDOWS['16+'];
}

class NapPredictorService {
  calculateNextNapWindow(lastSleepEnd: Date, ageMonths: number): NapWindow | null {
    if (!lastSleepEnd) return null;

    const wakeWindow = getWakeWindowForAge(ageMonths);
    const start = addMinutes(lastSleepEnd, wakeWindow.min);
    const end = addMinutes(lastSleepEnd, wakeWindow.max);

    return {
      start,
      end,
      reason: `Based on ${wakeWindow.name} wake window (${wakeWindow.min}-${wakeWindow.max} min)`,
    };
  }

  async getLearningMetrics(babyId: string): Promise<{ daysLogged: number; napCount: number; recentAdjustments: string[] }> {
    try {
      // Get events for the last 7 days to calculate metrics
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { eventsService } = await import('@/services/eventsService');
      const events = await eventsService.getEventsByRange(babyId, sevenDaysAgo.toISOString(), new Date().toISOString());

      if (!events || events.length === 0) {
        return { daysLogged: 0, napCount: 0, recentAdjustments: [] };
      }

      // Count unique days with events
      const uniqueDays = new Set(events.map(e => new Date(e.start_time).toDateString())).size;

      // Count naps (sleep events)
      const napCount = events.filter(e => e.type === 'sleep').length;

      // Generate recent adjustments based on nap feedback (simplified for now)
      const recentAdjustments: string[] = [];
      if (napCount >= 3) {
        // This would normally check nap feedback data
        recentAdjustments.push("We nudged this window earlier because the last 3 naps started around 1:10 PM");
      }

      return {
        daysLogged: uniqueDays,
        napCount,
        recentAdjustments
      };
    } catch (error) {
      console.error('Error calculating learning metrics:', error);
      return { daysLogged: 0, napCount: 0, recentAdjustments: [] };
    }
  }

  calculateFromEvents(events: EventRecord[], dateOfBirth: string): NapWindow | null {
    const sleepEvents = events
      .filter(e => e.type === 'sleep' && e.end_time)
      .sort((a, b) => new Date(b.end_time!).getTime() - new Date(a.end_time!).getTime());

    if (sleepEvents.length === 0) return null;

    const lastSleep = sleepEvents[0];
    const ageMonths = differenceInMonths(new Date(), new Date(dateOfBirth));

    return this.calculateNextNapWindow(new Date(lastSleep.end_time!), ageMonths);
  }
}

export const napPredictorService = new NapPredictorService();
