import { supabase } from '@/integrations/supabase/client';

export interface NapFeedback {
  id: string;
  baby_id: string;
  predicted_start: string;
  predicted_end: string;
  rating: 'too_early' | 'just_right' | 'too_late';
  created_at: string;
  updated_at: string;
}

class NapFeedbackService {
  async createFeedback(data: Omit<NapFeedback, 'id' | 'created_at' | 'updated_at'>): Promise<NapFeedback> {
    const { data: result, error } = await supabase
      .from('nap_feedback')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result;
  }

  async getFeedback(babyId: string, limit = 50): Promise<NapFeedback[]> {
    const { data, error } = await supabase
      .from('nap_feedback')
      .select('*')
      .eq('baby_id', babyId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }
}

export const napFeedbackService = new NapFeedbackService();


