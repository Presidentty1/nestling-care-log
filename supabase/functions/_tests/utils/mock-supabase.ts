// Mock utilities for testing Supabase edge functions
import { createClient } from '@supabase/supabase-js';

// Mock Supabase client for testing
export const createMockSupabaseClient = () => {
  const mockClient = {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          single: jest.fn(() => Promise.resolve({ data: null, error: null }))
        }))
      })),
      insert: jest.fn(() => Promise.resolve({ data: null, error: null })),
      update: jest.fn(() => Promise.resolve({ data: null, error: null })),
      delete: jest.fn(() => Promise.resolve({ data: null, error: null }))
    })),
    auth: {
      getUser: jest.fn(() => Promise.resolve({ data: { user: null }, error: null }))
    },
    storage: {
      from: jest.fn(() => ({
        upload: jest.fn(() => Promise.resolve({ data: null, error: null })),
        download: jest.fn(() => Promise.resolve({ data: null, error: null }))
      }))
    }
  };

  return mockClient as any;
};

// Test fixtures
export const testFixtures = {
  user: {
    id: 'test-user-id',
    email: 'test@example.com'
  },
  baby: {
    id: 'test-baby-id',
    name: 'Test Baby',
    dateOfBirth: '2024-01-01',
    familyId: 'test-family-id'
  },
  event: {
    id: 'test-event-id',
    babyId: 'test-baby-id',
    type: 'feed',
    startTime: '2024-01-01T12:00:00Z',
    amount: 120,
    unit: 'ml'
  }
};

// Helper to create test request
export const createTestRequest = (body: any, headers: Record<string, string> = {}) => {
  return new Request('http://localhost:54321/functions/v1/test', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers
    },
    body: JSON.stringify(body)
  });
};
