import type { Stripe } from '@stripe/stripe-js';
import { loadStripe, StripeElements } from '@stripe/stripe-js';
import { supabase } from '@/integrations/supabase/client';

// Initialize Stripe with publishable key
const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || '');

export interface SubscriptionStatus {
  tier: 'free' | 'premium';
  status: string;
  currentPeriodEnd?: string;
  trialEnd?: string;
  cancelAtPeriodEnd?: boolean;
}

class StripeService {
  private stripe: Promise<Stripe | null>;

  constructor() {
    this.stripe = stripePromise;
  }

  /**
   * Create a checkout session for subscription
   */
  async createCheckoutSession(priceId: string, userId: string): Promise<{ url: string } | null> {
    try {
      const { data, error } = await supabase.functions.invoke('stripe-create-checkout', {
        body: {
          priceId,
          userId,
          successUrl: `${window.location.origin}/subscription/success`,
          cancelUrl: `${window.location.origin}/subscription/cancel`,
        },
      });

      if (error) {
        console.error('Failed to create checkout session:', error);
        throw error;
      }

      return data;
    } catch (error) {
      console.error('Stripe checkout error:', error);
      return null;
    }
  }

  /**
   * Create a customer portal session for subscription management
   */
  async createPortalSession(userId: string): Promise<{ url: string } | null> {
    try {
      const { data, error } = await supabase.functions.invoke('stripe-create-portal', {
        body: {
          userId,
          returnUrl: `${window.location.origin}/settings`,
        },
      });

      if (error) {
        console.error('Failed to create portal session:', error);
        throw error;
      }

      return data;
    } catch (error) {
      console.error('Stripe portal error:', error);
      return null;
    }
  }

  /**
   * Get subscription status from database
   */
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatus | null> {
    try {
      const { data, error } = await supabase.rpc('check_subscription_status', {
        user_uuid: userId,
      });

      if (error) {
        console.error('Failed to check subscription status:', error);
        return null;
      }

      // Get detailed subscription info
      const { data: subscription, error: subError } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (subError && subError.code !== 'PGRST116') {
        // PGRST116 is "no rows returned"
        console.error('Failed to fetch subscription details:', subError);
        return { tier: data as 'free' | 'premium' };
      }

      return {
        tier: data as 'free' | 'premium',
        status: subscription?.status || 'none',
        currentPeriodEnd: subscription?.current_period_end,
        trialEnd: subscription?.trial_end,
        cancelAtPeriodEnd: subscription?.cancel_at_period_end,
      };
    } catch (error) {
      console.error('Subscription status check error:', error);
      return null;
    }
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(userId: string): Promise<boolean> {
    try {
      const { error } = await supabase.functions.invoke('stripe-cancel-subscription', {
        body: { userId },
      });

      if (error) {
        console.error('Failed to cancel subscription:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Cancel subscription error:', error);
      return false;
    }
  }

  /**
   * Reactivate subscription
   */
  async reactivateSubscription(userId: string): Promise<boolean> {
    try {
      const { error } = await supabase.functions.invoke('stripe-reactivate-subscription', {
        body: { userId },
      });

      if (error) {
        console.error('Failed to reactivate subscription:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Reactivate subscription error:', error);
      return false;
    }
  }

  /**
   * Get Stripe instance
   */
  async getStripe(): Promise<Stripe | null> {
    return await this.stripe;
  }
}

export const stripeService = new StripeService();
export default stripeService;

