import { useEffect, useState } from 'react';
import { dataService } from '@/services/dataService';
import { supabase } from '@/integrations/supabase/client';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { toast } from 'sonner';

export function useEventSync(babyId: string) {
  const { isOnline } = useNetworkStatus();
  const [isSyncing, setIsSyncing] = useState(false);
  const [pendingCount, setPendingCount] = useState(0);
  
  useEffect(() => {
    updatePendingCount();
  }, [babyId]);
  
  useEffect(() => {
    if (isOnline && pendingCount > 0 && !isSyncing) {
      syncToSupabase();
    }
  }, [isOnline, pendingCount]);
  
  const updatePendingCount = async () => {
    const events = await dataService.listEventsRange(
      babyId,
      new Date(0).toISOString(),
      new Date().toISOString()
    );
    const unsynced = events.filter(e => e.source === 'local' && !e.syncedAt);
    setPendingCount(unsynced.length);
  };
  
  const syncToSupabase = async () => {
    setIsSyncing(true);
    
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
        }
      }
      
      if (unsyncedEvents.length > 0) {
        toast.success(`Synced ${unsyncedEvents.length} events`);
      }
      await updatePendingCount();
    } catch (error) {
      console.error('Sync failed:', error);
    } finally {
      setIsSyncing(false);
    }
  };
  
  return { isSyncing, pendingCount, syncToSupabase };
}
