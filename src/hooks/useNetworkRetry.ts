import { useState, useCallback } from 'react';
import { toast } from 'sonner';
import { track } from '@/analytics/analytics';

export interface RetryOptions {
  maxRetries?: number;
  baseDelay?: number;
  maxDelay?: number;
  backoffMultiplier?: number;
  onRetry?: (attempt: number, error: Error) => void;
  onSuccess?: () => void;
  onFailure?: (finalError: Error) => void;
}

export function useNetworkRetry(options: RetryOptions = {}) {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 30000,
    backoffMultiplier = 2,
    onRetry,
    onSuccess,
    onFailure,
  } = options;

  const [retrying, setRetrying] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  const calculateDelay = useCallback(
    (attempt: number): number => {
      const delay = Math.min(baseDelay * Math.pow(backoffMultiplier, attempt), maxDelay);
      // Add jitter to prevent thundering herd
      return delay + Math.random() * 1000;
    },
    [baseDelay, maxDelay, backoffMultiplier]
  );

  const retry = useCallback(
    async (fn: () => Promise<void>, context?: string) => {
      if (retryCount >= maxRetries) {
        const error = new Error(`Max retries (${maxRetries}) exceeded`);
        onFailure?.(error);
        toast.error(`Unable to connect${context ? ` (${context})` : ''}. Please try again later.`);

        // Track failed retry attempts
        track('retry_failed', {
          context: context || 'unknown',
          max_retries: maxRetries,
          final_error: error.message,
        });

        return false;
      }

      setRetrying(true);
      setRetryCount(prev => prev + 1);

      const delay = calculateDelay(retryCount);
      await new Promise(resolve => setTimeout(resolve, delay));

      try {
        await fn();
        setRetryCount(0);
        setRetrying(false);
        onSuccess?.();

        if (retryCount > 0) {
          toast.success('Connection restored!');
          track('retry_success', {
            context: context || 'unknown',
            attempts: retryCount,
          });
        }

        return true;
      } catch (error: any) {
        onRetry?.(retryCount, error);

        track('retry_attempt', {
          context: context || 'unknown',
          attempt: retryCount,
          error: error.message,
        });

        // Continue retrying
        return await retry(fn, context);
      }
    },
    [retryCount, maxRetries, calculateDelay, onRetry, onSuccess, onFailure]
  );

  const reset = useCallback(() => {
    setRetryCount(0);
    setRetrying(false);
  }, []);

  const executeWithRetry = useCallback(
    async (operation: () => Promise<void>, context?: string): Promise<boolean> => {
      try {
        await operation();
        return true;
      } catch (error: any) {
        track('operation_failed', {
          context: context || 'unknown',
          error: error.message,
        });

        return await retry(operation, context);
      }
    },
    [retry]
  );

  return {
    retry: executeWithRetry,
    retrying,
    retryCount,
    reset,
    calculateDelay,
  };
}
