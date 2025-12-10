import { useEffect, useState } from 'react';
import { dataService } from '@/services/dataService';
import { supabase } from '@/integrations/supabase/client';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { toast } from 'sonner';

const SYNC_HISTORY_KEY = 'nestling_sync_history';

interface SyncHistoryItem {
  timestamp: string;
  count: number;
  success: boolean;
}

export function useEventSync(babyId: string) {
  const { isOnline } = useNetworkStatus();
  const [isSyncing, setIsSyncing] = useState(false);
  const [pendingCount, setPendingCount] = useState(0);
  const [pendingByType, setPendingByType] = useState<Record<string, number>>({});
  const [lastSyncTime, setLastSyncTime] = useState<string | undefined>();
  const [failedCount, setFailedCount] = useState(0);
  const [syncHistory, setSyncHistory] = useState<SyncHistoryItem[]>([]);

  useEffect(() => {
    loadSyncHistory();
    updatePendingCount();
  }, [babyId]);

  useEffect(() => {
    if (isOnline && pendingCount > 0 && !isSyncing) {
      syncToSupabase();
    }
  }, [isOnline, pendingCount]);

  const loadSyncHistory = () => {
    const history = localStorage.getItem(SYNC_HISTORY_KEY);
    if (history) {
      setSyncHistory(JSON.parse(history));
    }
  };

  const addToSyncHistory = (count: number, success: boolean) => {
    const newItem: SyncHistoryItem = {
      timestamp: new Date().toISOString(),
      count,
      success,
    };
    const updated = [newItem, ...syncHistory].slice(0, 10);
    setSyncHistory(updated);
    localStorage.setItem(SYNC_HISTORY_KEY, JSON.stringify(updated));
    if (success) {
      setLastSyncTime(newItem.timestamp);
    }
  };

  const updatePendingCount = async () => {
    const events = await dataService.listEventsRange(
      babyId,
      new Date(0).toISOString(),
      new Date().toISOString()
    );
    const unsynced = events.filter(e => e.source === 'local' && !e.syncedAt);
    setPendingCount(unsynced.length);

    // Count by type
    const byType: Record<string, number> = {};
    unsynced.forEach(event => {
      byType[event.type] = (byType[event.type] || 0) + 1;
    });
    setPendingByType(byType);
  };

  const syncToSupabase = async () => {
    setIsSyncing(true);
    let failed = 0;

    try {
      const localEvents = await dataService.listEventsRange(
        babyId,
        new Date(0).toISOString(),
        new Date().toISOString()
      );

      const unsyncedEvents = localEvents.filter(e => e.source === 'local' && !e.syncedAt);

      for (const event of unsyncedEvents) {
        const { error } = await supabase.from('events').insert({
          id: event.id,
          baby_id: event.babyId,
          family_id: event.familyId,
          type: event.type,
          subtype: event.subtype,
          start_time: event.startTime,
          end_time: event.endTime,
          amount: event.amount,
          unit: event.unit,
          note: event.notes,
        });

        if (!error) {
          await dataService.updateEvent(event.id, {
            source: 'sync',
            syncedAt: new Date().toISOString(),
          });
        } else {
          failed++;
        }
      }

      setFailedCount(failed);
      addToSyncHistory(unsyncedEvents.length - failed, failed === 0);

      if (unsyncedEvents.length > 0) {
        toast.success(`Synced ${unsyncedEvents.length - failed} events`);
      }
      await updatePendingCount();
    } catch (error) {
      console.error('Sync failed:', error);
      addToSyncHistory(0, false);
    } finally {
      setIsSyncing(false);
    }
  };

  const forceSyncNow = async () => {
    if (!isOnline) {
      toast.error('Cannot sync while offline');
      return;
    }
    await syncToSupabase();
  };

  return {
    isSyncing,
    pendingCount,
    pendingByType,
    lastSyncTime,
    failedCount,
    syncHistory,
    syncToSupabase,
    forceSyncNow,
  };
}
