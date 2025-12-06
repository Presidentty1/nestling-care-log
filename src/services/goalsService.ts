import { supabase } from '@/integrations/supabase/client';

export interface Goal {
  id: string;
  baby_id: string;
  goal_type: string;
  title: string;
  target_value?: number | null;
  target_unit?: string | null;
  target_date?: string | null;
  notes?: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

class GoalsService {
  async getGoals(babyId: string): Promise<Goal[]> {
    const { data, error } = await supabase
      .from('goals')
      .select('*')
      .eq('baby_id', babyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async createGoal(data: Omit<Goal, 'id' | 'created_at' | 'updated_at'>): Promise<Goal> {
    const { data: result, error } = await supabase
      .from('goals')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async updateGoal(id: string, data: Partial<Goal>): Promise<Goal> {
    const { data: result, error } = await supabase
      .from('goals')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async deleteGoal(id: string): Promise<void> {
    const { error } = await supabase
      .from('goals')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const goalsService = new GoalsService();
