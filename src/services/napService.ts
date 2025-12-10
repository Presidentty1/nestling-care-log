import { dataService } from './dataService';
import type { NapPrediction } from '@/types/events';
import { addMinutes, differenceInMonths } from 'date-fns';

interface WakeWindow {
  minMinutes: number;
  maxMinutes: number;
}

const WAKE_WINDOWS: Record<string, WakeWindow> = {
  '0-2m': { minMinutes: 45, maxMinutes: 75 },
  '3-4m': { minMinutes: 75, maxMinutes: 120 },
  '5-7m': { minMinutes: 120, maxMinutes: 150 },
  '8-10m': { minMinutes: 150, maxMinutes: 180 },
  '11-15m': { minMinutes: 180, maxMinutes: 210 },
};

class NapService {
  async calculateNapWindow(babyId: string): Promise<NapPrediction | null> {
    const baby = await dataService.getBaby(babyId);
    if (!baby) return null;

    const lastSleep = await dataService.getLastEventByType(babyId, 'sleep');
    if (!lastSleep || !lastSleep.endTime) return null;

    const ageMonths = differenceInMonths(new Date(), new Date(baby.dobISO));
    const ageBand = this.getAgeBand(ageMonths);
    const window = WAKE_WINDOWS[ageBand] || WAKE_WINDOWS['11-15m'];

    const lastWake = new Date(lastSleep.endTime);
    const windowStart = addMinutes(lastWake, window.minMinutes);
    const windowEnd = addMinutes(lastWake, window.maxMinutes);

    const prediction: NapPrediction = {
      nextWindowStartISO: windowStart.toISOString(),
      nextWindowEndISO: windowEnd.toISOString(),
      confidence: 0.6,
      reason: `Based on ${ageBand} wake windows`,
    };

    await dataService.storeNapPrediction(babyId, prediction);
    return prediction;
  }

  private getAgeBand(months: number): string {
    if (months < 3) return '0-2m';
    if (months < 5) return '3-4m';
    if (months < 8) return '5-7m';
    if (months < 11) return '8-10m';
    return '11-15m';
  }

  // Legacy method kept for compatibility
  async recalculate(babyId: string, babyAgeMonths: number): Promise<NapPrediction | null> {
    return this.calculateNapWindow(babyId);
  }
}

export const napService = new NapService();
