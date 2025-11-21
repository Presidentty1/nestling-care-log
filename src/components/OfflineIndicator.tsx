import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { offlineQueue } from '@/lib/offlineQueue';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { WifiOff, RefreshCw, CheckCircle, AlertTriangle } from 'lucide-react';
import { useEffect, useState } from 'react';
import { toast } from 'sonner';
import { track } from '@/analytics/analytics';

interface OfflineIndicatorProps {
  showDetailed?: boolean;
  onManualSync?: () => void;
}

export function OfflineIndicator({ showDetailed = false, onManualSync }: OfflineIndicatorProps) {
  const { isOnline, wasOffline } = useNetworkStatus();
  const [queueStatus, setQueueStatus] = useState({ pending: 0, failed: 0 });
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSyncTime, setLastSyncTime] = useState<Date | null>(null);

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
      handleAutoSync();
    }
  }, [isOnline, queueStatus.pending]);

  const handleAutoSync = async () => {
    setIsSyncing(true);
    try {
      const result = await offlineQueue.processQueue();
      setLastSyncTime(new Date());

      if (result.success > 0) {
        toast.success(`Synced ${result.success} changes`);
        track('sync_success', {
          changes_synced: result.success,
          auto_sync: true
        });
      }

      if (result.failed > 0) {
        toast.error(`Failed to sync ${result.failed} changes`);
        track('sync_partial_failure', {
          failed_count: result.failed,
          auto_sync: true
        });
      }
    } catch (error) {
      console.error('Auto sync failed:', error);
      toast.error('Sync failed. Check your connection.');
    } finally {
      setIsSyncing(false);
    }
  };

  const handleManualSync = async () => {
    if (!isOnline) {
      toast.error('Cannot sync while offline');
      return;
    }

    setIsSyncing(true);
    onManualSync?.();

    try {
      const result = await offlineQueue.processQueue();
      setLastSyncTime(new Date());

      if (result.success > 0) {
        toast.success(`Synced ${result.success} changes`);
        track('sync_success', {
          changes_synced: result.success,
          manual_sync: true
        });
      } else if (result.failed === 0) {
        toast.success('All changes are up to date');
      }

      if (result.failed > 0) {
        toast.error(`${result.failed} changes failed to sync`);
      }
    } catch (error) {
      console.error('Manual sync failed:', error);
      toast.error('Sync failed. Please try again.');
    } finally {
      setIsSyncing(false);
    }
  };

  // Don't show if everything is synced and online
  if (isOnline && queueStatus.pending === 0 && queueStatus.failed === 0 && !isSyncing) {
    if (showDetailed && lastSyncTime) {
      return (
        <div className="px-4 py-2 text-xs text-muted-foreground text-center">
          <CheckCircle className="h-3 w-3 inline mr-1" />
          Last synced {lastSyncTime.toLocaleTimeString()}
        </div>
      );
    }
    return null;
  }

  return (
    <Alert className={`mb-4 ${!isOnline ? 'border-orange-200 bg-orange-50' : ''}`}>
      {!isOnline ? (
        <>
          <WifiOff className="h-4 w-4" />
          <AlertDescription className="flex items-center justify-between">
            <div>
              <strong>You're offline</strong>
              <div className="text-sm mt-1">
                Changes will sync when you reconnect
                {queueStatus.pending > 0 && (
                  <span className="ml-2 font-medium">
                    • {queueStatus.pending} queued
                  </span>
                )}
              </div>
            </div>
            {showDetailed && queueStatus.pending > 0 && (
              <Button
                size="sm"
                variant="outline"
                onClick={() => toast.info('Changes will sync automatically when online')}
                className="ml-2"
              >
                View Queue
              </Button>
            )}
          </AlertDescription>
        </>
      ) : isSyncing ? (
        <>
          <RefreshCw className="h-4 w-4 animate-spin" />
          <AlertDescription>
            <strong>Syncing changes...</strong>
            <span className="ml-2 text-sm">
              {queueStatus.pending} remaining
            </span>
          </AlertDescription>
        </>
      ) : queueStatus.failed > 0 ? (
        <>
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription className="flex items-center justify-between">
            <div>
              <strong>Sync issues detected</strong>
              <div className="text-sm mt-1">
                {queueStatus.failed} changes failed to sync
              </div>
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={handleManualSync}
              disabled={isSyncing}
              className="ml-2"
            >
              Retry
            </Button>
          </AlertDescription>
        </>
      ) : queueStatus.pending > 0 ? (
        <>
          <RefreshCw className="h-4 w-4" />
          <AlertDescription className="flex items-center justify-between">
            <div>
              <strong>Ready to sync</strong>
              <div className="text-sm mt-1">
                {queueStatus.pending} changes pending
              </div>
            </div>
            <Button
              size="sm"
              onClick={handleManualSync}
              disabled={isSyncing}
              className="ml-2"
            >
              Sync Now
            </Button>
          </AlertDescription>
        </>
      ) : null}
    </Alert>
  );
}
