import { describe, it, expect } from 'vitest';
import { dateUtils } from '@/lib/dateUtils';

describe('dateUtils', () => {
  describe('isValidISODate', () => {
    it('should validate valid ISO date strings', () => {
      expect(dateUtils.isValidISODate('2024-01-01T10:00:00Z')).toBe(true);
      expect(dateUtils.isValidISODate('2024-01-01T10:00:00.000Z')).toBe(true);
    });

    it('should reject invalid ISO date strings', () => {
      expect(dateUtils.isValidISODate('2024-01-01')).toBe(false);
      expect(dateUtils.isValidISODate('invalid')).toBe(false);
      expect(dateUtils.isValidISODate('')).toBe(false);
      expect(dateUtils.isValidISODate(null as any)).toBe(false);
    });
  });

  describe('isValidDate', () => {
    it('should validate valid date strings', () => {
      expect(dateUtils.isValidDate('2024-01-01')).toBe(true);
      expect(dateUtils.isValidDate('2024-01-01T10:00:00Z')).toBe(true);
      expect(dateUtils.isValidDate('January 1, 2024')).toBe(true);
    });

    it('should reject invalid date strings', () => {
      expect(dateUtils.isValidDate('invalid')).toBe(false);
      expect(dateUtils.isValidDate('')).toBe(false);
      expect(dateUtils.isValidDate(null as any)).toBe(false);
    });
  });

  describe('nowISO', () => {
    it('should return current timestamp in ISO format', () => {
      const result = dateUtils.nowISO();
      expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
      expect(new Date(result).getTime()).toBeLessThanOrEqual(Date.now());
    });
  });

  describe('todayISO', () => {
    it('should return today\'s date in YYYY-MM-DD format', () => {
      const result = dateUtils.todayISO();
      expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      const date = new Date(result);
      expect(date.getDate()).toBe(new Date().getDate());
    });
  });

  describe('getDurationMinutes', () => {
    it('should calculate duration in minutes correctly', () => {
      const start = new Date('2024-01-01T10:00:00Z');
      const end = new Date('2024-01-01T10:30:00Z');
      expect(dateUtils.getDurationMinutes(start, end)).toBe(30);
    });

    it('should handle string dates', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T10:15:00Z';
      expect(dateUtils.getDurationMinutes(start, end)).toBe(15);
    });

    it('should return 0 for invalid dates', () => {
      expect(dateUtils.getDurationMinutes('invalid', 'invalid')).toBe(0);
    });

    it('should return 0 if end is before start', () => {
      const start = new Date('2024-01-01T10:30:00Z');
      const end = new Date('2024-01-01T10:00:00Z');
      expect(dateUtils.getDurationMinutes(start, end)).toBe(0);
    });
  });

  describe('getDurationSeconds', () => {
    it('should calculate duration in seconds correctly', () => {
      const start = new Date('2024-01-01T10:00:00Z');
      const end = new Date('2024-01-01T10:00:30Z');
      expect(dateUtils.getDurationSeconds(start, end)).toBe(30);
    });

    it('should handle string dates', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T10:00:45Z';
      expect(dateUtils.getDurationSeconds(start, end)).toBe(45);
    });
  });

  describe('getDayBounds', () => {
    it('should return start and end of day', () => {
      const date = new Date('2024-01-01T15:30:00Z');
      const bounds = dateUtils.getDayBounds(date);

      expect(bounds.start).toMatch(/2024-01-01T00:00:00/);
      expect(bounds.end).toMatch(/2024-01-01T23:59:59/);
    });

    it('should handle string dates', () => {
      const date = '2024-01-01T15:30:00Z';
      const bounds = dateUtils.getDayBounds(date);

      expect(bounds.start).toMatch(/2024-01-01T00:00:00/);
      expect(bounds.end).toMatch(/2024-01-01T23:59:59/);
    });

    it('should throw error for invalid dates', () => {
      expect(() => dateUtils.getDayBounds('invalid')).toThrow();
    });
  });

  describe('isInFuture', () => {
    it('should detect future dates', () => {
      const future = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now
      expect(dateUtils.isInFuture(future)).toBe(true);
    });

    it('should detect past dates', () => {
      const past = new Date(Date.now() - 10 * 60 * 1000); // 10 minutes ago
      expect(dateUtils.isInFuture(past)).toBe(false);
    });

    it('should handle tolerance', () => {
      const nearFuture = new Date(Date.now() + 2 * 60 * 1000); // 2 minutes from now
      expect(dateUtils.isInFuture(nearFuture, 5)).toBe(false); // Within 5 min tolerance
      expect(dateUtils.isInFuture(nearFuture, 1)).toBe(true); // Outside 1 min tolerance
    });
  });

  describe('isTooOld', () => {
    it('should detect dates that are too old', () => {
      const oldDate = new Date(Date.now() - 400 * 24 * 60 * 60 * 1000); // 400 days ago
      expect(dateUtils.isTooOld(oldDate, 365)).toBe(true);
    });

    it('should allow recent dates', () => {
      const recentDate = new Date(Date.now() - 100 * 24 * 60 * 60 * 1000); // 100 days ago
      expect(dateUtils.isTooOld(recentDate, 365)).toBe(false);
    });

    it('should handle custom max age', () => {
      const date = new Date(Date.now() - 200 * 24 * 60 * 60 * 1000); // 200 days ago
      expect(dateUtils.isTooOld(date, 100)).toBe(true);
      expect(dateUtils.isTooOld(date, 365)).toBe(false);
    });
  });

  describe('validateDateRange', () => {
    it('should validate valid date ranges', () => {
      const start = new Date('2024-01-01T10:00:00Z');
      const end = new Date('2024-01-01T11:00:00Z');
      expect(() => dateUtils.validateDateRange(start, end)).not.toThrow();
    });

    it('should reject end before start', () => {
      const start = new Date('2024-01-01T11:00:00Z');
      const end = new Date('2024-01-01T10:00:00Z');
      expect(() => dateUtils.validateDateRange(start, end)).toThrow('End date cannot be before start date');
    });

    it('should reject ranges exceeding 90 days', () => {
      const start = new Date('2024-01-01T10:00:00Z');
      const end = new Date('2024-04-15T10:00:00Z'); // More than 90 days
      expect(() => dateUtils.validateDateRange(start, end)).toThrow('Date range cannot exceed 90 days');
    });

    it('should allow ranges up to 90 days', () => {
      const start = new Date('2024-01-01T10:00:00Z');
      const end = new Date('2024-03-31T10:00:00Z'); // Exactly 90 days
      expect(() => dateUtils.validateDateRange(start, end)).not.toThrow();
    });
  });
});

