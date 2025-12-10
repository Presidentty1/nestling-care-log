import localforage from 'localforage';
import type {
  EventRecord,
  TimerState,
  Baby,
  NapFeedback,
  NotificationSettings,
} from '@/types/events';
import type {
  DataListener,
  NapPrediction,
  StorageEstimate,
  TimerData,
  StoredEvent,
  StoredBaby,
} from '@/types/common';
import { differenceInMinutes } from 'date-fns';
import { logger } from '@/lib/logger';
import { dateUtils, validationUtils } from '@/lib/sharedUtils';
import { TIME, STORAGE, LIMITS, UI } from '@/lib/constants';

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
  private listeners: Array<DataListener> = [];
  private readonly MAX_STORAGE_SIZE = STORAGE.MAX_SIZE_BYTES;
  private readonly MAX_EVENTS_PER_DAY = STORAGE.MAX_EVENTS_PER_DAY;
  private readonly DATA_VALIDITY_CHECK_INTERVAL = TIME.DAY;
  private isOnline: boolean = navigator.onLine;
  private connectionCheckInterval?: NodeJS.Timeout;

  constructor() {
    this.initializeErrorRecovery();
    this.scheduleDataMaintenance();
    this.setupConnectionMonitoring();
  }

  private async initializeErrorRecovery() {
    try {
      // Test storage availability
      await this.checkStorageAvailability();

      // Validate existing data integrity
      await this.validateDataIntegrity();

      logger.info('Data service initialized successfully', {}, 'DataService');
    } catch (error) {
      logger.error('Failed to initialize data service', error, 'DataService');
      // Continue with degraded functionality
    }
  }

  private async checkStorageAvailability(): Promise<void> {
    try {
      // Test basic storage operations
      const testKey = '__storage_test__';
      const testData = { test: true, timestamp: Date.now() };

      await eventsStore.setItem(testKey, testData);
      const retrieved = await eventsStore.getItem(testKey);

      if (!retrieved) {
        throw new Error('Storage read/write test failed');
      }

      await eventsStore.removeItem(testKey);

      // Check storage quota
      if ('storage' in navigator && 'estimate' in navigator.storage) {
        const estimate = await navigator.storage.estimate();
        if (estimate.quota && estimate.usage && estimate.usage > estimate.quota * 0.9) {
          // 90% threshold
          logger.warn(
            'Storage usage is above 90% of quota',
            {
              usage: estimate.usage,
              quota: estimate.quota,
              percentage: ((estimate.usage / estimate.quota) * 100).toFixed(1),
            },
            'DataService'
          );
        }
      }
    } catch (error) {
      logger.error('Storage availability check failed', error, 'DataService');
      throw new Error('Local storage is not available or full');
    }
  }

  private async validateDataIntegrity(): Promise<void> {
    try {
      const corruptedItems: string[] = [];

      // Check events store
      await eventsStore.iterate((value: unknown, key: string) => {
        if (!this.isValidEventRecord(value)) {
          corruptedItems.push(`events:${key}`);
        }
      });

      // Check babies store
      await babiesStore.iterate((value: unknown, key: string) => {
        if (!this.isValidBabyRecord(value)) {
          corruptedItems.push(`babies:${key}`);
        }
      });

      if (corruptedItems.length > 0) {
        logger.warn('Found corrupted data items', { corruptedItems }, 'DataService');

        // Attempt to clean up corrupted items
        for (const item of corruptedItems) {
          const [store, key] = item.split(':');
          try {
            switch (store) {
              case 'events':
                await eventsStore.removeItem(key);
                break;
              case 'babies':
                await babiesStore.removeItem(key);
                break;
            }
            logger.info('Cleaned up corrupted data item', { item }, 'DataService');
          } catch (error) {
            logger.error('Failed to clean up corrupted item', { item, error }, 'DataService');
          }
        }
      }
    } catch (error) {
      logger.error('Data integrity validation failed', error, 'DataService');
      // Don't throw - continue with potentially corrupted data
    }
  }

  private isValidEventRecord(data: unknown): boolean {
    return (
      data &&
      typeof data === 'object' &&
      typeof data.id === 'string' &&
      typeof data.babyId === 'string' &&
      typeof data.type === 'string' &&
      ['feed', 'sleep', 'diaper', 'tummy_time'].includes(data.type) &&
      typeof data.startTime === 'string' &&
      !isNaN(Date.parse(data.startTime))
    );
  }

  private isValidBabyRecord(data: unknown): boolean {
    return (
      data &&
      typeof data === 'object' &&
      typeof data.id === 'string' &&
      typeof data.name === 'string' &&
      data.name.trim().length > 0 &&
      typeof data.dateOfBirth === 'string' &&
      !isNaN(Date.parse(data.dateOfBirth))
    );
  }

  private setupConnectionMonitoring() {
    // Monitor online/offline status
    window.addEventListener('online', () => {
      this.isOnline = true;
      logger.info('Connection restored', {}, 'DataService');
      this.emitChange('connection_restored', {});
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
      logger.warn('Connection lost', {}, 'DataService');
      this.emitChange('connection_lost', {});
    });

    // Periodic connection health check
    this.connectionCheckInterval = setInterval(() => {
      this.checkConnectionHealth();
    }, UI.REQUEST_TIMEOUT_MS / 2); // Check every 15 seconds
  }

  private async checkConnectionHealth(): Promise<void> {
    if (!this.isOnline) return;

    try {
      // Simple connectivity check - try to access a small piece of localStorage
      const testKey = '__connectivity_test__';
      await eventsStore.setItem(testKey, { timestamp: Date.now() });
      await eventsStore.removeItem(testKey);
    } catch (error) {
      logger.warn('Connectivity check failed', error, 'DataService');
      this.isOnline = false;
      this.emitChange('connection_lost', {});
    }
  }

  private scheduleDataMaintenance() {
    // Schedule periodic data maintenance
    setInterval(async () => {
      try {
        await this.performDataMaintenance();
      } catch (error) {
        logger.error('Data maintenance failed', error, 'DataService');
      }
    }, this.DATA_VALIDITY_CHECK_INTERVAL);
  }

  private async performDataMaintenance(): Promise<void> {
    logger.info('Performing data maintenance', {}, 'DataService');

    // Clean up old temporary data
    await this.cleanupExpiredTimers();

    // Validate data integrity
    await this.validateDataIntegrity();

    // Optimize storage if needed
    await this.optimizeStorage();
  }

  private async cleanupExpiredTimers(): Promise<void> {
    const now = Date.now();
    const expiredTimerIds: string[] = [];

    await timersStore.iterate((timer: TimerData, key: string) => {
      // Remove timers older than 24 hours
      if (timer.timestamp && now - timer.timestamp > TIME.DAY) {
        expiredTimerIds.push(key);
      }
    });

    for (const timerId of expiredTimerIds) {
      await timersStore.removeItem(timerId);
      logger.debug('Cleaned up expired timer', { timerId }, 'DataService');
    }
  }

  private async optimizeStorage(): Promise<void> {
    // Placeholder for storage optimization logic
    // Could implement data compression, deduplication, etc.
  }

  async addEvent(
    event: Omit<EventRecord, 'id' | 'createdAt' | 'updatedAt' | 'source'>
  ): Promise<EventRecord> {
    try {
      // Check connection status
      if (!this.isOnline) {
        throw new Error('Cannot add events while offline. Event will be queued for sync.');
      }

      // Validate input data
      this.validateEventInput(event);

      // Check for reasonable limits
      await this.checkEventLimits(event.babyId, new Date(event.startTime));

      const now = dateUtils.nowISO();
      const record: EventRecord = {
        ...event,
        id: crypto.randomUUID(),
        createdAt: now,
        updatedAt: now,
        source: 'local',
      };

      // Calculate duration with validation
      if (record.startTime && record.endTime) {
        const startDate = new Date(record.startTime);
        const endDate = new Date(record.endTime);

        if (endDate < startDate) {
          throw new Error('End time cannot be before start time');
        }

        if (endDate.getTime() - startDate.getTime() > TIME.DAY) {
          throw new Error(`Event duration cannot exceed ${LIMITS.MAX_EVENT_DURATION_HOURS} hours`);
        }

        record.durationMin = differenceInMinutes(endDate, startDate);
      }

      // Check storage availability before saving
      await this.checkStorageAvailability();

      // Add timeout protection for storage operation
      await this.withTimeout(async () => {
        await eventsStore.setItem(record.id, record);
      }, UI.STORAGE_TIMEOUT_MS);

      this.emitChange('add', record);

      logger.debug(
        'Event added successfully',
        { eventId: record.id, type: record.type },
        'DataService'
      );

      return record;
    } catch (error) {
      logger.error('Failed to add event', error, 'DataService');

      // Handle different error types
      if (
        error.message?.includes('offline') ||
        error.message?.includes('Cannot add events while offline')
      ) {
        throw error; // Re-throw offline errors as-is
      }

      if (error.message?.includes('timeout')) {
        throw new Error('Operation timed out. Please try again.');
      }

      // Attempt recovery for storage quota issues
      if (error.message?.includes('QuotaExceededError') || error.name === 'QuotaExceededError') {
        await this.attemptStorageRecovery();
        // Retry once after cleanup
        try {
          return await this.addEvent(event);
        } catch (retryError) {
          logger.error('Retry after storage recovery failed', retryError, 'DataService');
          throw new Error('Storage is full. Please free up space and try again.');
        }
      }

      throw error;
    }
  }

  private async withTimeout<T>(operation: () => Promise<T>, timeoutMs: number): Promise<T> {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        reject(new Error('Operation timed out'));
      }, timeoutMs);

      operation()
        .then(resolve)
        .catch(reject)
        .finally(() => clearTimeout(timeoutId));
    });
  }

  private validateEventInput(
    event: Omit<EventRecord, 'id' | 'createdAt' | 'updatedAt' | 'source'>
  ): void {
    if (!event.babyId || typeof event.babyId !== 'string') {
      throw new Error('Valid baby ID is required');
    }

    if (!event.type || !['feed', 'sleep', 'diaper', 'tummy_time'].includes(event.type)) {
      throw new Error('Valid event type is required');
    }

    if (!event.startTime || isNaN(Date.parse(event.startTime))) {
      throw new Error('Valid start time is required');
    }

    // Validate future dates (allow small clock drift)
    if (dateUtils.isInFuture(event.startTime, 5)) {
      throw new Error('Event time cannot be in the future');
    }

    // Validate amount for feeds
    if (event.type === 'feed' && event.amount !== undefined) {
      if (
        typeof event.amount !== 'number' ||
        event.amount <= 0 ||
        event.amount > LIMITS.MAX_FEED_AMOUNT_ML
      ) {
        throw new Error(`Feed amount must be between 0 and ${LIMITS.MAX_FEED_AMOUNT_ML}`);
      }
    }

    // Validate duration for sleep/tummy_time
    if (
      (event.type === 'sleep' || event.type === 'tummy_time') &&
      event.durationMin !== undefined
    ) {
      if (
        typeof event.durationMin !== 'number' ||
        event.durationMin < 0 ||
        event.durationMin > LIMITS.MAX_EVENT_DURATION_MINUTES
      ) {
        throw new Error(
          `Duration must be between 0 and ${LIMITS.MAX_EVENT_DURATION_MINUTES} minutes`
        );
      }
    }
  }

  private async checkEventLimits(babyId: string, date: Date): Promise<void> {
    const dayStart = new Date(date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    let eventCount = 0;
    await eventsStore.iterate((event: EventRecord) => {
      if (event.babyId === babyId) {
        const eventTime = new Date(event.startTime);
        if (eventTime >= dayStart && eventTime <= dayEnd) {
          eventCount++;
        }
      }
    });

    if (eventCount >= this.MAX_EVENTS_PER_DAY) {
      throw new Error(`Cannot add more than ${this.MAX_EVENTS_PER_DAY} events per day`);
    }
  }

  private async attemptStorageRecovery(): Promise<void> {
    logger.info('Attempting storage recovery', {}, 'DataService');

    try {
      // Clean up old timers
      await this.cleanupExpiredTimers();

      // Remove old cached data if available
      // This could be extended to remove old events beyond a retention period

      logger.info('Storage recovery completed', {}, 'DataService');
    } catch (error) {
      logger.error('Storage recovery failed', error, 'DataService');
    }
  }

  async updateEvent(id: string, updates: Partial<EventRecord>): Promise<EventRecord> {
    try {
      const existing = await eventsStore.getItem<EventRecord>(id);
      if (!existing) {
        throw new Error('Event not found');
      }

      // Validate that the event belongs to the current user/family
      // This would be more comprehensive in a full implementation

      const updated: EventRecord = {
        ...existing,
        ...updates,
        updatedAt: new Date().toISOString(),
      };

      // Re-validate the complete updated event
      this.validateEventInput(updated);

      // Recalculate duration with validation
      if (updated.startTime && updated.endTime) {
        const startDate = new Date(updated.startTime);
        const endDate = new Date(updated.endTime);

        if (endDate < startDate) {
          throw new Error('End time cannot be before start time');
        }

        if (endDate.getTime() - startDate.getTime() > TIME.DAY) {
          throw new Error(`Event duration cannot exceed ${LIMITS.MAX_EVENT_DURATION_HOURS} hours`);
        }

        updated.durationMin = differenceInMinutes(endDate, startDate);
      }

      await eventsStore.setItem(id, updated);
      this.emitChange('update', updated);

      logger.debug(
        'Event updated successfully',
        { eventId: id, type: updated.type },
        'DataService'
      );

      return updated;
    } catch (error) {
      logger.error('Failed to update event', { eventId: id, error }, 'DataService');

      // Handle storage issues
      if (error.message?.includes('QuotaExceededError') || error.name === 'QuotaExceededError') {
        throw new Error('Storage is full. Cannot update event.');
      }

      throw error;
    }
  }

  async deleteEvent(id: string): Promise<void> {
    try {
      const existing = await eventsStore.getItem<EventRecord>(id);
      if (!existing) {
        logger.warn('Attempted to delete non-existent event', { eventId: id }, 'DataService');
        return; // Silently succeed for idempotent operations
      }

      await eventsStore.removeItem(id);
      this.emitChange('delete', { id });

      logger.debug(
        'Event deleted successfully',
        { eventId: id, type: existing.type },
        'DataService'
      );
    } catch (error) {
      logger.error('Failed to delete event', { eventId: id, error }, 'DataService');
      throw error;
    }
  }

  async getEvent(id: string): Promise<EventRecord | null> {
    return await eventsStore.getItem<EventRecord>(id);
  }

  async listEventsByDay(babyId: string, dayISO: string): Promise<EventRecord[]> {
    try {
      if (!babyId || typeof babyId !== 'string') {
        throw new Error('Valid baby ID is required');
      }

      if (!dayISO || isNaN(Date.parse(dayISO))) {
        throw new Error('Valid date ISO string is required');
      }

      const events: EventRecord[] = [];
      const dayStart = new Date(dayISO);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(dayISO);
      dayEnd.setHours(23, 59, 59, 999);

      // Validate date range (prevent querying too far in the past/future)
      const now = new Date();
      const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
      const oneMonthFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

      if (dayStart < oneYearAgo) {
        throw new Error('Cannot query events older than one year');
      }

      if (dayStart > oneMonthFromNow) {
        throw new Error('Cannot query events more than one month in the future');
      }

      await eventsStore.iterate<EventRecord, void>((event, key) => {
        try {
          // Validate event data during iteration
          if (!this.isValidEventRecord(event)) {
            logger.warn('Skipping invalid event during iteration', { key, event }, 'DataService');
            return;
          }

          if (event.babyId === babyId) {
            const eventTime = new Date(event.startTime);

            // Additional validation for date parsing
            if (isNaN(eventTime.getTime())) {
              logger.warn(
                'Skipping event with invalid date',
                { key, startTime: event.startTime },
                'DataService'
              );
              return;
            }

            if (eventTime >= dayStart && eventTime <= dayEnd) {
              events.push(event);
            }
          }
        } catch (error) {
          logger.error('Error processing event during iteration', { key, error }, 'DataService');
          // Continue processing other events
        }
      });

      // Sort events by start time (descending - most recent first), handling any remaining invalid dates
      const validEvents = events
        .filter(event => {
          const time = new Date(event.startTime).getTime();
          return !isNaN(time);
        })
        .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());

      logger.debug(
        'Events listed successfully',
        {
          babyId,
          dayISO,
          eventCount: validEvents.length,
        },
        'DataService'
      );

      return validEvents;
    } catch (error) {
      logger.error('Failed to list events by day', { babyId, dayISO, error }, 'DataService');
      throw error;
    }
  }

  async listEventsRange(babyId: string, fromISO: string, toISO: string): Promise<EventRecord[]> {
    const events: EventRecord[] = [];
    const start = new Date(fromISO);
    const end = new Date(toISO);

    await eventsStore.iterate<EventRecord, void>(event => {
      if (event.babyId === babyId) {
        const eventTime = new Date(event.startTime);
        if (eventTime >= start && eventTime <= end) {
          events.push(event);
        }
      }
    });

    return events.sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());
  }

  async getLastEventByType(babyId: string, type: string): Promise<EventRecord | null> {
    let lastEvent: EventRecord | null = null;
    let latestTime = 0;

    await eventsStore.iterate<EventRecord, void>(event => {
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
    try {
      if (!babyId || typeof babyId !== 'string') {
        throw new Error('Valid baby ID is required');
      }

      const timerState = await timersStore.getItem<TimerState>(`timer_${babyId}`);

      // Validate timer state if it exists
      if (timerState && !this.isValidTimerState(timerState)) {
        logger.warn('Invalid timer state found, clearing', { babyId }, 'DataService');
        await this.clearTimerState(babyId);
        return null;
      }

      return timerState;
    } catch (error) {
      logger.error('Failed to get timer state', { babyId, error }, 'DataService');
      throw error;
    }
  }

  async setTimerState(babyId: string, timerState: TimerState): Promise<void> {
    try {
      if (!babyId || typeof babyId !== 'string') {
        throw new Error('Valid baby ID is required');
      }

      if (!this.isValidTimerState(timerState)) {
        throw new Error('Invalid timer state');
      }

      // Add timestamp for cleanup purposes
      const timerWithTimestamp = {
        ...timerState,
        timestamp: Date.now(),
      };

      await timersStore.setItem(`timer_${babyId}`, timerWithTimestamp);
      this.emitChange('timer_updated', { babyId, timerState });

      logger.debug(
        'Timer state set successfully',
        { babyId, isRunning: timerState.isRunning },
        'DataService'
      );
    } catch (error) {
      logger.error('Failed to set timer state', { babyId, error }, 'DataService');
      throw error;
    }
  }

  async clearTimerState(babyId: string): Promise<void> {
    try {
      if (!babyId || typeof babyId !== 'string') {
        throw new Error('Valid baby ID is required');
      }

      await timersStore.removeItem(`timer_${babyId}`);
      this.emitChange('timer_cleared', { babyId });

      logger.debug('Timer state cleared successfully', { babyId }, 'DataService');
    } catch (error) {
      logger.error('Failed to clear timer state', { babyId, error }, 'DataService');
      throw error;
    }
  }

  private isValidTimerState(timerState: unknown): boolean {
    return (
      timerState &&
      typeof timerState === 'object' &&
      typeof timerState.isRunning === 'boolean' &&
      (timerState.startTime === null ||
        (typeof timerState.startTime === 'string' && !isNaN(Date.parse(timerState.startTime)))) &&
      typeof timerState.elapsed === 'number' &&
      timerState.elapsed >= 0
    );
  }

  async getAllEvents(): Promise<EventRecord[]> {
    try {
      const events: EventRecord[] = [];

      await eventsStore.iterate<EventRecord, void>((event, key) => {
        try {
          // Validate event data during iteration
          if (!this.isValidEventRecord(event)) {
            logger.warn('Skipping invalid event during getAllEvents', { key }, 'DataService');
            return;
          }

          // Additional validation for date parsing
          if (isNaN(new Date(event.startTime).getTime())) {
            logger.warn(
              'Skipping event with invalid date during getAllEvents',
              { key, startTime: event.startTime },
              'DataService'
            );
            return;
          }

          events.push(event);
        } catch (error) {
          logger.error(
            'Error processing event during getAllEvents iteration',
            { key, error },
            'DataService'
          );
          // Continue processing other events
        }
      });

      // Sort with error handling
      const sortedEvents = events.sort((a, b) => {
        try {
          return new Date(b.startTime).getTime() - new Date(a.startTime).getTime();
        } catch (error) {
          logger.warn('Error sorting events, using fallback', { error }, 'DataService');
          return 0; // Keep original order on sort error
        }
      });

      logger.debug(
        'All events retrieved successfully',
        { count: sortedEvents.length },
        'DataService'
      );
      return sortedEvents;
    } catch (error) {
      logger.error('Failed to get all events', error, 'DataService');
      // Return empty array instead of throwing for read operations
      return [];
    }
  }

  async addBaby(baby: Omit<Baby, 'id' | 'createdAt' | 'updatedAt'>): Promise<Baby> {
    try {
      // Validate input data
      this.validateBabyInput(baby);

      // Check for reasonable limits
      await this.checkBabyLimits();

      const now = dateUtils.nowISO();
      const record: Baby = {
        ...baby,
        id: crypto.randomUUID(),
        createdAt: now,
        updatedAt: now,
      };

      await babiesStore.setItem(record.id, record);
      this.emitChange('baby_added', record);

      logger.debug(
        'Baby added successfully',
        { babyId: record.id, name: record.name },
        'DataService'
      );

      return record;
    } catch (error) {
      logger.error('Failed to add baby', error, 'DataService');

      // Handle storage issues
      if (error.message?.includes('QuotaExceededError') || error.name === 'QuotaExceededError') {
        throw new Error('Storage is full. Cannot add new baby.');
      }

      throw error;
    }
  }

  private validateBabyInput(baby: Omit<Baby, 'id' | 'createdAt' | 'updatedAt'>): void {
    if (!baby.name || typeof baby.name !== 'string' || baby.name.trim().length === 0) {
      throw new Error('Baby name is required');
    }

    if (baby.name.length > LIMITS.MAX_BABY_NAME_LENGTH) {
      throw new Error(`Baby name cannot exceed ${LIMITS.MAX_BABY_NAME_LENGTH} characters`);
    }

    // Validate date of birth
    if (!validationUtils.isValidBabyAge(baby.dateOfBirth)) {
      throw new Error('Invalid date of birth - must be within the last year and not in the future');
    }

    if (!baby.timezone || typeof baby.timezone !== 'string') {
      throw new Error('Valid timezone is required');
    }

    // Validate sex if provided
    if (baby.sex !== undefined && baby.sex !== null && !['m', 'f', 'other'].includes(baby.sex)) {
      throw new Error('Invalid sex value');
    }

    // Validate feeding style if provided
    if (
      baby.primaryFeedingStyle !== undefined &&
      baby.primaryFeedingStyle !== null &&
      !['breast', 'bottle', 'both'].includes(baby.primaryFeedingStyle)
    ) {
      throw new Error('Invalid feeding style');
    }
  }

  private async checkBabyLimits(): Promise<void> {
    const babies = await this.listBabies();

    // Reasonable limit to prevent abuse
    if (babies.length >= STORAGE.MAX_BABIES_PER_FAMILY) {
      throw new Error(`Cannot add more than ${STORAGE.MAX_BABIES_PER_FAMILY} babies`);
    }
  }

  async listBabies(): Promise<Baby[]> {
    try {
      const babies: Baby[] = [];

      await babiesStore.iterate<Baby, void>((baby, key) => {
        try {
          // Validate baby data during iteration
          if (!this.isValidBabyRecord(baby)) {
            logger.warn('Skipping invalid baby during iteration', { key, baby }, 'DataService');
            return;
          }

          babies.push(baby);
        } catch (error) {
          logger.error('Error processing baby during iteration', { key, error }, 'DataService');
          // Continue processing other babies
        }
      });

      // Sort babies by creation date, handling any remaining invalid dates
      const validBabies = babies
        .filter(baby => {
          const time = new Date(baby.createdAt).getTime();
          return !isNaN(time);
        })
        .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

      logger.debug('Babies listed successfully', { count: validBabies.length }, 'DataService');

      return validBabies;
    } catch (error) {
      logger.error('Failed to list babies', error, 'DataService');
      throw error;
    }
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
    await napFeedbackStore.iterate<NapFeedback, void>(feedback => {
      if (feedback.babyId === babyId) {
        feedbacks.push(feedback);
      }
    });
    return feedbacks.sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }

  async saveNotificationSettings(babyId: string, settings: NotificationSettings): Promise<void> {
    await settingsStore.setItem(`notifications_${babyId}`, settings);
  }

  async getNotificationSettings(babyId: string): Promise<NotificationSettings | null> {
    return await settingsStore.getItem(`notifications_${babyId}`);
  }

  async clearAllData(): Promise<{
    eventsCleared: number;
    timersCleared: number;
    babiesCleared: number;
  }> {
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

  subscribe(callback: DataListener): () => void {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  private emitChange(action: string, data: unknown): void {
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

    const diaperWet = diapers.filter(e => e.subtype === 'wet' || e.subtype === 'both').length;

    const diaperDirty = diapers.filter(e => e.subtype === 'dirty' || e.subtype === 'both').length;

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

  async storeNapPrediction(babyId: string, prediction: NapPrediction): Promise<void> {
    const key = `nap_prediction_${babyId}`;
    await localforage.setItem(key, {
      ...prediction,
      timestamp: new Date().toISOString(),
    });
  }

  async getNapPrediction(babyId: string): Promise<NapPrediction | null> {
    const key = `nap_prediction_${babyId}`;
    return await localforage.getItem(key);
  }
}

export const dataService = new DataService();
