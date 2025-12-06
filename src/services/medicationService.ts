import { supabase } from '@/integrations/supabase/client';
import type { Medication } from '@/lib/types';

class MedicationService {
  async getMedications(babyId: string): Promise<Medication[]> {
    const { data, error } = await supabase
      .from('medications')
      .select('*')
      .eq('baby_id', babyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as Medication[];
  }

  async createMedication(data: Omit<Medication, 'id' | 'created_at' | 'updated_at'>): Promise<Medication> {
    const { data: result, error } = await supabase
      .from('medications')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result as Medication;
  }

  async updateMedication(id: string, data: Partial<Medication>): Promise<Medication> {
    const { data: result, error } = await supabase
      .from('medications')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return result as Medication;
  }

  async deleteMedication(id: string): Promise<void> {
    const { error } = await supabase
      .from('medications')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const medicationService = new MedicationService();
