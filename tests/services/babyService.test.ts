import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { babyService } from '@/services/babyService';
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

// Mock logger
vi.mock('@/lib/logger', () => ({
  logger: {
    debug: vi.fn(),
    error: vi.fn(),
    warn: vi.fn(),
  },
}));

describe('BabyService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('getUserBabies', () => {
    it('should fetch babies for authenticated user', async () => {
      const mockBabies = [
        {
          id: 'baby-1',
          family_id: 'family-1',
          name: 'Baby One',
          date_of_birth: '2024-01-01',
          timezone: 'America/New_York',
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-01T00:00:00Z',
        },
      ];

      const mockMemberships = {
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({
          data: [{ family_id: 'family-1' }],
          error: null,
        }),
      };

      const mockBabiesQuery = {
        select: vi.fn().mockReturnThis(),
        in: vi.fn().mockReturnThis(),
        order: vi.fn().mockResolvedValue({ data: mockBabies, error: null }),
      };

      vi.mocked(supabase.from)
        .mockReturnValueOnce(mockMemberships as any)
        .mockReturnValueOnce(mockBabiesQuery as any);

      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await babyService.getUserBabies();

      expect(result).toEqual(mockBabies);
      expect(mockMemberships.eq).toHaveBeenCalledWith('user_id', 'user-1');
    });

    it('should return empty array when user has no family memberships', async () => {
      const mockMemberships = {
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({
          data: [],
          error: null,
        }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockMemberships as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await babyService.getUserBabies();

      expect(result).toEqual([]);
    });

    it('should handle authentication errors', async () => {
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: null },
        error: { message: 'Not authenticated' },
      });

      await expect(babyService.getUserBabies()).rejects.toThrow('Authentication');
    });

    it('should handle network errors gracefully', async () => {
      const mockMemberships = {
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockRejectedValue(new Error('Network error')),
      };

      vi.mocked(supabase.from).mockReturnValue(mockMemberships as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await expect(babyService.getUserBabies()).rejects.toThrow();
    });
  });

  describe('createBaby', () => {
    it('should create a baby successfully', async () => {
      const mockBaby = {
        id: 'baby-1',
        family_id: 'family-1',
        name: 'Baby One',
        date_of_birth: '2024-01-01',
        timezone: 'America/New_York',
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
      };

      const mockQuery = {
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockBaby, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await babyService.createBaby({
        family_id: 'family-1',
        name: 'Baby One',
        date_of_birth: '2024-01-01',
        timezone: 'America/New_York',
      });

      expect(result).toEqual(mockBaby);
      expect(mockQuery.insert).toHaveBeenCalled();
    });

    it('should validate baby name', async () => {
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await expect(
        babyService.createBaby({
          family_id: 'family-1',
          name: '',
          date_of_birth: '2024-01-01',
          timezone: 'America/New_York',
        })
      ).rejects.toThrow();
    });
  });

  describe('updateBaby', () => {
    it('should update baby successfully', async () => {
      const mockUpdatedBaby = {
        id: 'baby-1',
        family_id: 'family-1',
        name: 'Updated Name',
        date_of_birth: '2024-01-01',
        timezone: 'America/New_York',
        updated_at: new Date().toISOString(),
      };

      const mockQuery = {
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockUpdatedBaby, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      const result = await babyService.updateBaby('baby-1', {
        name: 'Updated Name',
      });

      expect(result).toEqual(mockUpdatedBaby);
      expect(mockQuery.update).toHaveBeenCalled();
      expect(mockQuery.eq).toHaveBeenCalledWith('id', 'baby-1');
    });
  });

  describe('deleteBaby', () => {
    it('should delete baby successfully', async () => {
      const mockQuery = {
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      };

      vi.mocked(supabase.from).mockReturnValue(mockQuery as any);
      vi.mocked(supabase.auth.getUser).mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });

      await babyService.deleteBaby('baby-1');

      expect(mockQuery.delete).toHaveBeenCalled();
      expect(mockQuery.eq).toHaveBeenCalledWith('id', 'baby-1');
    });
  });
});

