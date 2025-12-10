import { supabase } from '@/integrations/supabase/client';

export interface CryLog {
  id: string;
  baby_id: string;
  start_time: string;
  end_time?: string | null;
  cry_type?: string | null;
  confidence?: number | null;
  resolved_by?: string | null;
  note?: string | null;
  created_at: string;
  updated_at: string;
}

class CryLogsService {
  async getCryLogs(babyId: string, limit = 20): Promise<CryLog[]> {
    const { data, error } = await supabase
      .from('cry_logs')
      .select('*')
      .eq('baby_id', babyId)
      .order('start_time', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async createCryLog(babyId: string, data: Partial<CryLog>): Promise<CryLog> {
    const { data: result, error } = await supabase
      .from('cry_logs')
      .insert({
        baby_id: babyId,
        ...data,
      })
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async updateCryLog(id: string, data: Partial<CryLog>): Promise<CryLog> {
    const { data: result, error } = await supabase
      .from('cry_logs')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return result;
  }
}

export const cryLogsService = new CryLogsService();

