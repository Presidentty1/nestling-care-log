import { track } from '@/analytics/analytics';

export interface PaywallVariant {
  id: string;
  name: string;
  headline: string;
  subheadline: string;
  pricing: {
    yearly: string;
    monthly: string;
    lifetime: string;
  };
  features: Array<{
    title: string;
    description: string;
    icon: string;
  }>;
  socialProof: string;
  ctaText: string;
  backgroundColor: string;
}

const PAYWALL_VARIANTS: PaywallVariant[] = [
  {
    id: 'control',
    name: 'Control',
    headline: 'Unlock Nestling Pro',
    subheadline: 'Advanced features for confident parenting',
    pricing: {
      yearly: '$39.99/yr',
      monthly: '$4.99/mo',
      lifetime: '$79.99 lifetime'
    },
    features: [
      {
        title: 'Personalized predictions',
        description: 'Nap & feed predictions tuned to your baby',
        icon: '🧠'
      },
      {
        title: 'Weekly patterns',
        description: 'See sleep and feeding trends at a glance',
        icon: '📊'
      },
      {
        title: 'Doctor reports',
        description: 'Share detailed summaries with pediatricians',
        icon: '👨‍⚕️'
      },
      {
        title: 'Cry Insights',
        description: 'AI-powered cry analysis when you need help',
        icon: '👶'
      }
    ],
    socialProof: 'Join 10,000+ parents',
    ctaText: 'Start Free Trial',
    backgroundColor: 'from-primary/10 via-primary/5 to-background'
  },
  {
    id: 'urgency',
    name: 'Urgency',
    headline: 'Don\'t miss out on Pro features',
    subheadline: 'Limited time: First month free',
    pricing: {
      yearly: '$39.99/yr (save 25%)',
      monthly: '$4.99/mo',
      lifetime: '$79.99 lifetime'
    },
    features: [
      {
        title: 'Smart predictions',
        description: 'AI learns your baby\'s unique patterns',
        icon: '🤖'
      },
      {
        title: 'Data insights',
        description: 'Track growth, sleep quality, and more',
        icon: '📈'
      },
      {
        title: 'Team coordination',
        description: 'Share with partner, nanny, and doctor',
        icon: '👨‍👩‍👧'
      },
      {
        title: 'Peace of mind',
        description: 'Expert AI support when you\'re unsure',
        icon: '🛡️'
      }
    ],
    socialProof: '⭐⭐⭐⭐⭐ "Changed how I parent" - Sarah M.',
    ctaText: 'Claim Free Month',
    backgroundColor: 'from-orange-500/10 via-orange-500/5 to-background'
  },
  {
    id: 'fear_of_missing_out',
    name: 'FOMO',
    headline: 'Parents who upgrade sleep better',
    subheadline: 'See why 94% of Pro users would recommend',
    pricing: {
      yearly: '$39.99/yr (most popular)',
      monthly: '$4.99/mo',
      lifetime: '$79.99 lifetime'
    },
    features: [
      {
        title: 'Predict the future',
        description: 'Know when baby will wake, feed, or nap',
        icon: '🔮'
      },
      {
        title: 'Track everything',
        description: 'Sleep efficiency, feeding patterns, growth trends',
        icon: '📋'
      },
      {
        title: 'Family coordination',
        description: 'Real-time sync across all caregivers',
        icon: '📱'
      },
      {
        title: 'AI parenting assistant',
        description: 'Answers questions, analyzes cries, gives advice',
        icon: '💬'
      }
    ],
    socialProof: '💝 Loved by 50,000+ families worldwide',
    ctaText: 'Join Pro Parents',
    backgroundColor: 'from-purple-500/10 via-purple-500/5 to-background'
  }
];

class ABTestingService {
  private userVariant: PaywallVariant | null = null;

  /**
   * Get the paywall variant for the current user
   * Uses consistent hashing to ensure user always sees the same variant
   */
  getPaywallVariant(userId?: string): PaywallVariant {
    if (this.userVariant) {
      return this.userVariant;
    }

    // If no user ID, return control variant
    if (!userId) {
      this.userVariant = PAYWALL_VARIANTS[0];
      return this.userVariant;
    }

    // Simple consistent hashing based on user ID
    const hash = this.simpleHash(userId);
    const variantIndex = Math.abs(hash) % PAYWALL_VARIANTS.length;

    this.userVariant = PAYWALL_VARIANTS[variantIndex];

    // Track which variant the user sees
    track('paywall_variant_shown', {
      variant_id: this.userVariant.id,
      variant_name: this.userVariant.name
    });

    return this.userVariant;
  }

  /**
   * Track paywall interactions for conversion analysis
   */
  trackPaywallInteraction(action: 'view' | 'click_cta' | 'dismiss', variantId: string) {
    track('paywall_interaction', {
      action,
      variant_id: variantId,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Track conversion from paywall to purchase
   */
  trackConversion(variantId: string, planType: 'monthly' | 'yearly' | 'lifetime') {
    track('paywall_conversion', {
      variant_id: variantId,
      plan_type: planType,
      converted_at: new Date().toISOString()
    });
  }

  /**
   * Simple hash function for consistent user assignment
   */
  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash;
  }

  /**
   * Get all available variants (for admin/testing)
   */
  getAllVariants(): PaywallVariant[] {
    return PAYWALL_VARIANTS;
  }

  /**
   * Reset variant assignment (for testing)
   */
  reset(): void {
    this.userVariant = null;
  }
}

export const abTestingService = new ABTestingService();

