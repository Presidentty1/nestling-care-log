import { supabase } from '@/integrations/supabase/client';
import { format } from 'date-fns';

export interface ParentWellnessLog {
  id: string;
  user_id: string;
  log_date: string;
  mood?: string | null;
  water_intake_ml?: number | null;
  sleep_quality?: string | null;
  created_at: string;
  updated_at: string;
}

export interface ParentMedication {
  id: string;
  user_id: string;
  name: string;
  dosage?: string | null;
  frequency?: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

class ParentWellnessService {
  async getTodayLog(userId: string, date: Date): Promise<ParentWellnessLog | null> {
    const dateStr = format(date, 'yyyy-MM-dd');
    const { data, error } = await supabase
      .from('parent_wellness_logs')
      .select('*')
      .eq('user_id', userId)
      .eq('log_date', dateStr)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') throw error;
    return data;
  }

  async upsertLog(data: Omit<ParentWellnessLog, 'id' | 'created_at' | 'updated_at'>): Promise<ParentWellnessLog> {
    const { data: result, error } = await supabase
      .from('parent_wellness_logs')
      .upsert(data, {
        onConflict: 'user_id,log_date',
      })
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async getActiveMedications(userId: string): Promise<ParentMedication[]> {
    const { data, error } = await supabase
      .from('parent_medications')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async createMedication(data: Omit<ParentMedication, 'id' | 'created_at' | 'updated_at'>): Promise<ParentMedication> {
    const { data: result, error } = await supabase
      .from('parent_medications')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async updateMedication(id: string, data: Partial<ParentMedication>): Promise<ParentMedication> {
    const { data: result, error } = await supabase
      .from('parent_medications')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return result;
  }
}

export const parentWellnessService = new ParentWellnessService();


