import { useEffect, useState } from 'react';
import { useNetworkStatus } from './useNetworkStatus';
import { offlineQueue } from '@/lib/offlineQueue';
import { toast } from 'sonner';

export function useOfflineQueue() {
  const isOnline = useNetworkStatus();
  const [pendingCount, setPendingCount] = useState(0);
  const [isSyncing, setIsSyncing] = useState(false);

  useEffect(() => {
    updateStatus();
  }, []);

  useEffect(() => {
    if (isOnline && pendingCount > 0 && !isSyncing) {
      syncQueue();
    }
  }, [isOnline, pendingCount]);

  const updateStatus = () => {
    const status = offlineQueue.getStatus();
    setPendingCount(status.pending);
  };

  const syncQueue = async () => {
    setIsSyncing(true);
    try {
      const result = await offlineQueue.processQueue();
      if (result.success > 0) {
        toast.success(`Synced ${result.success} offline events`);
        updateStatus();
      }
      if (result.failed > 0) {
        toast.error(`Failed to sync ${result.failed} events`);
      }
    } catch (error) {
      console.error('Queue sync error:', error);
    } finally {
      setIsSyncing(false);
    }
  };

  const enqueueOperation = (operation: any) => {
    offlineQueue.enqueue(operation);
    updateStatus();
  };

  return {
    pendingCount,
    isSyncing,
    syncQueue,
    enqueueOperation,
    updateStatus,
  };
}
