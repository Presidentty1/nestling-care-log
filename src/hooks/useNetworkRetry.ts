import { useState } from 'react';
import { toast } from 'sonner';

export function useNetworkRetry(maxRetries = 3) {
  const [retrying, setRetrying] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  const retry = async (fn: () => Promise<void>) => {
    if (retryCount >= maxRetries) {
      toast.error('Unable to connect. Please try again later.');
      return;
    }

    setRetrying(true);
    setRetryCount(prev => prev + 1);
    
    const delay = Math.pow(2, retryCount) * 1000; // 1s, 2s, 4s
    await new Promise(resolve => setTimeout(resolve, delay));

    try {
      await fn();
      setRetryCount(0);
      toast.success('Connection restored!');
    } catch (error) {
      retry(fn);
    } finally {
      setRetrying(false);
    }
  };

  const reset = () => {
    setRetryCount(0);
    setRetrying(false);
  };

  return { retry, retrying, retryCount, reset };
}
