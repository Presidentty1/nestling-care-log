import { supabase } from '@/integrations/supabase/client';
import { sanitizeBabyName, sanitizeTimeZone } from '@/lib/sanitization';
import { logger } from '@/lib/logger';

export interface Baby {
  id: string;
  family_id: string;
  name: string;
  date_of_birth: string;
  sex?: 'm' | 'f' | 'other' | null;
  primary_feeding_style?: 'breast' | 'bottle' | 'both' | null;
  timezone: string;
  created_at: string;
  updated_at: string;
}

class BabyService {
  async getUserBabies(): Promise<Baby[]> {
    try {
      const { data: { user }, error: authError } = await supabase.auth.getUser();

      if (authError) {
        logger.error('Authentication error in getUserBabies', authError, 'BabyService');
        throw new Error('Authentication failed. Please sign in again.');
      }

      if (!user) {
        logger.debug('No authenticated user in getUserBabies', {}, 'BabyService');
        return [];
      }

      // Get user's families with error handling
      const { data: memberships, error: membershipError } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id);

      if (membershipError) {
        logger.error('Failed to get family memberships', membershipError, 'BabyService');
        throw new Error('Failed to load family information');
      }

      if (!memberships || memberships.length === 0) {
        logger.debug('User has no family memberships', { userId: user.id }, 'BabyService');
        return [];
      }

      // Validate family IDs
      const familyIds = memberships
        .map(m => m.family_id)
        .filter(id => id && typeof id === 'string');

      if (familyIds.length === 0) {
        logger.warn('No valid family IDs found', { userId: user.id }, 'BabyService');
        return [];
      }

      // Get babies from those families with timeout and retry logic
      const { data: babies, error: babyError } = await this.withRetry(
        () => supabase
          .from('babies')
          .select('*')
          .in('family_id', familyIds)
          .order('created_at', { ascending: true }),
        'getUserBabies'
      );

      if (babyError) {
        logger.error('Failed to get babies', babyError, 'BabyService');
        throw new Error('Failed to load babies');
      }

      // Validate and sanitize baby data
      const validBabies = (babies || [])
        .filter(baby => this.isValidBaby(baby))
        .map(baby => this.sanitizeBaby(baby));

      logger.debug('Babies retrieved successfully', {
        userId: user.id,
        babyCount: validBabies.length
      }, 'BabyService');

      return validBabies as Baby[];
    } catch (error) {
      logger.error('Failed to get user babies', error, 'BabyService');

      // Re-throw with user-friendly message
      if (error.message?.includes('network') || error.message?.includes('fetch')) {
        throw new Error('Network error. Please check your connection and try again.');
      }

      throw error;
    }
  }

  private async withRetry<T>(
    operation: () => Promise<{ data: T; error: any }>,
    operationName: string,
    maxRetries: number = 3
  ): Promise<{ data: T; error: any }> {
    let lastError: any;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const result = await operation();

        // If successful, return immediately
        if (!result.error) {
          return result;
        }

        // If it's a non-retryable error, fail immediately
        if (this.isNonRetryableError(result.error)) {
          return result;
        }

        lastError = result.error;

        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s
          const delay = Math.pow(2, attempt - 1) * 1000;
          logger.debug(`Retrying ${operationName} after ${delay}ms`, { attempt }, 'BabyService');
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      } catch (error) {
        lastError = error;

        if (this.isNonRetryableError(error) || attempt === maxRetries) {
          break;
        }

        const delay = Math.pow(2, attempt - 1) * 1000;
        logger.debug(`Retrying ${operationName} after ${delay}ms due to exception`, { attempt }, 'BabyService');
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    return { data: null, error: lastError };
  }

  private isNonRetryableError(error: any): boolean {
    // Authentication errors shouldn't be retried
    if (error?.message?.includes('JWT') || error?.message?.includes('auth')) {
      return true;
    }

    // Permission errors shouldn't be retried
    if (error?.code === 'PGRST301' || error?.message?.includes('permission')) {
      return true;
    }

    // Validation errors shouldn't be retried
    if (error?.code?.startsWith('23') || error?.message?.includes('violates')) {
      return true;
    }

    return false;
  }

  private isValidBaby(baby: any): boolean {
    return (
      baby &&
      typeof baby === 'object' &&
      typeof baby.id === 'string' &&
      typeof baby.family_id === 'string' &&
      typeof baby.name === 'string' &&
      baby.name.trim().length > 0 &&
      typeof baby.date_of_birth === 'string' &&
      !isNaN(Date.parse(baby.date_of_birth)) &&
      typeof baby.timezone === 'string'
    );
  }

  private sanitizeBaby(baby: any): Baby {
    return {
      ...baby,
      name: sanitizeBabyName(baby.name || ''),
      timezone: sanitizeTimeZone(baby.timezone || 'UTC')
    };
  }

  async getBaby(id: string): Promise<Baby | null> {
    const { data, error } = await supabase
      .from('babies')
      .select('*')
      .eq('id', id)
      .single();

    if (error) return null;
    return data as Baby;
  }

  async createBaby(baby: {
    family_id: string;
    name: string;
    date_of_birth: string;
    sex?: 'm' | 'f' | 'other';
    primary_feeding_style?: 'breast' | 'bottle' | 'both';
  }): Promise<Baby> {
    try {
      // Validate and sanitize inputs
      if (!baby.family_id || typeof baby.family_id !== 'string') {
        throw new Error('Valid family ID is required');
      }

      if (!baby.name || typeof baby.name !== 'string' || baby.name.trim().length === 0) {
        throw new Error('Baby name is required');
      }

      if (baby.name.length > 50) {
        throw new Error('Baby name cannot exceed 50 characters');
      }

      const sanitizedName = sanitizeBabyName(baby.name);
      if (!sanitizedName.trim()) {
        throw new Error('Invalid baby name after sanitization');
      }

      if (!baby.date_of_birth || typeof baby.date_of_birth !== 'string') {
        throw new Error('Date of birth is required');
      }

      // Validate date of birth
      const dob = new Date(baby.date_of_birth);
      if (isNaN(dob.getTime())) {
        throw new Error('Invalid date of birth format');
      }

      // Check that date is not in the future
      const now = new Date();
      if (dob > now) {
        throw new Error('Date of birth cannot be in the future');
      }

      // Check reasonable age limits (not older than 1 year for newborn app)
      const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
      if (dob < oneYearAgo) {
        throw new Error('Date of birth seems too far in the past for this app');
      }

      // Validate sex if provided
      if (baby.sex !== undefined && baby.sex !== null && !['m', 'f', 'other'].includes(baby.sex)) {
        throw new Error('Invalid sex value');
      }

      // Validate feeding style if provided
      if (baby.primary_feeding_style !== undefined && baby.primary_feeding_style !== null &&
          !['breast', 'bottle', 'both'].includes(baby.primary_feeding_style)) {
        throw new Error('Invalid feeding style');
      }

      const timezone = sanitizeTimeZone(Intl.DateTimeFormat().resolvedOptions().timeZone);

      // Check user permissions and baby limits
      await this.validateBabyCreationPermissions(baby.family_id);

      const { data, error } = await this.withRetry(
        () => supabase
          .from('babies')
          .insert({
            ...baby,
            name: sanitizedName,
            timezone,
          })
          .select('*')
          .single(),
        'createBaby'
      );

      if (error) {
        logger.error('Failed to create baby', error, 'BabyService');
        throw new Error('Failed to create baby. Please try again.');
      }

      if (!data) {
        throw new Error('No data returned from baby creation');
      }

      const createdBaby = this.sanitizeBaby(data);

      logger.debug('Baby created successfully', {
        babyId: createdBaby.id,
        name: createdBaby.name,
        familyId: createdBaby.family_id
      }, 'BabyService');

      return createdBaby as Baby;
    } catch (error) {
      logger.error('Failed to create baby', error, 'BabyService');

      // Re-throw with user-friendly messages
      if (error.message?.includes('duplicate key') || error.code === '23505') {
        throw new Error('A baby with this name already exists in the family');
      }

      if (error.message?.includes('violates foreign key') || error.code === '23503') {
        throw new Error('Invalid family. Please refresh and try again.');
      }

      throw error;
    }
  }

  private async validateBabyCreationPermissions(familyId: string): Promise<void> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Authentication required');
      }

      // Check if user is a member of the family
      const { data: membership, error: membershipError } = await supabase
        .from('family_members')
        .select('role')
        .eq('user_id', user.id)
        .eq('family_id', familyId)
        .single();

      if (membershipError || !membership) {
        throw new Error('You do not have permission to add babies to this family');
      }

      // Check baby limit per family (reasonable limit to prevent abuse)
      const { count, error: countError } = await supabase
        .from('babies')
        .select('*', { count: 'exact', head: true })
        .eq('family_id', familyId);

      if (countError) {
        logger.warn('Could not check baby count, proceeding', { familyId }, 'BabyService');
        return;
      }

      if (count && count >= 10) {
        throw new Error('Family has reached the maximum number of babies (10)');
      }
    } catch (error) {
      logger.error('Failed to validate baby creation permissions', { familyId, error }, 'BabyService');
      throw error;
    }
  }

  async updateBaby(id: string, updates: Partial<Baby>): Promise<Baby> {
    const { data, error } = await supabase
      .from('babies')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data as Baby;
  }

  async deleteBaby(id: string): Promise<void> {
    const { error } = await supabase
      .from('babies')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const babyService = new BabyService();
