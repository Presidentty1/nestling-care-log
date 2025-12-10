import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';

export interface ReferralCode {
  id: string;
  user_id: string;
  code: string;
  uses_count: number;
  created_at: string;
}

class ReferralsService {
  async getOrCreateReferralCode(): Promise<ReferralCode> {
    const {
      data: { user },
    } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    let { data: existing } = await supabase
      .from('referral_codes')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (!existing) {
      const code = `NEST-${Math.random().toString(36).substr(2, 8).toUpperCase()}`;
      const { data: created, error } = await supabase
        .from('referral_codes')
        .insert({ user_id: user.id, code })
        .select()
        .single();

      if (error) throw error;
      existing = created;
    }

    return existing as ReferralCode;
  }

  async getReferralCode(userId: string): Promise<ReferralCode | null> {
    const { data, error } = await supabase
      .from('referral_codes')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data as ReferralCode;
  }
}

export const referralsService = new ReferralsService();

