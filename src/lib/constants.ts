/**
 * Application constants and magic numbers
 */

// Time constants (in milliseconds)
export const TIME = {
  SECOND: 1000,
  MINUTE: 60 * 1000,
  HOUR: 60 * 60 * 1000,
  DAY: 24 * 60 * 60 * 1000,
  WEEK: 7 * 24 * 60 * 60 * 1000,
  MONTH: 30 * 24 * 60 * 60 * 1000,
  YEAR: 365 * 24 * 60 * 60 * 1000,
} as const;

// Storage limits
export const STORAGE = {
  MAX_SIZE_MB: 50,
  MAX_SIZE_BYTES: 50 * 1024 * 1024,
  MAX_EVENTS_PER_DAY: 100,
  MAX_BABIES_PER_FAMILY: 10,
} as const;

// Time limits
export const LIMITS = {
  MAX_EVENT_DURATION_HOURS: 24,
  MAX_EVENT_DURATION_MINUTES: 24 * 60,
  MAX_FEED_AMOUNT_ML: 1000,
  MAX_BABY_NAME_LENGTH: 50,
  MIN_EVENT_LOG_AGE_DAYS: -365, // 1 year ago
  MAX_EVENT_LOG_FUTURE_MINUTES: 5,
} as const;

// UI constants
export const UI = {
  DEBOUNCE_DELAY_MS: 300,
  TOAST_DURATION_MS: 4000,
  ANIMATION_DURATION_MS: 200,
  MAX_RETRY_ATTEMPTS: 3,
  REQUEST_TIMEOUT_MS: 30000,
  STORAGE_TIMEOUT_MS: 5000,
} as const;

// Feature flags and quotas
export const FEATURES = {
  CRY_INSIGHTS_FREE_QUOTA: 3,
  CRY_INSIGHTS_RESET_DAY: 1, // Monday (0 = Sunday, 1 = Monday)
} as const;

// Validation messages
export const MESSAGES = {
  ERRORS: {
    NETWORK_ERROR: 'Network error. Please check your connection and try again.',
    TIMEOUT_ERROR: 'Request timed out. Please try again.',
    STORAGE_FULL: 'Storage is full. Please free up space and try again.',
    INVALID_DATA: 'Invalid data provided.',
    UNAUTHORIZED: 'Authentication failed. Please sign in again.',
    NOT_FOUND: 'The requested item was not found.',
    CONFLICT: 'This item was modified by someone else. Please refresh and try again.',
  },
  SUCCESS: {
    SAVED: 'Changes saved successfully.',
    DELETED: 'Item deleted successfully.',
    SYNCED: 'Data synced successfully.',
  },
} as const;




