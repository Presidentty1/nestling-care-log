import { describe, it, expect } from 'vitest';
import {
  formatDuration,
  formatTimerDisplay,
  formatTimeRange,
  calculateDuration,
  getElapsedSeconds,
  isCrossMidnight,
} from '@/utils/time';

describe('Time Utils', () => {
  describe('formatDuration', () => {
    it('formats minutes correctly', () => {
      expect(formatDuration(45)).toBe('45m');
      expect(formatDuration(0)).toBe('0m');
    });

    it('formats hours and minutes correctly', () => {
      expect(formatDuration(90)).toBe('1h 30m');
      expect(formatDuration(120)).toBe('2h 0m');
      expect(formatDuration(150)).toBe('2h 30m');
    });
  });

  describe('formatTimerDisplay', () => {
    it('formats seconds correctly', () => {
      expect(formatTimerDisplay(0)).toBe('00:00');
      expect(formatTimerDisplay(30)).toBe('00:30');
      expect(formatTimerDisplay(90)).toBe('01:30');
      expect(formatTimerDisplay(3661)).toBe('61:01');
    });
  });

  describe('formatTimeRange', () => {
    it('formats time range correctly', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T11:30:00Z';
      const result = formatTimeRange(start, end);

      // Format may vary by locale, but should contain both times
      expect(result).toContain('10:00');
      expect(result).toContain('11:30');
    });
  });

  describe('calculateDuration', () => {
    it('calculates duration in minutes', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T11:30:00Z';

      expect(calculateDuration(start, end)).toBe(90);
    });

    it('handles zero duration', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T10:00:00Z';

      expect(calculateDuration(start, end)).toBe(0);
    });
  });

  describe('getElapsedSeconds', () => {
    it('calculates elapsed seconds from past time', () => {
      const pastTime = new Date(Date.now() - 60000).toISOString(); // 1 minute ago
      const elapsed = getElapsedSeconds(pastTime);

      expect(elapsed).toBeGreaterThan(55); // Allow some variance
      expect(elapsed).toBeLessThan(65);
    });
  });

  describe('isCrossMidnight', () => {
    it('detects cross-midnight events', () => {
      const start = '2024-01-01T23:00:00Z';
      const end = '2024-01-02T01:00:00Z';

      expect(isCrossMidnight(start, end)).toBe(true);
    });

    it('detects same-day events', () => {
      const start = '2024-01-01T10:00:00Z';
      const end = '2024-01-01T11:00:00Z';

      expect(isCrossMidnight(start, end)).toBe(false);
    });
  });
});
