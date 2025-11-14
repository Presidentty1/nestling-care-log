import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { BabyEvent, EventType } from '@/lib/types';
import { toast } from 'sonner';
import { useQueryClient } from '@tanstack/react-query';

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
      const { data, error } = await supabase
        .from('events')
        .insert({
          ...eventData,
          created_by: (await supabase.auth.getUser()).data.user?.id,
        })
        .select()
        .single();

      if (error) throw error;

      toast.success('Event logged successfully');
      queryClient.invalidateQueries({ queryKey: ['events'] });
      return data;
    } catch (error: any) {
      console.error('Error creating event:', error);
      toast.error(error.message || 'Failed to log event');
      throw error;
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

      toast.success('Event updated');
      queryClient.invalidateQueries({ queryKey: ['events'] });
      return data;
    } catch (error: any) {
      console.error('Error updating event:', error);
      toast.error(error.message || 'Failed to update event');
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

      toast.success('Event deleted');
      queryClient.invalidateQueries({ queryKey: ['events'] });
    } catch (error: any) {
      console.error('Error deleting event:', error);
      toast.error(error.message || 'Failed to delete event');
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
