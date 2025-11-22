import { useEffect, useState } from 'react';
import { useNetworkStatus } from './useNetworkStatus';
import { offlineQueue } from '@/lib/offlineQueue';
import { toast } from 'sonner';

export function useOfflineQueue() {
  const isOnline = useNetworkStatus();
  const [pendingCount, setPendingCount] = useState(0);
  const [conflictCount, setConflictCount] = useState(0);
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
    setConflictCount(status.conflicts || 0);
  };

  const syncQueue = async () => {
    setIsSyncing(true);
    try {
      const result = await offlineQueue.processQueue();
      const status = offlineQueue.getStatus();

      if (result.success > 0) {
        toast.success(`Synced ${result.success} offline events`);
      }
      if (result.failed > 0) {
        toast.error(`Failed to sync ${result.failed} events. They will be retried later.`);
      }
      if (status.conflicts > 0) {
        toast.warning(`${status.conflicts} data conflicts need resolution`, {
          duration: 5000,
          action: {
            label: 'Resolve',
            onClick: () => {
              // Could navigate to conflict resolution screen
              console.log('Navigate to conflict resolution');
            }
          }
        });
      }

      updateStatus();
    } catch (error) {
      console.error('Queue sync error:', error);
      toast.error('Sync failed. Check your connection and try again.');
    } finally {
      setIsSyncing(false);
    }
  };

  const enqueueOperation = (operation: any) => {
    offlineQueue.enqueue(operation);
    updateStatus();
  };

  const getConflicts = () => {
    return offlineQueue.getConflicts();
  };

  const resolveConflict = (conflictResolution: any) => {
    const success = offlineQueue.resolveConflict(conflictResolution);
    if (success) {
      updateStatus();
      toast.success('Conflict resolved');
    }
    return success;
  };

  return {
    pendingCount,
    conflictCount,
    isSyncing,
    syncQueue,
    enqueueOperation,
    updateStatus,
    getConflicts,
    resolveConflict,
  };
}
