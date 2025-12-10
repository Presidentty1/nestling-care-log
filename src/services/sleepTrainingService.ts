import { supabase } from '@/integrations/supabase/client';

export interface SleepTrainingSession {
  id: string;
  baby_id: string;
  method: string;
  start_date: string;
  target_bedtime?: string | null;
  target_wake_time?: string | null;
  check_intervals?: number[] | null;
  notes?: string | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface SleepRegression {
  id: string;
  baby_id: string;
  regression_type?: string | null;
  severity?: string | null;
  detected_at: string;
  resolved_at?: string | null;
  created_at: string;
  updated_at: string;
}

class SleepTrainingService {
  async getSessions(babyId: string): Promise<SleepTrainingSession[]> {
    const { data, error } = await supabase
      .from('sleep_training_sessions')
      .select('*')
      .eq('baby_id', babyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getSession(id: string): Promise<SleepTrainingSession | null> {
    const { data, error } = await supabase
      .from('sleep_training_sessions')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  async createSession(
    data: Omit<SleepTrainingSession, 'id' | 'created_at' | 'updated_at'>
  ): Promise<SleepTrainingSession> {
    const { data: result, error } = await supabase
      .from('sleep_training_sessions')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async updateSession(
    id: string,
    data: Partial<SleepTrainingSession>
  ): Promise<SleepTrainingSession> {
    const { data: result, error } = await supabase
      .from('sleep_training_sessions')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async getRegressions(babyId: string): Promise<SleepRegression[]> {
    const { data, error } = await supabase
      .from('sleep_regressions')
      .select('*')
      .eq('baby_id', babyId)
      .order('detected_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }
}

export const sleepTrainingService = new SleepTrainingService();
