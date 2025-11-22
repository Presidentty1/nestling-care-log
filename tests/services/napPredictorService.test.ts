import { describe, it, expect, vi, beforeEach } from 'vitest';
import { napPredictorService } from '@/services/napPredictorService';
import { addMinutes } from 'date-fns';

// Mock eventsService
vi.mock('@/services/eventsService', () => ({
  eventsService: {
    getEventsByRange: vi.fn(),
  },
}));

describe('NapPredictorService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('calculateNextNapWindow', () => {
    it('should calculate nap window for 0-2 months', () => {
      const lastSleepEnd = new Date('2024-01-01T10:00:00Z');
      const result = napPredictorService.calculateNextNapWindow(lastSleepEnd, 1);

      expect(result).not.toBeNull();
      expect(result!.start).toEqual(addMinutes(lastSleepEnd, 45));
      expect(result!.end).toEqual(addMinutes(lastSleepEnd, 75));
      expect(result!.reason).toContain('0-2 months');
    });

    it('should calculate nap window for 3-4 months', () => {
      const lastSleepEnd = new Date('2024-01-01T10:00:00Z');
      const result = napPredictorService.calculateNextNapWindow(lastSleepEnd, 3);

      expect(result).not.toBeNull();
      expect(result!.start).toEqual(addMinutes(lastSleepEnd, 75));
      expect(result!.end).toEqual(addMinutes(lastSleepEnd, 120));
      expect(result!.reason).toContain('3-4 months');
    });

    it('should calculate nap window for 5-7 months', () => {
      const lastSleepEnd = new Date('2024-01-01T10:00:00Z');
      const result = napPredictorService.calculateNextNapWindow(lastSleepEnd, 6);

      expect(result).not.toBeNull();
      expect(result!.start).toEqual(addMinutes(lastSleepEnd, 120));
      expect(result!.end).toEqual(addMinutes(lastSleepEnd, 150));
    });

    it('should return null for invalid last sleep end', () => {
      const result = napPredictorService.calculateNextNapWindow(null as any, 3);
      expect(result).toBeNull();
    });
  });

  describe('calculateFromEvents', () => {
    it('should calculate nap window from sleep events', () => {
      const dateOfBirth = new Date('2024-01-01');
      dateOfBirth.setMonth(dateOfBirth.getMonth() - 3);

      const events = [
        {
          id: 'event-1',
          type: 'sleep',
          start_time: '2024-01-15T10:00:00Z',
          end_time: '2024-01-15T11:00:00Z',
        },
        {
          id: 'event-2',
          type: 'feed',
          start_time: '2024-01-15T12:00:00Z',
        },
      ] as any;

      const result = napPredictorService.calculateFromEvents(events, dateOfBirth.toISOString());

      expect(result).not.toBeNull();
      expect(result!.start.getTime()).toBeGreaterThan(new Date('2024-01-15T11:00:00Z').getTime());
    });

    it('should return null when no sleep events', () => {
      const events = [
        {
          id: 'event-1',
          type: 'feed',
          start_time: '2024-01-15T10:00:00Z',
        },
      ] as any;

      const result = napPredictorService.calculateFromEvents(events, new Date().toISOString());
      expect(result).toBeNull();
    });

    it('should use most recent sleep event', () => {
      const dateOfBirth = new Date('2024-01-01');
      dateOfBirth.setMonth(dateOfBirth.getMonth() - 3);

      const events = [
        {
          id: 'event-1',
          type: 'sleep',
          start_time: '2024-01-15T10:00:00Z',
          end_time: '2024-01-15T11:00:00Z',
        },
        {
          id: 'event-2',
          type: 'sleep',
          start_time: '2024-01-15T14:00:00Z',
          end_time: '2024-01-15T15:00:00Z',
        },
      ] as any;

      const result = napPredictorService.calculateFromEvents(events, dateOfBirth.toISOString());

      expect(result).not.toBeNull();
      // Should use the more recent sleep (15:00 end time)
      expect(result!.start.getTime()).toBeGreaterThan(new Date('2024-01-15T15:00:00Z').getTime());
    });
  });

  describe('getLearningMetrics', () => {
    it('should calculate metrics from events', async () => {
      const { eventsService } = await import('@/services/eventsService');
      vi.mocked(eventsService.getEventsByRange).mockResolvedValue([
        {
          id: 'event-1',
          type: 'sleep',
          start_time: '2024-01-15T10:00:00Z',
        },
        {
          id: 'event-2',
          type: 'sleep',
          start_time: '2024-01-16T10:00:00Z',
        },
        {
          id: 'event-3',
          type: 'feed',
          start_time: '2024-01-17T10:00:00Z',
        },
      ] as any);

      const result = await napPredictorService.getLearningMetrics('baby-1');

      expect(result.daysLogged).toBe(3);
      expect(result.napCount).toBe(2);
    });

    it('should return zeros when no events', async () => {
      const { eventsService } = await import('@/services/eventsService');
      vi.mocked(eventsService.getEventsByRange).mockResolvedValue([]);

      const result = await napPredictorService.getLearningMetrics('baby-1');

      expect(result.daysLogged).toBe(0);
      expect(result.napCount).toBe(0);
      expect(result.recentAdjustments).toEqual([]);
    });

    it('should handle errors gracefully', async () => {
      const { eventsService } = await import('@/services/eventsService');
      vi.mocked(eventsService.getEventsByRange).mockRejectedValue(new Error('Network error'));

      const result = await napPredictorService.getLearningMetrics('baby-1');

      expect(result.daysLogged).toBe(0);
      expect(result.napCount).toBe(0);
    });
  });
});

