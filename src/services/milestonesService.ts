import { supabase } from '@/integrations/supabase/client';
import type { Milestone } from '@/lib/types';

class MilestonesService {
  async getMilestones(babyId: string): Promise<Milestone[]> {
    const { data, error } = await supabase
      .from('milestones')
      .select('*')
      .eq('baby_id', babyId)
      .order('achieved_date', { ascending: false });

    if (error) throw error;
    return (data || []) as Milestone[];
  }

  async getMilestone(id: string): Promise<Milestone | null> {
    const { data, error } = await supabase
      .from('milestones')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as Milestone;
  }

  async createMilestone(milestone: Omit<Milestone, 'id' | 'created_at' | 'updated_at'>): Promise<Milestone> {
    const { data, error } = await supabase
      .from('milestones')
      .insert(milestone)
      .select('*')
      .single();

    if (error) throw error;
    return data as Milestone;
  }

  async updateMilestone(id: string, updates: Partial<Milestone>): Promise<Milestone> {
    const { data, error } = await supabase
      .from('milestones')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data as Milestone;
  }

  async deleteMilestone(id: string): Promise<void> {
    const { error } = await supabase
      .from('milestones')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const milestonesService = new MilestonesService();


