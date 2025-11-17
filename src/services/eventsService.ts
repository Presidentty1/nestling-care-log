import { supabase } from '@/integrations/supabase/client';
import { differenceInMinutes, differenceInSeconds, startOfDay, endOfDay } from 'date-fns';

export interface CreateEventData {
  baby_id: string;
  family_id: string;
  type: 'feed' | 'sleep' | 'diaper' | 'tummy_time';
  subtype?: string;
  side?: 'left' | 'right' | 'both';
  amount?: number; // Always in ml
  unit?: 'ml' | 'oz';
  start_time: string; // UTC ISO
  end_time?: string; // UTC ISO
  duration_min?: number;
  duration_sec?: number;
  diaper_color?: string;
  diaper_texture?: string;
  note?: string;
}

export interface EventRecord extends CreateEventData {
  id: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

class EventsService {
  private listeners: Array<(action: 'add' | 'update' | 'delete', data: any) => void> = [];

  subscribe(callback: (action: 'add' | 'update' | 'delete', data: any) => void) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  private emit(action: 'add' | 'update' | 'delete', data: any) {
    this.listeners.forEach(listener => listener(action, data));
  }

  async createEvent(data: CreateEventData): Promise<EventRecord> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Calculate duration if both times provided
    let duration_min = data.duration_min;
    let duration_sec = data.duration_sec;
    
    if (data.start_time && data.end_time) {
      if (!duration_sec) {
        duration_sec = differenceInSeconds(
          new Date(data.end_time),
          new Date(data.start_time)
        );
      }
      if (!duration_min) {
        duration_min = Math.floor(duration_sec / 60);
      }
    }

    const payload = {
      ...data,
      duration_min,
      duration_sec,
      created_by: user.id,
    };

    const { data: event, error } = await supabase
      .from('events')
      .insert(payload)
      .select('*')
      .single();

    if (error) throw error;

    this.emit('add', event);
    return event as EventRecord;
  }

  async updateEvent(id: string, updates: Partial<CreateEventData>): Promise<EventRecord> {
    // Recalculate duration if times changed
    let duration_min = updates.duration_min;
    let duration_sec = updates.duration_sec;
    
    if (updates.start_time || updates.end_time) {
      const { data: existing } = await supabase
        .from('events')
        .select('start_time, end_time')
        .eq('id', id)
        .single();

      const startTime = updates.start_time || existing?.start_time;
      const endTime = updates.end_time || existing?.end_time;

      if (startTime && endTime) {
        duration_sec = differenceInSeconds(new Date(endTime), new Date(startTime));
        duration_min = Math.floor(duration_sec / 60);
      }
    }

    const { data: event, error } = await supabase
      .from('events')
      .update({ ...updates, duration_min, duration_sec })
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;

    this.emit('update', event);
    return event as EventRecord;
  }

  async deleteEvent(id: string): Promise<void> {
    const { error } = await supabase
      .from('events')
      .delete()
      .eq('id', id);

    if (error) throw error;

    this.emit('delete', { id });
  }

  async getEvent(id: string): Promise<EventRecord | null> {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('id', id)
      .single();

    if (error) return null;
    return data as EventRecord;
  }

  async getTodayEvents(babyId: string): Promise<EventRecord[]> {
    const now = new Date();
    const start = startOfDay(now).toISOString();
    const end = endOfDay(now).toISOString();

    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', start)
      .lte('start_time', end)
      .order('start_time', { ascending: false });

    if (error) throw error;
    return (data || []) as EventRecord[];
  }

  async getEventsByDate(babyId: string, date: Date): Promise<EventRecord[]> {
    const start = startOfDay(date).toISOString();
    const end = endOfDay(date).toISOString();

    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', start)
      .lte('start_time', end)
      .order('start_time', { ascending: false });

    if (error) throw error;
    return (data || []) as EventRecord[];
  }

  async getEventsByRange(babyId: string, fromISO: string, toISO: string): Promise<EventRecord[]> {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', fromISO)
      .lte('start_time', toISO)
      .order('start_time', { ascending: false });

    if (error) throw error;
    return (data || []) as EventRecord[];
  }

  async getLastEventByType(babyId: string, type: string): Promise<EventRecord | null> {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .eq('type', type)
      .order('start_time', { ascending: false })
      .limit(1)
      .single();

    if (error) return null;
    return data as EventRecord;
  }

  // Calculate daily summary
  calculateSummary(events: EventRecord[]) {
    const feeds = events.filter(e => e.type === 'feed');
    const sleeps = events.filter(e => e.type === 'sleep');
    const diapers = events.filter(e => e.type === 'diaper');

    const totalFeedAmount = feeds.reduce((sum, e) => sum + (e.amount || 0), 0);
    const totalSleepMin = sleeps.reduce((sum, e) => sum + (e.duration_min || 0), 0);

    const wetCount = diapers.filter(d => d.subtype === 'wet' || d.subtype === 'both').length;
    const dirtyCount = diapers.filter(d => d.subtype === 'dirty' || d.subtype === 'both').length;

    return {
      feeds: {
        count: feeds.length,
        totalMl: totalFeedAmount,
      },
      sleep: {
        count: sleeps.length,
        totalMinutes: totalSleepMin,
      },
      diapers: {
        count: diapers.length,
        wet: wetCount,
        dirty: dirtyCount,
      },
    };
  }
}

export const eventsService = new EventsService();
