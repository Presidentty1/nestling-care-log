import { dataService } from './dataService';
import { NapPrediction } from '@/types/events';
import { addMinutes } from 'date-fns';

interface WakeWindow {
  minMinutes: number;
  maxMinutes: number;
}

const WAKE_WINDOWS: Record<string, WakeWindow> = {
  '0-3': { minMinutes: 60, maxMinutes: 90 },
  '3-6': { minMinutes: 90, maxMinutes: 120 },
  '6-9': { minMinutes: 120, maxMinutes: 180 },
  '9-12': { minMinutes: 150, maxMinutes: 240 },
  '12+': { minMinutes: 240, maxMinutes: 360 },
};

class NapService {
  async recalculate(babyId: string, babyAgeMonths: number): Promise<NapPrediction | null> {
    const lastSleep = await dataService.getLastEventByType(babyId, 'sleep');
    
    if (!lastSleep || !lastSleep.endTime) {
      return null;
    }
    
    const band = this.getAgeBand(babyAgeMonths);
    const wakeWindow = WAKE_WINDOWS[band];
    
    const lastWake = new Date(lastSleep.endTime);
    const windowStart = addMinutes(lastWake, wakeWindow.minMinutes);
    const windowEnd = addMinutes(lastWake, wakeWindow.maxMinutes);
    
    const confidence = await this.calculateConfidence(babyId);
    
    return {
      nextWindowStartISO: windowStart.toISOString(),
      nextWindowEndISO: windowEnd.toISOString(),
      confidence,
      reason: `Based on ${band} month wake windows`,
    };
  }
  
  private getAgeBand(months: number): string {
    if (months < 3) return '0-3';
    if (months < 6) return '3-6';
    if (months < 9) return '6-9';
    if (months < 12) return '9-12';
    return '12+';
  }
  
  private async calculateConfidence(babyId: string): Promise<number> {
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    
    const events = await dataService.listEventsRange(
      babyId,
      threeDaysAgo.toISOString(),
      new Date().toISOString()
    );
    
    const sleepEvents = events.filter(e => e.type === 'sleep' && e.endTime);
    const dataConfidence = Math.min(sleepEvents.length / 10, 0.9);
    const consistencyConfidence = sleepEvents.length > 5 ? 0.8 : 0.5;
    
    return Math.min((dataConfidence + consistencyConfidence) / 2, 0.95);
  }
}

export const napService = new NapService();
