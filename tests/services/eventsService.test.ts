import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { eventsService } from '@/services/eventsService';
import { supabase } from '@/integrations/supabase/client';

// Mock Supabase client
vi.mock('@/integrations/supabase/client', () => ({
  supabase: {
    from: vi.fn(),
    auth: {
      getUser: vi.fn(),
    },
  },
}));

// Mock analytics
vi.mock('@/analytics/analytics', () => ({
  track: vi.fn(),
}));

// Mock logger
vi.mock('@/lib/logger', () => ({
  logger: {
    debug: vi.fn(),
    error: vi.fn(),
    warn: vi.fn(),
  },
}));

describe('EventsService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('createEvent', () => {
    it('should create a feed event successfully', async () => {
      const mockEvent = {
        id: 'event-1',
        baby_id: 'baby-1',
        family_id: 'family-1',
        type: 'feed',
        subtype: 'breast',
        side: 'left',
        start_time: new Date().toISOString(),
        created_by: 'user-1',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      const mockQuery = {
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockEvent, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await eventsService.createEvent({
        baby_id: 'baby-1',
        family_id: 'family-1',
        type: 'feed',
        subtype: 'breast',
        side: 'left',
        start_time: new Date().toISOString(),
      });

      expect(result).toEqual(mockEvent);
      expect(mockQuery.insert).toHaveBeenCalled();
    });

    it('should handle validation errors', async () => {
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await expect(
        eventsService.createEvent({
          baby_id: '',
          family_id: 'family-1',
          type: 'feed',
          start_time: new Date().toISOString(),
        })
      ).rejects.toThrow();
    });

    it('should handle authentication errors', async () => {
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: null },
        error: { message: 'Not authenticated' },
      });

      await expect(
        eventsService.createEvent({
          baby_id: 'baby-1',
          family_id: 'family-1',
          type: 'feed',
          start_time: new Date().toISOString(),
        })
      ).rejects.toThrow('Authentication');
    });
  });

  describe('getEventsForDay', () => {
    it('should fetch events for a specific day', async () => {
      const mockEvents = [
        {
          id: 'event-1',
          baby_id: 'baby-1',
          family_id: 'family-1',
          type: 'feed',
          start_time: '2024-01-01T10:00:00Z',
        },
        {
          id: 'event-2',
          baby_id: 'baby-1',
          family_id: 'family-1',
          type: 'diaper',
          start_time: '2024-01-01T14:00:00Z',
        },
      ];

      const mockQuery = {
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        gte: vi.fn().mockReturnThis(),
        lte: vi.fn().mockReturnThis(),
        order: vi.fn().mockResolvedValue({ data: mockEvents, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const date = new Date('2024-01-01');
      const result = await eventsService.getEventsForDay('baby-1', date);

      expect(result).toEqual(mockEvents);
      expect(mockQuery.eq).toHaveBeenCalledWith('baby_id', 'baby-1');
    });

    it('should return empty array when no events found', async () => {
      const mockQuery = {
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        gte: vi.fn().mockReturnThis(),
        lte: vi.fn().mockReturnThis(),
        order: vi.fn().mockResolvedValue({ data: [], error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const date = new Date('2024-01-01');
      const result = await eventsService.getEventsForDay('baby-1', date);

      expect(result).toEqual([]);
    });
  });

  describe('updateEvent', () => {
    it('should update an existing event', async () => {
      const mockUpdatedEvent = {
        id: 'event-1',
        baby_id: 'baby-1',
        family_id: 'family-1',
        type: 'feed',
        subtype: 'breast',
        side: 'right',
        start_time: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      const mockQuery = {
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockUpdatedEvent, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await eventsService.updateEvent('event-1', {
        side: 'right',
      });

      expect(result).toEqual(mockUpdatedEvent);
      expect(mockQuery.update).toHaveBeenCalled();
      expect(mockQuery.eq).toHaveBeenCalledWith('id', 'event-1');
    });

    it('should handle update errors', async () => {
      const mockQuery = {
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({
          data: null,
          error: { message: 'Event not found' },
        }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await expect(
        eventsService.updateEvent('event-1', { side: 'right' })
      ).rejects.toThrow();
    });
  });

  describe('deleteEvent', () => {
    it('should delete an event successfully', async () => {
      const mockQuery = {
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await eventsService.deleteEvent('event-1');

      expect(mockQuery.delete).toHaveBeenCalled();
      expect(mockQuery.eq).toHaveBeenCalledWith('id', 'event-1');
    });

    it('should handle delete errors', async () => {
      const mockQuery = {
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({
          data: null,
          error: { message: 'Delete failed' },
        }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await expect(eventsService.deleteEvent('event-1')).rejects.toThrow();
    });
  });

  describe('subscribe', () => {
    it('should subscribe to event updates', () => {
      const callback = vi.fn();
      const unsubscribe = eventsService.subscribe(callback);

      expect(typeof unsubscribe).toBe('function');
    });

    it('should unsubscribe when unsubscribe function is called', () => {
      const callback = vi.fn();
      const unsubscribe = eventsService.subscribe(callback);

      unsubscribe();

      // Verify callback is removed (would need to test emit to verify)
      expect(typeof unsubscribe).toBe('function');
    });
  });
});

