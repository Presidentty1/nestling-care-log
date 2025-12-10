import { supabase } from '@/integrations/supabase/client';

export interface WeeklySummary {
  id: string;
  baby_id: string;
  week_start: string;
  week_end: string;
  summary_data: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

class WeeklySummariesService {
  async getSummaries(babyId: string, limit = 10): Promise<WeeklySummary[]> {
    const { data, error } = await supabase
      .from('weekly_summaries')
      .select('*')
      .eq('baby_id', babyId)
      .order('week_start', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async generateSummary(babyId: string, weekStart: string): Promise<unknown> {
    const { data, error } = await supabase.functions.invoke('generate-weekly-summary', {
      body: {
        babyId,
        weekStart: weekStart.split('T')[0],
      },
    });

    if (error) throw error;
    return data;
  }
}

export const weeklySummariesService = new WeeklySummariesService();
