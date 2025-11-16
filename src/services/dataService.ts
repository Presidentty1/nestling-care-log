import localforage from 'localforage';
import { EventRecord, TimerState } from '@/types/events';
import { differenceInMinutes } from 'date-fns';

const eventsStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'events',
});

const timersStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'timers',
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

  subscribe(callback: (action: string, data: any) => void): () => void {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }
  
  private emitChange(action: string, data: any): void {
    this.listeners.forEach(listener => listener(action, data));
  }
}

export const dataService = new DataService();
