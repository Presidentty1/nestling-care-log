import type { SubscriptionStatus } from './stripeService';
import { stripeService } from './stripeService';
import { supabase } from '@/integrations/supabase/client';

export interface SubscriptionLimits {
  aiPredictions: number;
  cryAnalysis: number;
  aiAssistant: number;
}

export class SubscriptionService {
  private static readonly LIMITS = {
    free: {
      aiPredictions: 0, // Unlimited for now to drive conversion
      cryAnalysis: 2, // 2 per week
      aiAssistant: 5, // 5 per day
    },
    premium: {
      aiPredictions: -1, // Unlimited
      cryAnalysis: -1, // Unlimited
      aiAssistant: -1, // Unlimited
    },
  } as const;

  /**
   * Check if user has premium subscription
   */
  async isPremium(userId: string): Promise<boolean> {
    const status = await stripeService.getSubscriptionStatus(userId);
    return status?.tier === 'premium';
  }

  /**
   * Get subscription status
   */
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatus | null> {
    return await stripeService.getSubscriptionStatus(userId);
  }

  /**
   * Get trial days remaining
   */
  async getTrialDaysRemaining(userId: string): Promise<number | null> {
    const status = await stripeService.getSubscriptionStatus(userId);
    if (!status?.trialEnd) return null;

    const trialEnd = new Date(status.trialEnd);
    const now = new Date();
    const daysRemaining = Math.ceil((trialEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

    return Math.max(0, daysRemaining);
  }

  /**
   * Check if feature is accessible
   */
  async canAccessFeature(feature: keyof SubscriptionLimits, userId: string): Promise<boolean> {
    const isPremium = await this.isPremium(userId);

    if (isPremium) return true;

    // For free users, check usage limits
    const limits = SubscriptionService.LIMITS.free;
    const limit = limits[feature];

    if (limit === -1) return true; // Unlimited
    if (limit === 0) return false; // Not allowed

    // Check actual usage based on feature
    const usage = await this.getFeatureUsage(feature, userId);
    return usage < limit;
  }

  /**
   * Get feature usage for current period
   */
  private async getFeatureUsage(
    feature: keyof SubscriptionLimits,
    userId: string
  ): Promise<number> {
    const now = new Date();
    let startDate: Date;

    switch (feature) {
      case 'cryAnalysis':
        // Weekly limit - start of current week
        startDate = new Date(now);
        startDate.setDate(now.getDate() - now.getDay());
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'aiAssistant':
        // Daily limit - start of current day
        startDate = new Date(now);
        startDate.setHours(0, 0, 0, 0);
        break;
      default:
        // Monthly limit for other features
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    }

    try {
      switch (feature) {
        case 'cryAnalysis': {
          const { count: cryCount } = await supabase
            .from('cry_insight_sessions')
            .select('*', { count: 'exact', head: true })
            .eq('created_by', userId)
            .gte('created_at', startDate.toISOString());
          return cryCount || 0;
        }

        case 'aiAssistant': {
          // For AI assistant, we need to track conversations
          const { count: chatCount } = await supabase
            .from('ai_conversations')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .gte('created_at', startDate.toISOString());
          return chatCount || 0;
        }

        case 'aiPredictions': {
          // For nap predictions, count generated predictions
          const { count: predictionCount } = await supabase
            .from('predictions')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .gte('created_at', startDate.toISOString());
          return predictionCount || 0;
        }

        default:
          return 0;
      }
    } catch (error) {
      console.error('Error checking feature usage:', error);
      return 0; // Default to 0 on error to be permissive
    }
  }

  /**
   * Create checkout session
   */
  async createCheckoutSession(priceId: string, userId: string) {
    return await stripeService.createCheckoutSession(priceId, userId);
  }

  /**
   * Create portal session
   */
  async createPortalSession(userId: string) {
    return await stripeService.createPortalSession(userId);
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(userId: string): Promise<boolean> {
    return await stripeService.cancelSubscription(userId);
  }

  /**
   * Reactivate subscription
   */
  async reactivateSubscription(userId: string): Promise<boolean> {
    return await stripeService.reactivateSubscription(userId);
  }

  /**
   * Get limits for current user
   */
  async getLimits(userId: string): Promise<SubscriptionLimits> {
    const isPremium = await this.isPremium(userId);
    return isPremium ? SubscriptionService.LIMITS.premium : SubscriptionService.LIMITS.free;
  }
}

export const subscriptionService = new SubscriptionService();
export default subscriptionService;

