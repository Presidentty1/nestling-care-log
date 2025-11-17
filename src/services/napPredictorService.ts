import { differenceInMonths, addMinutes } from 'date-fns';
import { EventRecord } from './eventsService';

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
