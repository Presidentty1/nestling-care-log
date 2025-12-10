import type { EventRecord, EventType } from '@/types/events';

export interface DaySummary {
  feedCount: number;
  totalMl: number;
  sleepMinutes: number;
  sleepCount: number;
  diaperWet: number;
  diaperDirty: number;
  diaperTotal: number;
  tummyTimeMinutes: number;
}

/**
 * Calculate day totals from events
 */
export function getDayTotals(events: EventRecord[]): DaySummary {
  const summary: DaySummary = {
    feedCount: 0,
    totalMl: 0,
    sleepMinutes: 0,
    sleepCount: 0,
    diaperWet: 0,
    diaperDirty: 0,
    diaperTotal: 0,
    tummyTimeMinutes: 0,
  };

  events.forEach(event => {
    switch (event.type) {
      case 'feed':
        summary.feedCount++;
        if (event.amount) {
          summary.totalMl += event.amount;
        }
        break;

      case 'sleep':
        summary.sleepCount++;
        if (event.durationMin) {
          summary.sleepMinutes += event.durationMin;
        } else if (event.startTime && event.endTime) {
          const duration = Math.round(
            (new Date(event.endTime).getTime() - new Date(event.startTime).getTime()) / 60000
          );
          summary.sleepMinutes += duration;
        }
        break;

      case 'diaper':
        summary.diaperTotal++;
        if (event.subtype === 'wet') {
          summary.diaperWet++;
        } else if (event.subtype === 'dirty') {
          summary.diaperDirty++;
        } else if (event.subtype === 'both') {
          summary.diaperWet++;
          summary.diaperDirty++;
        }
        break;

      case 'tummy_time':
        if (event.durationMin) {
          summary.tummyTimeMinutes += event.durationMin;
        }
        break;
    }
  });

  return summary;
}

/**
 * Get the last event of a specific type
 */
export function getLastEventByType(events: EventRecord[], type: EventType): EventRecord | null {
  const filtered = events
    .filter(e => e.type === type)
    .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());

  return filtered[0] || null;
}

/**
 * Filter events by day (ISO date string)
 */
export function getEventsByDay(events: EventRecord[], dayISO: string): EventRecord[] {
  return events.filter(e => {
    const eventDay = e.startTime.split('T')[0];
    return eventDay === dayISO;
  });
}

/**
 * Get events for today
 */
export function getTodayEvents(events: EventRecord[]): EventRecord[] {
  const today = new Date().toISOString().split('T')[0];
  return getEventsByDay(events, today);
}

/**
 * Get events for the last 7 days
 */
export function getWeekEvents(events: EventRecord[]): EventRecord[] {
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  return events.filter(e => {
    const eventDate = new Date(e.startTime);
    return eventDate >= sevenDaysAgo && eventDate <= now;
  });
}

/**
 * Calculate average feed amount for last N feeds
 */
export function getAverageFeedAmount(events: EventRecord[], count: number = 5): number {
  const feeds = events
    .filter(e => e.type === 'feed' && e.amount)
    .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime())
    .slice(0, count);

  if (feeds.length === 0) return 0;

  const total = feeds.reduce((sum, e) => sum + (e.amount || 0), 0);
  return Math.round(total / feeds.length);
}

/**
 * Calculate average sleep duration for last N sleeps
 */
export function getAverageSleepDuration(events: EventRecord[], count: number = 5): number {
  const sleeps = events
    .filter(e => e.type === 'sleep' && e.durationMin)
    .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime())
    .slice(0, count);

  if (sleeps.length === 0) return 0;

  const total = sleeps.reduce((sum, e) => sum + (e.durationMin || 0), 0);
  return Math.round(total / sleeps.length);
}
