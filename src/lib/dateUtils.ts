import { differenceInMinutes, differenceInSeconds, startOfDay, endOfDay } from 'date-fns';

/**
 * Common date utility functions used across the application
 */

export const dateUtils = {
  /**
   * Validates if a string is a valid ISO date
   */
  isValidISODate: (dateString: string): boolean => {
    if (!dateString || typeof dateString !== 'string') return false;
    const date = new Date(dateString);
    return !isNaN(date.getTime()) && dateString.includes('T');
  },

  /**
   * Validates if a string is a valid date (any format)
   */
  isValidDate: (dateString: string): boolean => {
    if (!dateString || typeof dateString !== 'string') return false;
    return !isNaN(Date.parse(dateString));
  },

  /**
   * Gets current timestamp in ISO format
   */
  nowISO: (): string => new Date().toISOString(),

  /**
   * Gets current date in YYYY-MM-DD format
   */
  todayISO: (): string => new Date().toISOString().split('T')[0],

  /**
   * Calculates duration between two dates in minutes
   */
  getDurationMinutes: (start: Date | string, end: Date | string): number => {
    const startDate = typeof start === 'string' ? new Date(start) : start;
    const endDate = typeof end === 'string' ? new Date(end) : end;

    if (!dateUtils.isValidDate(startDate.toISOString()) || !dateUtils.isValidDate(endDate.toISOString())) {
      return 0;
    }

    return Math.max(0, differenceInMinutes(endDate, startDate));
  },

  /**
   * Calculates duration between two dates in seconds
   */
  getDurationSeconds: (start: Date | string, end: Date | string): number => {
    const startDate = typeof start === 'string' ? new Date(start) : start;
    const endDate = typeof end === 'string' ? new Date(end) : end;

    if (!dateUtils.isValidDate(startDate.toISOString()) || !dateUtils.isValidDate(endDate.toISOString())) {
      return 0;
    }

    return Math.max(0, differenceInSeconds(endDate, startDate));
  },

  /**
   * Gets start and end of day for a given date
   */
  getDayBounds: (date: Date | string): { start: string; end: string } => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    if (!dateUtils.isValidDate(dateObj.toISOString())) {
      throw new Error('Invalid date provided');
    }

    return {
      start: startOfDay(dateObj).toISOString(),
      end: endOfDay(dateObj).toISOString()
    };
  },

  /**
   * Checks if a date is in the future (with small tolerance)
   */
  isInFuture: (date: Date | string, toleranceMinutes: number = 5): boolean => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const now = new Date();
    const toleranceMs = toleranceMinutes * 60 * 1000;

    return dateObj.getTime() > (now.getTime() + toleranceMs);
  },

  /**
   * Checks if a date is too far in the past
   */
  isTooOld: (date: Date | string, maxAgeDays: number = 365): boolean => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const cutoff = new Date(Date.now() - maxAgeDays * 24 * 60 * 60 * 1000);

    return dateObj < cutoff;
  },

  /**
   * Validates date range for reasonable bounds
   */
  validateDateRange: (start: Date | string, end: Date | string): void => {
    const startDate = typeof start === 'string' ? new Date(start) : start;
    const endDate = typeof end === 'string' ? new Date(end) : end;

    if (endDate < startDate) {
      throw new Error('End date cannot be before start date');
    }

    const durationMs = endDate.getTime() - startDate.getTime();
    const maxDurationMs = 90 * 24 * 60 * 60 * 1000; // 90 days

    if (durationMs > maxDurationMs) {
      throw new Error('Date range cannot exceed 90 days');
    }
  }
};




