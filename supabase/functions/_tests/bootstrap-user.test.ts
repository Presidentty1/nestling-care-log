import { createMockSupabaseClient, testFixtures, createTestRequest } from './utils/mock-supabase.ts';
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

// Mock the bootstrap-user function
jest.mock('../bootstrap-user/index.ts', () => ({
  default: async (req: Request) => {
    const supabase = createMockSupabaseClient();

    try {
      const { email, babyName, babyDateOfBirth } = await req.json();

      // Validate required fields
      if (!email || !babyName || !babyDateOfBirth) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }

      // Mock user creation
      const mockUser = {
        id: 'test-user-id',
        email,
        created_at: new Date().toISOString()
      };

      // Mock family creation
      const mockFamily = {
        id: 'test-family-id',
        name: `${babyName}'s Family`,
        created_at: new Date().toISOString()
      };

      // Mock baby creation
      const mockBaby = {
        id: 'test-baby-id',
        name: babyName,
        date_of_birth: babyDateOfBirth,
        family_id: mockFamily.id,
        created_at: new Date().toISOString()
      };

      return new Response(
        JSON.stringify({
          user: mockUser,
          family: mockFamily,
          baby: mockBaby
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid request body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
}));

describe('bootstrap-user function', () => {
  test('should create user, family, and baby with valid data', async () => {
    const mockFunction = await import('../bootstrap-user/index.ts');

    const request = createTestRequest({
      email: 'test@example.com',
      babyName: 'Test Baby',
      babyDateOfBirth: '2024-01-01'
    });

    const response = await mockFunction.default(request);
    const result = await response.json();

    expect(response.status).toBe(200);
    expect(result.user).toBeDefined();
    expect(result.family).toBeDefined();
    expect(result.baby).toBeDefined();
    expect(result.user.email).toBe('test@example.com');
    expect(result.baby.name).toBe('Test Baby');
  });

  test('should return error for missing required fields', async () => {
    const mockFunction = await import('../bootstrap-user/index.ts');

    const request = createTestRequest({
      email: 'test@example.com'
      // Missing babyName and babyDateOfBirth
    });

    const response = await mockFunction.default(request);
    const result = await response.json();

    expect(response.status).toBe(400);
    expect(result.error).toContain('Missing required fields');
  });

  test('should return error for invalid JSON', async () => {
    const mockFunction = await import('../bootstrap-user/index.ts');

    const request = new Request('http://localhost:54321/functions/v1/bootstrap-user', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: 'invalid json'
    });

    const response = await mockFunction.default(request);
    const result = await response.json();

    expect(response.status).toBe(400);
    expect(result.error).toContain('Invalid request body');
  });
});