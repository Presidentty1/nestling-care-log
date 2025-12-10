import { useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

export function useRealtimeEvents(familyId: string | undefined, onUpdate: () => void) {
  useEffect(() => {
    if (!familyId) return;

    const channel = supabase
      .channel(`events-${familyId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'events',
          filter: `family_id=eq.${familyId}`,
        },
        payload => {
          console.log('Realtime event update:', payload);
          onUpdate();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [familyId, onUpdate]);
}
