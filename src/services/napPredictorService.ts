import { supabase } from '@/integrations/supabase/client';

export interface NapPrediction {
  napWindowStart: Date;
  napWindowEnd: Date;
  confidence: 'high' | 'medium' | 'low';
  explanation: string;
  lastWakeTime?: Date;
}

class NapPredictorService {
  async calculateNapWindow(babyId: string): Promise<unknown> {
    const { data, error } = await supabase.functions.invoke('calculate-nap-window', {
      body: { babyId }
    });

    if (error) throw error;
    return data;
  }
}

export const napPredictorService = new NapPredictorService();
