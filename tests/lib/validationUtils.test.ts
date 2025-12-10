import { describe, it, expect, vi } from 'vitest';
import { validationUtils } from '@/lib/validationUtils';

describe('validationUtils', () => {
  describe('isValidUUID', () => {
    it('should validate correct UUIDs', () => {
      expect(validationUtils.isValidUUID('123e4567-e89b-12d3-a456-426614174000')).toBe(true);
      expect(validationUtils.isValidUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
    });

    it('should reject invalid UUIDs', () => {
      expect(validationUtils.isValidUUID('not-a-uuid')).toBe(false);
      expect(validationUtils.isValidUUID('123')).toBe(false);
      expect(validationUtils.isValidUUID('')).toBe(false);
      expect(validationUtils.isValidUUID(null as any)).toBe(false);
    });
  });

  describe('isValidEmail', () => {
    it('should validate correct emails', () => {
      expect(validationUtils.isValidEmail('test@example.com')).toBe(true);
      expect(validationUtils.isValidEmail('user.name@domain.co.uk')).toBe(true);
      expect(validationUtils.isValidEmail('test+tag@example.com')).toBe(true);
    });

    it('should reject invalid emails', () => {
      expect(validationUtils.isValidEmail('not-an-email')).toBe(false);
      expect(validationUtils.isValidEmail('@example.com')).toBe(false);
      expect(validationUtils.isValidEmail('test@')).toBe(false);
      expect(validationUtils.isValidEmail('')).toBe(false);
    });

    it('should trim whitespace', () => {
      expect(validationUtils.isValidEmail('  test@example.com  ')).toBe(true);
    });
  });

  describe('isValidBabyName', () => {
    it('should validate correct names', () => {
      expect(validationUtils.isValidBabyName('Emma')).toBe(true);
      expect(validationUtils.isValidBabyName('Mary-Jane')).toBe(true);
      expect(validationUtils.isValidBabyName("O'Brien")).toBe(true);
    });

    it('should reject invalid names', () => {
      expect(validationUtils.isValidBabyName('')).toBe(false);
      expect(validationUtils.isValidBabyName('A'.repeat(51))).toBe(false);
      expect(validationUtils.isValidBabyName('123')).toBe(false);
      expect(validationUtils.isValidBabyName('Test@Name')).toBe(false);
    });
  });

  describe('isValidEventType', () => {
    it('should validate correct event types', () => {
      expect(validationUtils.isValidEventType('feed')).toBe(true);
      expect(validationUtils.isValidEventType('sleep')).toBe(true);
      expect(validationUtils.isValidEventType('diaper')).toBe(true);
      expect(validationUtils.isValidEventType('tummy_time')).toBe(true);
    });

    it('should reject invalid event types', () => {
      expect(validationUtils.isValidEventType('invalid')).toBe(false);
      expect(validationUtils.isValidEventType('')).toBe(false);
    });
  });

  describe('isValidDiaperSubtype', () => {
    it('should validate correct subtypes', () => {
      expect(validationUtils.isValidDiaperSubtype('wet')).toBe(true);
      expect(validationUtils.isValidDiaperSubtype('dirty')).toBe(true);
      expect(validationUtils.isValidDiaperSubtype('both')).toBe(true);
    });

    it('should reject invalid subtypes', () => {
      expect(validationUtils.isValidDiaperSubtype('invalid')).toBe(false);
    });
  });

  describe('isValidFeedingSide', () => {
    it('should validate correct sides', () => {
      expect(validationUtils.isValidFeedingSide('left')).toBe(true);
      expect(validationUtils.isValidFeedingSide('right')).toBe(true);
      expect(validationUtils.isValidFeedingSide('both')).toBe(true);
    });

    it('should reject invalid sides', () => {
      expect(validationUtils.isValidFeedingSide('invalid')).toBe(false);
    });
  });

  describe('isValidAmount', () => {
    it('should validate correct amounts', () => {
      expect(validationUtils.isValidAmount(1)).toBe(true);
      expect(validationUtils.isValidAmount(100)).toBe(true);
      expect(validationUtils.isValidAmount(1000)).toBe(true);
    });

    it('should reject invalid amounts', () => {
      expect(validationUtils.isValidAmount(0)).toBe(false);
      expect(validationUtils.isValidAmount(-1)).toBe(false);
      expect(validationUtils.isValidAmount(1001)).toBe(false);
    });
  });

  describe('isValidDuration', () => {
    it('should validate correct durations', () => {
      expect(validationUtils.isValidDuration(0)).toBe(true);
      expect(validationUtils.isValidDuration(60)).toBe(true);
      expect(validationUtils.isValidDuration(1440)).toBe(true);
    });

    it('should reject invalid durations', () => {
      expect(validationUtils.isValidDuration(-1)).toBe(false);
      expect(validationUtils.isValidDuration(1441)).toBe(false);
    });
  });

  describe('isValidBabyAge', () => {
    it('should validate correct ages', () => {
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      expect(validationUtils.isValidBabyAge(sixMonthsAgo.toISOString())).toBe(true);
    });

    it('should reject future dates', () => {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 1);
      expect(validationUtils.isValidBabyAge(future.toISOString())).toBe(false);
    });

    it('should reject dates older than 1 year', () => {
      const twoYearsAgo = new Date();
      twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
      expect(validationUtils.isValidBabyAge(twoYearsAgo.toISOString())).toBe(false);
    });
  });

  describe('validateEvent', () => {
    it('should validate complete valid event', () => {
      const event = {
        baby_id: '123e4567-e89b-12d3-a456-426614174000',
        family_id: '123e4567-e89b-12d3-a456-426614174001',
        type: 'feed',
        start_time: new Date().toISOString(),
      };

      const result = validationUtils.validateEvent(event);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject event with missing required fields', () => {
      const event = {
        type: 'feed',
      };

      const result = validationUtils.validateEvent(event);
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should reject event with invalid UUIDs', () => {
      const event = {
        baby_id: 'invalid',
        family_id: 'invalid',
        type: 'feed',
        start_time: new Date().toISOString(),
      };

      const result = validationUtils.validateEvent(event);
      expect(result.isValid).toBe(false);
    });

    it('should reject event with future start time', () => {
      const future = new Date();
      future.setHours(future.getHours() + 1);

      const event = {
        baby_id: '123e4567-e89b-12d3-a456-426614174000',
        family_id: '123e4567-e89b-12d3-a456-426614174001',
        type: 'feed',
        start_time: future.toISOString(),
      };

      const result = validationUtils.validateEvent(event);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Event time cannot be in the future');
    });

    it('should reject event with end before start', () => {
      const start = new Date();
      const end = new Date(start.getTime() - 1000);

      const event = {
        baby_id: '123e4567-e89b-12d3-a456-426614174000',
        family_id: '123e4567-e89b-12d3-a456-426614174001',
        type: 'feed',
        start_time: start.toISOString(),
        end_time: end.toISOString(),
      };

      const result = validationUtils.validateEvent(event);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('End time cannot be before start time');
    });
  });

  describe('validateBaby', () => {
    it('should validate complete valid baby', () => {
      const baby = {
        name: 'Emma',
        date_of_birth: new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000).toISOString(),
        sex: 'f',
        primary_feeding_style: 'breast',
      };

      const result = validationUtils.validateBaby(baby);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject baby with missing name', () => {
      const baby = {
        date_of_birth: new Date().toISOString(),
      };

      const result = validationUtils.validateBaby(baby);
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should reject baby with invalid date of birth', () => {
      const baby = {
        name: 'Emma',
        date_of_birth: 'invalid',
      };

      const result = validationUtils.validateBaby(baby);
      expect(result.isValid).toBe(false);
    });
  });
});
