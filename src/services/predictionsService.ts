import { supabase } from '@/integrations/supabase/client';
import type { DbBaby } from '@/types/db';

export interface Prediction {
  id: string;
  baby_id: string;
  prediction_type: string;
  predicted_at: string;
  confidence_score: number;
  prediction_data: Record<string, unknown>;
  was_accurate?: boolean | null;
  created_at: string;
  updated_at: string;
}

class PredictionsService {
  async getPredictions(babyId: string, limit = 10): Promise<Prediction[]> {
    const { data, error } = await supabase
      .from('predictions')
      .select('*')
      .eq('baby_id', babyId)
      .order('predicted_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async generatePrediction(babyId: string, predictionType: string): Promise<unknown> {
    const { data, error } = await supabase.functions.invoke('generate-predictions', {
      body: { babyId, predictionType },
    });

    if (error) {
      // Handle specific error cases
      if (error.message?.includes('404') || error.message?.includes('FunctionsRelayError')) {
        throw new Error('FUNCTION_NOT_FOUND');
      }
      throw error;
    }

    if (!data) {
      throw new Error('No data returned from prediction service');
    }

    return data;
  }
}

export const predictionsService = new PredictionsService();
