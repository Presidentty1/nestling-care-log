import { supabase } from '@/integrations/supabase/client';

export interface SubscriptionStatus {
  isPro: boolean;
  status: 'active' | 'trialing' | 'past_due' | 'canceled' | 'incomplete' | null;
  currentPeriodEnd: Date | null;
}

class ProService {
  /**
   * Check if user has an active Pro subscription
   */
  async isPro(): Promise<boolean> {
    const status = await this.getSubscriptionStatus();
    return status.isPro;
  }

  /**
   * Get detailed subscription status
   */
  async getSubscriptionStatus(): Promise<SubscriptionStatus> {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        return { isPro: false, status: null, currentPeriodEnd: null };
      }

      const { data: subscription } = await supabase
        .from('subscriptions')
        .select('status, current_period_end')
        .eq('user_id', user.id)
        .maybeSingle();

      if (!subscription) {
        return { isPro: false, status: null, currentPeriodEnd: null };
      }

      const isActive = ['active', 'trialing'].includes(subscription.status);
      const currentPeriodEnd = subscription.current_period_end
        ? new Date(subscription.current_period_end)
        : null;

      return {
        isPro: isActive,
        status: subscription.status as any,
        currentPeriodEnd,
      };
    } catch (error) {
      console.error('Error checking Pro status:', error);
      return { isPro: false, status: null, currentPeriodEnd: null };
    }
  }

  /**
   * Check if a feature requires Pro and if user has access
   */
  async canAccessFeature(
    feature: 'caregiver_invites' | 'ai_features' | 'csv_export' | 'advanced_analytics'
  ): Promise<boolean> {
    // For now, all Pro features require subscription
    // In the future, we might have different tiers
    return await this.isPro();
  }
}

export const proService = new ProService();
