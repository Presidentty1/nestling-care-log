import React from 'react';
import { renderHook, act, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAIChat } from '../useAIChat';
import { supabase } from '@/integrations/supabase/client';
import type { Baby } from '@/lib/types';

// Mock Supabase
jest.mock('@/integrations/supabase/client', () => ({
  supabase: {
    auth: {
      getUser: jest.fn(),
    },
    from: jest.fn(() => ({
      insert: jest.fn(() => ({
        select: jest.fn(() => ({
          single: jest.fn(),
        })),
      })),
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          order: jest.fn(() => ({
            limit: jest.fn(),
          })),
        })),
      })),
    })),
    functions: {
      invoke: jest.fn(),
    },
  },
}));

// Mock buildBabyContext
jest.mock('@/lib/aiContext', () => ({
  buildBabyContext: jest.fn(),
}));

const mockSupabase = supabase as jest.Mocked<typeof supabase>;

describe('useAIChat', () => {
  let queryClient: QueryClient;
  let mockBaby: Baby;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
        mutations: {
          retry: false,
        },
      },
    });

    mockBaby = {
      id: 'baby-1',
      name: 'Test Baby',
      date_of_birth: '2024-01-01',
      family_id: 'family-1',
      created_at: '2024-01-01T00:00:00Z',
    } as Baby;

    // Reset mocks
    jest.clearAllMocks();
  });

  const wrapper = ({ children }: { children: React.ReactNode }) => {
    return React.createElement(QueryClientProvider, { client: queryClient }, children);
  };

  describe('initialization', () => {
    it('should initialize with empty messages when no conversation exists', () => {
      mockSupabase.auth.getUser.mockResolvedValue({
        data: { user: { id: 'user-1' } },
        error: null,
      });
      mockSupabase.from.mockReturnValue({
        select: jest.fn(() => ({
          eq: jest.fn(() => ({
            order: jest.fn(() => ({
              limit: jest.fn().mockResolvedValue({ data: [], error: null }),
            })),
          })),
        })),
      } as any);

      const { result } = renderHook(() => useAIChat(mockBaby), { wrapper });

      expect(result.current.messages).toEqual([]);
      expect(result.current.isLoading).toBe(false);
      expect(result.current.error).toBe(null);
    });
  });

  describe('sendMessage', () => {
    it('should create conversation and send message successfully', async () => {
      const mockUser = { id: 'user-1' };
      const mockFamilyMember = { family_id: 'family-1' };
      const mockConversation = { id: 'conv-1' };
      const mockResponse = { message: 'Test response' };

      // Mock auth
      mockSupabase.auth.getUser.mockResolvedValue({ data: { user: mockUser }, error: null });

      // Mock family lookup
      mockSupabase.from
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              single: jest.fn().mockResolvedValue({ data: mockFamilyMember, error: null }),
            })),
          })),
        } as any)
        // Mock conversation creation
        .mockReturnValueOnce({
          insert: jest.fn(() => ({
            select: jest.fn(() => ({
              single: jest.fn().mockResolvedValue({ data: mockConversation, error: null }),
            })),
          })),
        } as any)
        // Mock user message insert
        .mockReturnValueOnce({
          insert: jest.fn().mockResolvedValue({ error: null }),
        } as any)
        // Mock conversation history
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              order: jest.fn().mockResolvedValue({ data: [], error: null }),
            })),
          })),
        } as any)
        // Mock assistant message insert
        .mockReturnValueOnce({
          insert: jest.fn().mockResolvedValue({ error: null }),
        } as any);

      // Mock edge function
      mockSupabase.functions.invoke.mockResolvedValue({ data: mockResponse, error: null });

      const { result } = renderHook(() => useAIChat(mockBaby), { wrapper });

      await act(async () => {
        await result.current.sendMessage('Test message');
      });

      expect(result.current.isLoading).toBe(false);
      expect(result.current.error).toBe(null);
      expect(mockSupabase.functions.invoke).toHaveBeenCalledWith('ai-assistant', {
        body: expect.objectContaining({
          conversationId: 'conv-1',
          messages: [],
        }),
      });
    });

    it('should handle authentication failure', async () => {
      mockSupabase.auth.getUser.mockResolvedValue({
        data: { user: null },
        error: new Error('Not authenticated'),
      });

      const { result } = renderHook(() => useAIChat(mockBaby), { wrapper });

      await act(async () => {
        await result.current.sendMessage('Test message');
      });

      expect(result.current.error).toBeTruthy();
    });

    it('should handle edge function error', async () => {
      const mockUser = { id: 'user-1' };
      const mockFamilyMember = { family_id: 'family-1' };
      const mockConversation = { id: 'conv-1' };

      // Setup successful auth and conversation creation
      mockSupabase.auth.getUser.mockResolvedValue({ data: { user: mockUser }, error: null });
      mockSupabase.from
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              single: jest.fn().mockResolvedValue({ data: mockFamilyMember, error: null }),
            })),
          })),
        } as any)
        .mockReturnValueOnce({
          insert: jest.fn(() => ({
            select: jest.fn(() => ({
              single: jest.fn().mockResolvedValue({ data: mockConversation, error: null }),
            })),
          })),
        } as any)
        .mockReturnValueOnce({
          insert: jest.fn().mockResolvedValue({ error: null }),
        } as any)
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              order: jest.fn().mockResolvedValue({ data: [], error: null }),
            })),
          })),
        } as any);

      // Mock edge function error
      mockSupabase.functions.invoke.mockResolvedValue({
        data: null,
        error: new Error('Network error'),
      });

      const { result } = renderHook(() => useAIChat(mockBaby), { wrapper });

      await act(async () => {
        await result.current.sendMessage('Test message');
      });

      expect(result.current.error).toBeTruthy();
    });
  });

  describe('conversation reuse', () => {
    it('should reuse existing conversation ID', async () => {
      const mockUser = { id: 'user-1' };
      const mockFamilyMember = { family_id: 'family-1' };
      const mockConversation = { id: 'existing-conv' };
      const mockResponse = { message: 'Response' };

      // Setup mocks
      mockSupabase.auth.getUser.mockResolvedValue({ data: { user: mockUser }, error: null });
      mockSupabase.from
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              single: jest.fn().mockResolvedValue({ data: mockFamilyMember, error: null }),
            })),
          })),
        } as any)
        .mockReturnValueOnce({
          insert: jest.fn().mockResolvedValue({ error: null }),
        } as any)
        .mockReturnValueOnce({
          select: jest.fn(() => ({
            eq: jest.fn(() => ({
              order: jest.fn().mockResolvedValue({ data: [], error: null }),
            })),
          })),
        } as any)
        .mockReturnValueOnce({
          insert: jest.fn().mockResolvedValue({ error: null }),
        } as any);

      mockSupabase.functions.invoke.mockResolvedValue({ data: mockResponse, error: null });

      const { result } = renderHook(() => useAIChat(mockBaby), { wrapper });

      // First message - creates conversation
      await act(async () => {
        await result.current.sendMessage('First message');
      });

      // Second message - should reuse conversation
      await act(async () => {
        await result.current.sendMessage('Second message');
      });

      // Verify conversation creation was called only once
      expect(mockSupabase.from).toHaveBeenCalledTimes(4); // family lookup + conv creation + 2 message inserts
    });
  });
});
