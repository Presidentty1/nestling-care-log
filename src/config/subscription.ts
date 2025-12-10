export const PRICING = {
  monthly: {
    priceId: 'price_monthly_premium', // Replace with actual Stripe price ID
    amount: 5.99,
    currency: 'USD',
    interval: 'month',
  },
  yearly: {
    priceId: 'price_yearly_premium', // Replace with actual Stripe price ID
    amount: 39.99,
    currency: 'USD',
    interval: 'year',
    savings: '30%', // Compared to monthly
  },
  trialDays: 7,
} as const;

export const FEATURES = {
  free: [
    'Unlimited event logging',
    'Timeline & history view',
    'Multi-device sync',
    'Basic analytics',
  ],
  premium: [
    'AI Nap Predictor (unlimited)',
    'AI Cry Analysis (unlimited)',
    'Smart reminders',
    'AI Assistant chat (unlimited)',
    'Weekly insights reports',
    'Growth tracking',
    'Priority support',
  ],
} as const;

export type SubscriptionTier = 'free' | 'premium';
export type BillingInterval = 'month' | 'year';
