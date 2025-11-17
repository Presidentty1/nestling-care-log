import localforage from 'localforage';
import { EventRecord, TimerState, Baby, NapFeedback, NotificationSettings } from '@/types/events';
import { differenceInMinutes } from 'date-fns';

const eventsStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'events',
});

const timersStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'timers',
});

const babiesStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'babies',
});

const napFeedbackStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'napFeedback',
});

const settingsStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'settings',
});

class DataService {
  private listeners: Array<(action: string, data: any) => void> = [];

  async addEvent(event: Omit<EventRecord, 'id' | 'createdAt' | 'updatedAt' | 'source'>): Promise<EventRecord> {
    const now = new Date().toISOString();
    const record: EventRecord = {
      ...event,
      id: crypto.randomUUID(),
      createdAt: now,
      updatedAt: now,
      source: 'local',
    };
    
    if (record.startTime && record.endTime) {
      record.durationMin = differenceInMinutes(
        new Date(record.endTime),
        new Date(record.startTime)
      );
    }
    
    await eventsStore.setItem(record.id, record);
    this.emitChange('add', record);
    return record;
  }
  
  async updateEvent(id: string, updates: Partial<EventRecord>): Promise<EventRecord> {
    const existing = await eventsStore.getItem<EventRecord>(id);
    if (!existing) throw new Error('Event not found');
    
    const updated: EventRecord = {
      ...existing,
      ...updates,
      updatedAt: new Date().toISOString(),
    };
    
    if (updated.startTime && updated.endTime) {
      updated.durationMin = differenceInMinutes(
        new Date(updated.endTime),
        new Date(updated.startTime)
      );
    }
    
    await eventsStore.setItem(id, updated);
    this.emitChange('update', updated);
    return updated;
  }
  
  async deleteEvent(id: string): Promise<void> {
    await eventsStore.removeItem(id);
    this.emitChange('delete', { id });
  }

  async getEvent(id: string): Promise<EventRecord | null> {
    return await eventsStore.getItem<EventRecord>(id);
  }
  
  async listEventsByDay(babyId: string, dayISO: string): Promise<EventRecord[]> {
    const events: EventRecord[] = [];
    const dayStart = new Date(dayISO);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dayISO);
    dayEnd.setHours(23, 59, 59, 999);
    
    await eventsStore.iterate<EventRecord, void>((event) => {
      if (event.babyId === babyId) {
        const eventTime = new Date(event.startTime);
        if (eventTime >= dayStart && eventTime <= dayEnd) {
          events.push(event);
        }
      }
    });
    
