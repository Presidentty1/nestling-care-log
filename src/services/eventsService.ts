import { supabase } from '@/integrations/supabase/client';
import { differenceInMinutes, differenceInSeconds, startOfDay, endOfDay } from 'date-fns';
import type { DailySummary } from '@/types/summary';
import type { EventListener, StoredEvent } from '@/types/common';
import { track } from '@/analytics/analytics';
import { sanitizeEventNote, sanitizeAmount, sanitizeDuration } from '@/lib/sanitization';
import { logger } from '@/lib/logger';
import { dateUtils, validationUtils } from '@/lib/sharedUtils';
import type { DbEvent} from '@/types/db';
import { DbEventType } from '@/types/db';

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

// Alias DbEvent to EventRecord for backward compatibility
export type EventRecord = DbEvent;

class EventsService {
  private listeners: Array<EventListener> = [];
  private readonly MAX_RETRIES = 3;
  private readonly REQUEST_TIMEOUT = 30000; // 30 seconds
  private readonly RATE_LIMIT_DELAY = 1000; // 1 second between requests
  private lastRequestTime = 0;

  subscribe(callback: EventListener) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  private emit(action: 'add' | 'update' | 'delete', data: unknown) {
    this.listeners.forEach(listener => listener(action, data));
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number = this.REQUEST_TIMEOUT): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), timeoutMs);
    });
    return Promise.race([promise, timeoutPromise]);
  }

  private async withRetry<T>(
    operation: () => Promise<T>,
    operationName: string,
    maxRetries: number = this.MAX_RETRIES
  ): Promise<T> {
    let lastError: Error;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Rate limiting
        const now = Date.now();
        const timeSinceLastRequest = now - this.lastRequestTime;
        if (timeSinceLastRequest < this.RATE_LIMIT_DELAY) {
          await new Promise(resolve => setTimeout(resolve, this.RATE_LIMIT_DELAY - timeSinceLastRequest));
        }
        this.lastRequestTime = Date.now();

        const result = await this.withTimeout(operation());

        // If successful, return immediately
        return result;
      } catch (error) {
        lastError = error;

        if (this.isNonRetryableError(error) || attempt === maxRetries) {
          break;
        }

        // Exponential backoff: 1s, 2s, 4s
        const delay = Math.pow(2, attempt - 1) * 1000;
        logger.debug(`Retrying ${operationName} after ${delay}ms`, { attempt }, 'EventsService');
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    throw lastError;
  }

  private isNonRetryableError(error: unknown): boolean {
    // Authentication errors
    if (error?.message?.includes('JWT') || error?.message?.includes('auth') || error?.status === 401) {
      return true;
    }

    // Permission errors
    if (error?.status === 403 || error?.message?.includes('permission')) {
      return true;
    }

    // Validation errors (client-side validation should prevent these)
    if (error?.status === 400 || error?.message?.includes('violates')) {
      return true;
    }

    // Not found errors
    if (error?.status === 404) {
      return true;
    }

    // Rate limiting
    if (error?.status === 429) {
      return true;
    }

    return false;
  }

  private async ensureAuthenticated(): Promise<void> {
    try {
      const { data: { user }, error } = await supabase.auth.getUser();

      if (error) {
        logger.error('Authentication check failed', error, 'EventsService');
        throw new Error('Authentication failed. Please sign in again.');
      }

      if (!user) {
        throw new Error('Not authenticated');
      }
    } catch (error) {
      logger.error('Failed to ensure authentication', error, 'EventsService');
      throw error;
    }
  }

  private validateEventData(data: CreateEventData): void {
    const validation = validationUtils.validateEvent(data);
    if (!validation.isValid) {
      throw new Error(validation.errors[0]); // Throw first error
    }

    // Additional note validation
    if (data.note && typeof data.note !== 'string') {
      throw new Error('Note must be a string');
    }
  }

  async createEvent(data: CreateEventData): Promise<EventRecord> {
    try {
      // Ensure authentication
      await this.ensureAuthenticated();

      // Validate input data
      this.validateEventData(data);

      // Sanitize inputs
      const sanitizedNote = data.note ? sanitizeEventNote(data.note) : undefined;
      const sanitizedAmount = data.amount !== undefined ? sanitizeAmount(data.amount) : undefined;

      if (data.amount !== undefined && sanitizedAmount === null) {
        throw new Error('Invalid amount value after sanitization');
      }

      // Calculate duration if both times provided
      let duration_min = data.duration_min;
      let duration_sec = data.duration_sec;

      if (data.start_time && data.end_time) {
        try {
          const startDate = new Date(data.start_time);
          const endDate = new Date(data.end_time);

          if (!duration_sec) {
            duration_sec = Math.max(0, differenceInSeconds(endDate, startDate));
          }
          if (!duration_min) {
            duration_min = Math.floor((duration_sec || 0) / 60);
          }
        } catch (error) {
          logger.error('Failed to calculate duration', error, 'EventsService');
          throw new Error('Invalid date format for duration calculation');
        }
      }

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Authentication lost during operation');

      const payload = {
        ...data,
        note: sanitizedNote,
        amount: sanitizedAmount !== undefined ? sanitizedAmount : data.amount,
        duration_min,
        duration_sec,
        created_by: user.id,
      };

      const event = await this.withRetry(async () => {
        const { data: event, error } = await supabase
          .from('events')
          .insert(payload)
          .select('*')
          .single();

        if (error) {
          logger.error('Supabase insert error', error, 'EventsService');
          throw error;
        }

        return event;
      }, 'createEvent');

      // Validate returned data
      if (!event || !event.id) {
        throw new Error('Invalid response from server');
      }

      // Track analytics
      try {
        track('event_logged', {
          event_type: data.type,
          subtype: data.subtype,
          amount: data.amount,
          unit: data.unit,
          has_note: !!data.note,
          baby_id: data.baby_id,
          source: 'form'
        });
      } catch (analyticsError) {
        // Don't fail the operation for analytics errors
        logger.warn('Analytics tracking failed', analyticsError, 'EventsService');
      }

      logger.debug('Event created successfully', {
        eventId: event.id,
        type: event.type,
        babyId: event.baby_id
      }, 'EventsService');

      this.emit('add', event);
      return event as EventRecord;
    } catch (error) {
      logger.error('Failed to create event', error, 'EventsService');

      // Re-throw with user-friendly messages
      if (error.message?.includes('duplicate key') || error.code === '23505') {
        throw new Error('This event already exists');
      }

      if (error.message?.includes('violates foreign key') || error.code === '23503') {
        throw new Error('Invalid baby or family reference');
      }

      if (error.message?.includes('network') || error.message?.includes('fetch')) {
        throw new Error('Network error. Please check your connection and try again.');
      }

      if (error.message?.includes('timeout')) {
        throw new Error('Request timed out. Please try again.');
      }

      throw error;
    }
  }

  async updateEvent(id: string, updates: Partial<CreateEventData>): Promise<EventRecord> {
    try {
      if (!id || typeof id !== 'string' || id.trim().length === 0) {
        throw new Error('Valid event ID is required');
      }

      // Ensure authentication
      await this.ensureAuthenticated();

      // Validate ID format (UUID)
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(id)) {
        throw new Error('Invalid event ID format');
      }

      // Check if event exists and user has permission
      const existingEvent = await this.getEvent(id);
      if (!existingEvent) {
        throw new Error('Event not found');
      }

      // Validate update data if provided
      if (Object.keys(updates).length > 0) {
        // Create a merged version for validation
        const mergedData = { ...existingEvent, ...updates };
        delete mergedData.id; // Remove ID for validation
        delete mergedData.created_by; // Remove system fields
        delete mergedData.created_at;
        delete mergedData.updated_at;

        try {
          this.validateEventData(mergedData as CreateEventData);
        } catch (validationError) {
          logger.error('Update validation failed', { updates, validationError }, 'EventsService');
          throw validationError;
        }
      }

      // Recalculate duration if times changed
      let duration_min = updates.duration_min;
      let duration_sec = updates.duration_sec;

      if (updates.start_time || updates.end_time) {
        try {
          const startTime = updates.start_time || existingEvent.start_time;
          const endTime = updates.end_time || existingEvent.end_time;

          if (startTime && endTime) {
            const startDate = new Date(startTime);
            const endDate = new Date(endTime);

            if (endDate < startDate) {
              throw new Error('End time cannot be before start time');
            }

            duration_sec = Math.max(0, differenceInSeconds(endDate, startDate));
            duration_min = Math.floor((duration_sec || 0) / 60);
          }
        } catch (error) {
          logger.error('Failed to recalculate duration', error, 'EventsService');
          throw new Error('Invalid date format for duration calculation');
        }
      }

      // Sanitize inputs
      const sanitizedUpdates = { ...updates };
      if (updates.note !== undefined) {
        sanitizedUpdates.note = updates.note ? sanitizeEventNote(updates.note) : undefined;
      }

      if (updates.amount !== undefined) {
        const sanitizedAmount = sanitizeAmount(updates.amount);
        if (sanitizedAmount === null) {
          throw new Error('Invalid amount value after sanitization');
        }
        sanitizedUpdates.amount = sanitizedAmount;
      }

      const updatePayload = {
        ...sanitizedUpdates,
        duration_min,
        duration_sec,
        updated_at: new Date().toISOString()
      };

      const event = await this.withRetry(async () => {
        const { data: event, error } = await supabase
          .from('events')
          .update(updatePayload)
          .eq('id', id)
          .select('*')
          .single();

        if (error) {
          // Handle concurrent modification
          if (error.code === 'PGRST116' || error.message?.includes('conflict')) {
            throw new Error('Event was modified by another user. Please refresh and try again.');
          }

          logger.error('Supabase update error', error, 'EventsService');
          throw error;
        }

        return event;
      }, 'updateEvent');

      // Validate returned data
      if (!event || !event.id) {
        throw new Error('Invalid response from server');
      }

      // Track analytics
      try {
        const changedFields = Object.keys(updates);
        track('event_edited', {
          event_type: event.type,
          event_id: id,
          changes: changedFields
        });
      } catch (analyticsError) {
        // Don't fail the operation for analytics errors
        logger.warn('Analytics tracking failed', analyticsError, 'EventsService');
      }

      logger.debug('Event updated successfully', {
        eventId: id,
        type: event.type,
        changes: Object.keys(updates)
      }, 'EventsService');

      this.emit('update', event);
      return event as EventRecord;
    } catch (error) {
      logger.error('Failed to update event', { eventId: id, error }, 'EventsService');

      // Re-throw with user-friendly messages
      if (error.message?.includes('violates foreign key') || error.code === '23503') {
        throw new Error('Invalid baby or family reference');
      }

      if (error.message?.includes('network') || error.message?.includes('fetch')) {
        throw new Error('Network error. Please check your connection and try again.');
      }

      if (error.message?.includes('timeout')) {
        throw new Error('Request timed out. Please try again.');
      }

      throw error;
    }
  }

  async deleteEvent(id: string): Promise<void> {
    try {
      if (!id || typeof id !== 'string' || id.trim().length === 0) {
        throw new Error('Valid event ID is required');
      }

      // Validate ID format (UUID)
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(id)) {
        throw new Error('Invalid event ID format');
      }

      // Ensure authentication
      await this.ensureAuthenticated();

      // Fetch event before deleting for analytics and validation
      const existingEvent = await this.getEvent(id);
      if (!existingEvent) {
        // Idempotent - don't throw error for non-existent events
        logger.debug('Attempted to delete non-existent event', { eventId: id }, 'EventsService');
        return;
      }

      await this.withRetry(async () => {
        const { error } = await supabase
          .from('events')
          .delete()
          .eq('id', id);

        if (error) {
          logger.error('Supabase delete error', error, 'EventsService');
          throw error;
        }
      }, 'deleteEvent');

      // Track analytics
      try {
        track('event_deleted', {
          event_type: existingEvent.type,
          event_id: id
        });
      } catch (analyticsError) {
        // Don't fail the operation for analytics errors
        logger.warn('Analytics tracking failed', analyticsError, 'EventsService');
      }

      logger.debug('Event deleted successfully', {
        eventId: id,
        type: existingEvent.type
      }, 'EventsService');

      this.emit('delete', { id });
    } catch (error) {
      logger.error('Failed to delete event', { eventId: id, error }, 'EventsService');

      if (error.message?.includes('network') || error.message?.includes('fetch')) {
        throw new Error('Network error. Please check your connection and try again.');
      }

      if (error.message?.includes('timeout')) {
        throw new Error('Request timed out. Please try again.');
      }

      throw error;
    }
  }

  async getEvent(id: string): Promise<EventRecord | null> {
    try {
      if (!id || typeof id !== 'string' || id.trim().length === 0) {
        logger.warn('Invalid event ID provided', { id }, 'EventsService');
        return null;
      }

      const event = await this.withRetry(async () => {
        const { data, error } = await supabase
          .from('events')
          .select('*')
          .eq('id', id)
          .single();

        if (error) {
          if (error.code === 'PGRST116') {
            // Not found
            return null;
          }
          logger.error('Supabase getEvent error', error, 'EventsService');
          throw error;
        }

        return data;
      }, 'getEvent');

      if (!event) {
        return null;
      }

      // Validate returned data
      if (!this.isValidEventRecord(event)) {
        logger.warn('Invalid event record received', { id, event }, 'EventsService');
        return null;
      }

      logger.debug('Event retrieved successfully', { eventId: id }, 'EventsService');
      return event as EventRecord;
    } catch (error) {
      logger.error('Failed to get event', { eventId: id, error }, 'EventsService');

      // For read operations, don't throw errors - return null instead
      if (error.message?.includes('network') || error.message?.includes('timeout')) {
        logger.warn('Network error during getEvent, returning null', { eventId: id }, 'EventsService');
        return null;
      }

      throw error;
    }
  }

  private isValidEventRecord(event: unknown): boolean {
    return (
      event &&
      typeof event === 'object' &&
      typeof event.id === 'string' &&
      typeof event.baby_id === 'string' &&
      typeof event.family_id === 'string' &&
      typeof event.type === 'string' &&
      ['feed', 'sleep', 'diaper', 'tummy_time'].includes(event.type) &&
      typeof event.start_time === 'string' &&
      !isNaN(Date.parse(event.start_time))
      // created_by check removed as it might be optional/null in DbEvent
    );
  }

  async getTodayEvents(babyId: string): Promise<EventRecord[]> {
    const now = new Date();
    return this.getEventsByDate(babyId, now);
  }

  async getEventsByDate(babyId: string, date: Date): Promise<EventRecord[]> {
    try {
      if (!babyId || typeof babyId !== 'string' || babyId.trim().length === 0) {
        throw new Error('Valid baby ID is required');
      }

      if (!date || isNaN(date.getTime())) {
        throw new Error('Valid date is required');
      }

      // Validate date range (prevent querying too far in the past/future)
      const now = new Date();
      const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
      const oneMonthFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

      if (date < oneYearAgo) {
        throw new Error('Cannot query events older than one year');
      }

      if (date > oneMonthFromNow) {
        throw new Error('Cannot query events more than one month in the future');
      }

      const start = startOfDay(date).toISOString();
      const end = endOfDay(date).toISOString();

      const events = await this.withRetry(async () => {
        const { data, error } = await supabase
          .from('events')
          .select('*')
          .eq('baby_id', babyId)
          .gte('start_time', start)
          .lte('start_time', end)
          .order('end_time', { ascending: false, nullsFirst: false })
          .order('start_time', { ascending: false });

        if (error) {
          logger.error('Supabase getEventsByDate error', error, 'EventsService');
          throw error;
        }

        return data || [];
      }, 'getEventsByDate');

      // Validate and filter results
      const validEvents = events.filter(event => this.isValidEventRecord(event));

      if (validEvents.length !== events.length) {
        logger.warn('Filtered out invalid events', {
          babyId,
          date: date.toISOString(),
          totalEvents: events.length,
          validEvents: validEvents.length
        }, 'EventsService');
      }

      logger.debug('Events retrieved successfully', {
        babyId,
        date: date.toISOString(),
        eventCount: validEvents.length
      }, 'EventsService');

      return validEvents as EventRecord[];
    } catch (error) {
      logger.error('Failed to get events by date', { babyId, date, error }, 'EventsService');

      // For read operations, return empty array instead of throwing
      if (error.message?.includes('network') || error.message?.includes('timeout')) {
        logger.warn('Network error during getEventsByDate, returning empty array', { babyId, date }, 'EventsService');
        return [];
      }

      throw error;
    }
  }

  async getEventsByRange(babyId: string, fromISO: string, toISO: string): Promise<EventRecord[]> {
    try {
      if (!babyId || typeof babyId !== 'string' || babyId.trim().length === 0) {
        throw new Error('Valid baby ID is required');
      }

      if (!fromISO || !toISO || typeof fromISO !== 'string' || typeof toISO !== 'string') {
        throw new Error('Valid date range is required');
      }

      const fromDate = new Date(fromISO);
      const toDate = new Date(toISO);

      if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        throw new Error('Invalid date format');
      }

      if (fromDate > toDate) {
        throw new Error('From date cannot be after to date');
      }

      // Validate date range limits (prevent excessive queries)
      const rangeMs = toDate.getTime() - fromDate.getTime();
      const maxRangeMs = 90 * 24 * 60 * 60 * 1000; // 90 days max

      if (rangeMs > maxRangeMs) {
        throw new Error('Date range cannot exceed 90 days');
      }

      // Prevent queries too far in the past
      const oneYearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
      if (fromDate < oneYearAgo) {
        throw new Error('Cannot query events older than one year');
      }

      const events = await this.withRetry(async () => {
        const { data, error } = await supabase
          .from('events')
          .select('*')
          .eq('baby_id', babyId)
          .gte('start_time', fromISO)
          .lte('start_time', toISO)
          .order('end_time', { ascending: false, nullsFirst: false })
          .order('start_time', { ascending: false });

        if (error) {
          logger.error('Supabase getEventsByRange error', error, 'EventsService');
          throw error;
        }

        return data || [];
      }, 'getEventsByRange');

      // Validate and filter results
      const validEvents = events.filter(event => this.isValidEventRecord(event));

      if (validEvents.length !== events.length) {
        logger.warn('Filtered out invalid events', {
          babyId,
          fromISO,
          toISO,
          totalEvents: events.length,
          validEvents: validEvents.length
        }, 'EventsService');
      }

      logger.debug('Events retrieved successfully', {
        babyId,
        fromISO,
        toISO,
        eventCount: validEvents.length
      }, 'EventsService');

      return validEvents as EventRecord[];
    } catch (error) {
      logger.error('Failed to get events by range', { babyId, fromISO, toISO, error }, 'EventsService');

      // For read operations, return empty array instead of throwing
      if (error.message?.includes('network') || error.message?.includes('timeout')) {
        logger.warn('Network error during getEventsByRange, returning empty array', { babyId, fromISO, toISO }, 'EventsService');
        return [];
      }

      throw error;
    }
  }

  async getLastEventByType(babyId: string, type: string): Promise<EventRecord | null> {
    try {
      if (!babyId || typeof babyId !== 'string' || babyId.trim().length === 0) {
        logger.warn('Invalid baby ID provided', { babyId }, 'EventsService');
        return null;
      }

      if (!type || !['feed', 'sleep', 'diaper', 'tummy_time'].includes(type)) {
        logger.warn('Invalid event type provided', { type }, 'EventsService');
        return null;
      }

      const event = await this.withRetry(async () => {
        const { data, error } = await supabase
          .from('events')
          .select('*')
          .eq('baby_id', babyId)
          .eq('type', type)
          .order('end_time', { ascending: false, nullsFirst: false })
          .order('start_time', { ascending: false })
          .limit(1)
          .single();

        if (error) {
          if (error.code === 'PGRST116') {
            // No results found
            return null;
          }
          logger.error('Supabase getLastEventByType error', error, 'EventsService');
          throw error;
        }

        return data;
      }, 'getLastEventByType');

      if (!event) {
        return null;
      }

      // Validate returned data
      if (!this.isValidEventRecord(event)) {
        logger.warn('Invalid event record received', { babyId, type, event }, 'EventsService');
        return null;
      }

      logger.debug('Last event retrieved successfully', {
        babyId,
        type,
        eventId: event.id
      }, 'EventsService');

      return event as EventRecord;
    } catch (error) {
      logger.error('Failed to get last event by type', { babyId, type, error }, 'EventsService');

      // For read operations, return null instead of throwing
      if (error.message?.includes('network') || error.message?.includes('timeout')) {
        logger.warn('Network error during getLastEventByType, returning null', { babyId, type }, 'EventsService');
        return null;
      }

      throw error;
    }
  }

  // Calculate daily summary with validation
  calculateSummary(events: EventRecord[]): DailySummary {
    try {
      if (!Array.isArray(events)) {
        logger.warn('Invalid events array provided to calculateSummary', { events }, 'EventsService');
        return {
          feedCount: 0,
          totalMl: 0,
          sleepMinutes: 0,
          sleepCount: 0,
          diaperWet: 0,
          diaperDirty: 0,
          diaperTotal: 0,
        };
      }

      // Validate and filter events
      const validEvents = events.filter(event => {
        if (!this.isValidEventRecord(event)) {
          logger.warn('Invalid event in summary calculation', { event }, 'EventsService');
          return false;
        }
        return true;
      });

      const feeds = validEvents.filter(e => e.type === 'feed');
      const sleeps = validEvents.filter(e => e.type === 'sleep' && e.end_time); // Only completed sleeps
      const diapers = validEvents.filter(e => e.type === 'diaper');

      // Safely calculate totals with validation
      const totalFeedAmount = feeds.reduce((sum, e) => {
        const amount = typeof e.amount === 'number' && e.amount >= 0 ? e.amount : 0;
        return sum + amount;
      }, 0);

      const totalSleepMin = sleeps.reduce((sum, e) => {
        const duration = typeof e.duration_min === 'number' && e.duration_min >= 0 ? e.duration_min : 0;
        return sum + duration;
      }, 0);

      const wetCount = diapers.filter(d =>
        d.subtype === 'wet' || d.subtype === 'both'
      ).length;

      const dirtyCount = diapers.filter(d =>
        d.subtype === 'dirty' || d.subtype === 'both'
      ).length;

      const summary = {
        feedCount: feeds.length,
        totalMl: Math.round(totalFeedAmount * 100) / 100, // Round to 2 decimal places
        sleepMinutes: Math.round(totalSleepMin),
        sleepCount: sleeps.length,
        diaperWet: wetCount,
        diaperDirty: dirtyCount,
        diaperTotal: diapers.length,
      };

      // Validate summary totals are reasonable
      if (summary.totalMl > 10000) { // More than 10L seems unreasonable
        logger.warn('Unusually high feed total detected', { summary }, 'EventsService');
      }

      if (summary.sleepMinutes > 1440) { // More than 24 hours
        logger.warn('Unusually high sleep total detected', { summary }, 'EventsService');
      }

      logger.debug('Summary calculated successfully', {
        eventCount: validEvents.length,
        feedCount: summary.feedCount,
        sleepMinutes: summary.sleepMinutes
      }, 'EventsService');

      return summary;
    } catch (error) {
      logger.error('Failed to calculate summary', error, 'EventsService');

      // Return safe defaults on error
      return {
        feedCount: 0,
        totalMl: 0,
        sleepMinutes: 0,
        sleepCount: 0,
        diaperWet: 0,
        diaperDirty: 0,
        diaperTotal: 0,
      };
    }
  }
}

export const eventsService = new EventsService();
