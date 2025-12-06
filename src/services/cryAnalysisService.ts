import { supabase } from '@/integrations/supabase/client';

class CryAnalysisService {
  async analyzeCryPattern(params: {
    babyId: string;
    recentEvents: unknown[];
    timeOfDay: number;
    timeSinceLastFeed: number;
    lastSleepDuration: number;
  }): Promise<unknown> {
    const { data, error } = await supabase.functions.invoke('analyze-cry-pattern', {
      body: params,
    });

    if (error) throw error;
    return data;
  }
}

export const cryAnalysisService = new CryAnalysisService();