    return events.sort((a, b) => 
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );
  }
  
  async listEventsRange(babyId: string, fromISO: string, toISO: string): Promise<EventRecord[]> {
    const events: EventRecord[] = [];
    const start = new Date(fromISO);
    const end = new Date(toISO);
    
    await eventsStore.iterate<EventRecord, void>((event) => {
      if (event.babyId === babyId) {
        const eventTime = new Date(event.startTime);
        if (eventTime >= start && eventTime <= end) {
          events.push(event);
        }
      }
    });
    
    return events.sort((a, b) => 
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );
  }
  
  async getLastEventByType(babyId: string, type: string): Promise<EventRecord | null> {
    let lastEvent: EventRecord | null = null;
    let latestTime = 0;
    
    await eventsStore.iterate<EventRecord, void>((event) => {
      if (event.babyId === babyId && event.type === type) {
        const eventTime = new Date(event.startTime).getTime();
        if (eventTime > latestTime) {
          latestTime = eventTime;
          lastEvent = event;
        }
      }
    });
    
    return lastEvent;
  }
  
  async saveTimerState(babyId: string, state: TimerState): Promise<void> {
    await timersStore.setItem(`timer_${babyId}`, state);
  }
  
  async getTimerState(babyId: string): Promise<TimerState | null> {
    return await timersStore.getItem(`timer_${babyId}`);
  }
  
  async clearTimerState(babyId: string): Promise<void> {
    await timersStore.removeItem(`timer_${babyId}`);
  }

  async getAllEvents(): Promise<EventRecord[]> {
    const events: EventRecord[] = [];
    await eventsStore.iterate<EventRecord, void>((event) => {
      events.push(event);
    });
    return events.sort((a, b) => 
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );
  }

  async addBaby(baby: Omit<Baby, 'id' | 'createdAt' | 'updatedAt'>): Promise<Baby> {
    const now = new Date().toISOString();
    const record: Baby = {
      ...baby,
      id: crypto.randomUUID(),
      createdAt: now,
      updatedAt: now,
    };
    await babiesStore.setItem(record.id, record);
    this.emitChange('baby_added', record);
    return record;
  }

  async listBabies(): Promise<Baby[]> {
    const babies: Baby[] = [];
    await babiesStore.iterate<Baby, void>((baby) => {
      babies.push(baby);
    });
    return babies.sort((a, b) => 
      new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
    );
  }

  async getBaby(id: string): Promise<Baby | null> {
    return await babiesStore.getItem<Baby>(id);
  }

  async updateBaby(id: string, updates: Partial<Baby>): Promise<Baby> {
    const existing = await babiesStore.getItem<Baby>(id);
    if (!existing) throw new Error('Baby not found');
    
    const updated: Baby = {
      ...existing,
      ...updates,
      updatedAt: new Date().toISOString(),
    };
    
    await babiesStore.setItem(id, updated);
    this.emitChange('baby_updated', updated);
    return updated;
  }

  async deleteBaby(id: string): Promise<void> {
    await babiesStore.removeItem(id);
    this.emitChange('baby_deleted', { id });
  }

  async addNapFeedback(feedback: Omit<NapFeedback, 'id' | 'createdAt'>): Promise<NapFeedback> {
    const record: NapFeedback = {
      ...feedback,
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
    };
    await napFeedbackStore.setItem(record.id, record);
    return record;
  }

  async listNapFeedback(babyId: string): Promise<NapFeedback[]> {
    const feedbacks: NapFeedback[] = [];
    await napFeedbackStore.iterate<NapFeedback, void>((feedback) => {
      if (feedback.babyId === babyId) {
        feedbacks.push(feedback);
      }
    });
    return feedbacks.sort((a, b) => 
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }

  async saveNotificationSettings(babyId: string, settings: NotificationSettings): Promise<void> {
    await settingsStore.setItem(`notifications_${babyId}`, settings);
  }

  async getNotificationSettings(babyId: string): Promise<NotificationSettings | null> {
    return await settingsStore.getItem(`notifications_${babyId}`);
  }

  async clearAllData(): Promise<{ eventsCleared: number; timersCleared: number; babiesCleared: number }> {
    const eventsCount = await eventsStore.length();
    const timersCount = await timersStore.length();
    const babiesCount = await babiesStore.length();
    
    await eventsStore.clear();
    await timersStore.clear();
    await babiesStore.clear();
    await napFeedbackStore.clear();
    await settingsStore.clear();
    
    this.emitChange('clear', {});
    
    return {
      eventsCleared: eventsCount,
      timersCleared: timersCount,
      babiesCleared: babiesCount,
    };
  }

  subscribe(callback: (action: string, data: any) => void): () => void {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }
  
  private emitChange(action: string, data: any): void {
    this.listeners.forEach(listener => listener(action, data));
  }

  async getTodaySummary(babyId: string) {
    const today = new Date().toISOString().split('T')[0];
    return this.getDaySummary(babyId, today);
  }

  async getDaySummary(babyId: string, dateISO: string) {
    const events = await this.listEventsByDay(babyId, dateISO);
    
    const feeds = events.filter(e => e.type === 'feed');
    const sleeps = events.filter(e => e.type === 'sleep' && e.endTime);
    const diapers = events.filter(e => e.type === 'diaper');
    
    const totalMl = feeds.reduce((sum, e) => {
      if (!e.amount) return sum;
      // Convert oz to ml if needed (1 oz = 29.5735 ml)
      const ml = e.unit === 'oz' ? e.amount * 29.5735 : e.amount;
      return sum + ml;
    }, 0);

    const sleepMinutes = sleeps.reduce((sum, e) => sum + (e.durationMin || 0), 0);

    const diaperWet = diapers.filter(e => 
      e.subtype === 'wet' || e.subtype === 'both'
    ).length;
    
    const diaperDirty = diapers.filter(e => 
      e.subtype === 'dirty' || e.subtype === 'both'
    ).length;

    // Get last feed and wake times
    const lastFeed = feeds.length > 0 ? feeds[0] : null;
    const lastSleep = sleeps.length > 0 ? sleeps[0] : null;

    return {
      feedCount: feeds.length,
      totalMl: Math.round(totalMl),
      sleepMinutes,
      sleepCount: sleeps.length,
      diaperWet,
      diaperDirty,
      diaperTotal: diaperWet + diaperDirty,
      lastFeedTime: lastFeed?.startTime,
      lastWakeTime: lastSleep?.endTime,
    };
  }

  async storeNapPrediction(babyId: string, prediction: any): Promise<void> {
    const key = `nap_prediction_${babyId}`;
    await localforage.setItem(key, {
      ...prediction,
      timestamp: new Date().toISOString(),
    });
  }

  async getNapPrediction(babyId: string): Promise<any | null> {
    const key = `nap_prediction_${babyId}`;
    return await localforage.getItem(key);
  }
}

export const dataService = new DataService();
