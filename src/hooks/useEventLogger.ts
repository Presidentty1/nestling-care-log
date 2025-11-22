import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { EventType } from '@/lib/types';
import { BabyEvent } from '@/lib/types';
import { toast } from 'sonner';
import { useQueryClient } from '@tanstack/react-query';
import { offlineQueue } from '@/lib/offlineQueue';

interface CreateEventData {
  baby_id: string;
  family_id: string;
  type: EventType;
  subtype?: string;
  start_time: string;
  end_time?: string;
  amount?: number;
  unit?: string;
  note?: string;
}

export function useEventLogger() {
  const [isLoading, setIsLoading] = useState(false);
  const queryClient = useQueryClient();

  const createEvent = async (eventData: CreateEventData) => {
    setIsLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      const eventWithUser = {
        ...eventData,
        created_by: user?.id,
      };

      const { data, error } = await supabase
        .from('events')
        .insert(eventWithUser)
        .select()
        .single();

      if (error) {
        // Queue for offline sync
        console.log('Queueing event for offline sync:', error);
        offlineQueue.enqueue({
          type: 'create',
          table: 'events',
          data: eventWithUser,
        });
        toast.info('Event saved offline, will sync when online');
        return null;
      }

      toast.success('Logged!');
      queryClient.invalidateQueries({ queryKey: ['events'] });
      return data;
    } catch (error: any) {
      console.error('Error creating event:', error);
      // Queue for offline sync on network error
      const { data: { user } } = await supabase.auth.getUser();
      offlineQueue.enqueue({
        type: 'create',
        table: 'events',
        data: {
          ...eventData,
          created_by: user?.id,
        },
      });
      toast.info('Saved offline, will sync when connected');
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  const updateEvent = async (id: string, updates: Partial<CreateEventData>) => {
    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from('events')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      toast.success('Updated!');
      queryClient.invalidateQueries({ queryKey: ['events'] });
      return data;
    } catch (error: any) {
      console.error('Error updating event:', error);
      toast.error("Couldn't save changes. Try again?");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const deleteEvent = async (id: string) => {
    setIsLoading(true);
    try {
      const { error } = await supabase.from('events').delete().eq('id', id);

      if (error) throw error;

      toast.success('Removed!');
      queryClient.invalidateQueries({ queryKey: ['events'] });
    } catch (error: any) {
      console.error('Error deleting event:', error);
      toast.error("Couldn't remove that. Try again?");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const getActiveTimer = async (babyId: string) => {
    try {
      const { data, error } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', babyId)
        .is('end_time', null)
        .in('type', ['sleep', 'feed'])
        .order('start_time', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error getting active timer:', error);
      return null;
    }
  };

  return {
    createEvent,
    updateEvent,
    deleteEvent,
    getActiveTimer,
    isLoading,
  };
}
