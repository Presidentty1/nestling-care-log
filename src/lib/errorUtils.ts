import { logger } from './logger';

/**
 * Common error handling utilities
 */

export interface ErrorResult {
  message: string;
  userMessage: string;
  shouldRetry?: boolean;
  context?: string;
}

export const errorUtils = {
  /**
   * Standardizes error messages for user display
   */
  getUserFriendlyMessage: (error: any): string => {
    if (!error) return 'An unexpected error occurred';

    // Network errors
    if (error.message?.includes('network') || error.message?.includes('fetch')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Timeout errors
    if (error.message?.includes('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (error.message?.includes('auth') || error.message?.includes('JWT')) {
      return 'Authentication failed. Please sign in again.';
    }

    // Permission errors
    if (error.message?.includes('permission') || error.status === 403) {
      return 'You do not have permission to perform this action.';
    }

    // Not found errors
    if (error.status === 404) {
      return 'The requested item was not found.';
    }

    // Validation errors
    if (error.message?.includes('required') || error.message?.includes('invalid')) {
      return error.message;
    }

    // Storage errors
    if (error.message?.includes('storage') || error.message?.includes('QuotaExceededError')) {
      return 'Storage is full. Please free up space and try again.';
    }

    // Conflict errors
    if (error.message?.includes('conflict') || error.code === 'PGRST116') {
      return 'This item was modified by someone else. Please refresh and try again.';
    }

    // Rate limiting
    if (error.status === 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  },

  /**
   * Determines if an error should trigger a retry
   */
  shouldRetry: (error: any): boolean => {
    if (!error) return false;

    // Don't retry auth errors
    if (error.message?.includes('auth') || error.message?.includes('JWT') || error.status === 401) {
      return false;
    }

    // Don't retry permission errors
    if (error.status === 403 || error.message?.includes('permission')) {
      return false;
    }

    // Don't retry validation errors
    if (error.status === 400 || error.message?.includes('invalid') || error.message?.includes('required')) {
      return false;
    }

    // Don't retry not found
    if (error.status === 404) {
      return false;
    }

    // Don't retry conflicts
    if (error.message?.includes('conflict') || error.code === 'PGRST116') {
      return false;
    }

    // Retry network and timeout errors
    if (error.message?.includes('network') || error.message?.includes('fetch') || error.message?.includes('timeout')) {
      return true;
    }

    // Retry server errors (5xx)
    if (error.status >= 500) {
      return true;
    }

    return false;
  },

  /**
   * Processes an error and returns structured error information
   */
  processError: (error: any, context?: string): ErrorResult => {
    const userMessage = errorUtils.getUserFriendlyMessage(error);
    const shouldRetry = errorUtils.shouldRetry(error);

    // Log the error for debugging
    logger.error('Error processed', {
      error: error.message || error,
      context,
      shouldRetry,
      userMessage
    }, 'errorUtils');

    return {
      message: error.message || 'Unknown error',
      userMessage,
      shouldRetry,
      context
    };
  },

  /**
   * Creates a standardized toast error handler
   */
  createToastErrorHandler: (toast: any, context?: string) => {
    return (error: any, customMessage?: string) => {
      const errorResult = errorUtils.processError(error, context);
      const message = customMessage || errorResult.userMessage;
      toast.error(message);
    };
  }
};
