import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';
import { GrowthRecord } from '@/lib/types';

class GrowthRecordsService {
  async getGrowthRecords(babyId: string): Promise<GrowthRecord[]> {
    const { data, error } = await supabase
      .from('growth_records')
      .select('*')
      .eq('baby_id', babyId)
      .order('recorded_at', { ascending: false });

    if (error) throw error;
    return (data || []) as GrowthRecord[];
  }

  async getGrowthRecord(id: string): Promise<GrowthRecord | null> {
    const { data, error } = await supabase
      .from('growth_records')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as GrowthRecord;
  }

  async createGrowthRecord(record: Omit<GrowthRecord, 'id' | 'created_at' | 'updated_at'>): Promise<GrowthRecord> {
    const { data: { user } } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    const recordData = {
      ...record,
      recorded_by: user.id,
    };

    const { data, error } = await supabase
      .from('growth_records')
      .insert(recordData)
      .select('*')
      .single();

    if (error) throw error;
    return data as GrowthRecord;
  }

  async updateGrowthRecord(id: string, updates: Partial<GrowthRecord>): Promise<GrowthRecord> {
    const { data, error } = await supabase
      .from('growth_records')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data as GrowthRecord;
  }

  async deleteGrowthRecord(id: string): Promise<void> {
    const { error } = await supabase
      .from('growth_records')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const growthRecordsService = new GrowthRecordsService();


