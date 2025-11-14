import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { offlineQueue } from '@/lib/offlineQueue';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { WifiOff, RefreshCw } from 'lucide-react';
import { useEffect, useState } from 'react';

export function OfflineIndicator() {
  const { isOnline } = useNetworkStatus();
  const [queueStatus, setQueueStatus] = useState({ pending: 0, failed: 0 });
  const [isSyncing, setIsSyncing] = useState(false);

  useEffect(() => {
    const updateStatus = () => {
      setQueueStatus(offlineQueue.getStatus());
    };

    updateStatus();
    const interval = setInterval(updateStatus, 2000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (isOnline && queueStatus.pending > 0 && !isSyncing) {
      setIsSyncing(true);
      offlineQueue.processQueue().finally(() => {
        setIsSyncing(false);
      });
    }
  }, [isOnline, queueStatus.pending]);

  if (isOnline && queueStatus.pending === 0) {
    return null;
  }

  return (
    <Alert className="mb-4">
      {!isOnline ? (
        <>
          <WifiOff className="h-4 w-4" />
          <AlertDescription>
            <strong>Offline Mode</strong>
            {queueStatus.pending > 0 && (
              <span className="ml-2">
                {queueStatus.pending} change{queueStatus.pending !== 1 ? 's' : ''} queued for sync
              </span>
            )}
          </AlertDescription>
        </>
      ) : isSyncing ? (
        <>
          <RefreshCw className="h-4 w-4 animate-spin" />
          <AlertDescription>
            <strong>Syncing...</strong>
            <span className="ml-2">
              Uploading {queueStatus.pending} change{queueStatus.pending !== 1 ? 's' : ''}
            </span>
          </AlertDescription>
        </>
      ) : null}
    </Alert>
  );
}
