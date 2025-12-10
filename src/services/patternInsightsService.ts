import { supabase } from '@/integrations/supabase/client';

export interface PatternInsight {
  id: string;
  baby_id: string;
  pattern_type: string;
  detected_at: string;
  confidence: number;
  insight_data: Record<string, unknown>;
  acknowledged_at?: string | null;
  created_at: string;
  updated_at: string;
}

export interface CorrelationAnalysis {
  id: string;
  baby_id: string;
  correlation_type: string;
  strength: number;
  analysis_data: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

class PatternInsightsService {
  async getPatternInsights(babyId: string, acknowledgedOnly = false): Promise<PatternInsight[]> {
    let query = supabase
      .from('pattern_insights')
      .select('*')
      .eq('baby_id', babyId)
      .order('detected_at', { ascending: false });

    if (acknowledgedOnly) {
      query = query.not('acknowledged_at', 'is', null);
    } else {
      query = query.is('acknowledged_at', null);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  async acknowledgeInsight(id: string): Promise<void> {
    const { error } = await supabase
      .from('pattern_insights')
      .update({ acknowledged_at: new Date().toISOString() })
      .eq('id', id);

    if (error) throw error;
  }

  async getCorrelations(babyId: string, limit = 5): Promise<CorrelationAnalysis[]> {
    const { data, error } = await supabase
      .from('correlation_analysis')
      .select('*')
      .eq('baby_id', babyId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async getBehaviorPatterns(babyId: string): Promise<unknown[]> {
    const { data, error } = await supabase
      .from('behavior_patterns')
      .select('*')
      .eq('baby_id', babyId)
      .order('detected_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }
}

export const patternInsightsService = new PatternInsightsService();


