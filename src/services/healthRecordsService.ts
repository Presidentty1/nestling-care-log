import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';
import { HealthRecord, HealthRecordType } from '@/lib/types';

class HealthRecordsService {
  async getHealthRecords(babyId: string): Promise<HealthRecord[]> {
    const { data, error } = await supabase
      .from('health_records')
      .select('*')
      .eq('baby_id', babyId)
      .order('recorded_at', { ascending: false });

    if (error) throw error;
    return (data || []) as HealthRecord[];
  }

  async getHealthRecord(id: string): Promise<HealthRecord | null> {
    const { data, error } = await supabase
      .from('health_records')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as HealthRecord;
  }

  async createHealthRecord(record: Omit<HealthRecord, 'id' | 'created_at' | 'updated_at'>): Promise<HealthRecord> {
    const { data: { user } } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    const recordData = {
      ...record,
      created_by: user.id,
    };

    const { data, error } = await supabase
      .from('health_records')
      .insert(recordData)
      .select('*')
      .single();

    if (error) throw error;
    return data as HealthRecord;
  }

  async updateHealthRecord(id: string, updates: Partial<HealthRecord>): Promise<HealthRecord> {
    const { data, error } = await supabase
      .from('health_records')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data as HealthRecord;
  }

  async deleteHealthRecord(id: string): Promise<void> {
    const { error } = await supabase
      .from('health_records')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const healthRecordsService = new HealthRecordsService();


