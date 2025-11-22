import { track } from '@/analytics/analytics';
import { usePro } from '@/hooks/usePro';

export interface UpgradePrompt {
  id: string;
  title: string;
  message: string;
  ctaText: string;
  icon: string;
  priority: 'low' | 'medium' | 'high';
  conditions: UpgradeCondition[];
  maxDisplays: number;
  cooldownDays: number;
}

export interface UpgradeCondition {
  type: 'event_count' | 'feature_used' | 'time_since_signup' | 'page_view' | 'streak_broken';
  value: number | string;
  operator: 'gt' | 'gte' | 'lt' | 'lte' | 'eq' | 'contains';
}

const UPGRADE_PROMPTS: UpgradePrompt[] = [
  {
    id: 'first_patterns_view',
    title: 'Unlock Detailed Patterns',
    message: 'See your baby\'s sleep and feeding trends over the past week with beautiful charts and insights.',
    ctaText: 'View Patterns',
    icon: '📊',
    priority: 'high',
    conditions: [
      { type: 'event_count', value: 10, operator: 'gte' },
      { type: 'page_view', value: 'patterns', operator: 'eq' }
    ],
    maxDisplays: 3,
    cooldownDays: 7
  },
  {
    id: 'second_baby_added',
    title: 'Multi-Baby Support',
    message: 'Track multiple babies with one Pro subscription. Perfect for twins or growing families!',
    ctaText: 'Add Another Baby',
    icon: '👶👶',
    priority: 'high',
    conditions: [
      { type: 'event_count', value: 50, operator: 'gte' },
      { type: 'page_view', value: 'manage-babies', operator: 'eq' }
    ],
    maxDisplays: 2,
    cooldownDays: 14
  },
  {
    id: 'cry_analysis_used',
    title: 'Advanced Cry Insights',
    message: 'Get detailed AI analysis of your baby\'s cries with confidence scores and personalized tips.',
    ctaText: 'Upgrade for Full Analysis',
    icon: '👂',
    priority: 'medium',
    conditions: [
      { type: 'feature_used', value: 'cry_insights', operator: 'eq' }
    ],
    maxDisplays: 5,
    cooldownDays: 3
  },
  {
    id: 'doctor_report_generated',
    title: 'Professional Reports',
    message: 'Generate and share detailed reports with your pediatrician. Include charts, patterns, and insights.',
    ctaText: 'Create Doctor Report',
    icon: '📋',
    priority: 'high',
    conditions: [
      { type: 'event_count', value: 30, operator: 'gte' },
      { type: 'page_view', value: 'doctor-report', operator: 'eq' }
    ],
    maxDisplays: 3,
    cooldownDays: 7
  },
  {
    id: 'streak_recovery',
    title: 'Never Lose Your Streak',
    message: 'Pro users maintain their logging streaks even when life gets busy. Keep your momentum going!',
    ctaText: 'Protect My Streak',
    icon: '🔥',
    priority: 'medium',
    conditions: [
      { type: 'streak_broken', value: true, operator: 'eq' }
    ],
    maxDisplays: 2,
    cooldownDays: 30
  },
  {
    id: 'ai_assistant_used',
    title: 'Full AI Parenting Support',
    message: 'Get unlimited access to AI guidance, cry analysis, and personalized parenting advice.',
    ctaText: 'Unlock AI Assistant',
    icon: '🤖',
    priority: 'high',
    conditions: [
      { type: 'feature_used', value: 'ai_assistant', operator: 'eq' }
    ],
    maxDisplays: 5,
    cooldownDays: 1
  }
];

class UpgradePromptService {
  private dismissedPrompts: Set<string> = new Set();
  private promptDisplayCount: Record<string, number> = {};
  private lastDisplayed: Record<string, Date> = {};

  constructor() {
    this.loadFromStorage();
  }

  /**
   * Get contextual upgrade prompts based on user behavior
   */
  async getContextualPrompts(userContext: UserContext): Promise<UpgradePrompt[]> {
    const availablePrompts = UPGRADE_PROMPTS.filter(prompt =>
      this.shouldShowPrompt(prompt, userContext)
    );

    // Sort by priority and recency
    return availablePrompts.sort((a, b) => {
      const priorityOrder = { high: 3, medium: 2, low: 1 };
      const priorityDiff = priorityOrder[b.priority] - priorityOrder[a.priority];
      if (priorityDiff !== 0) return priorityDiff;

      // Show less recently shown prompts first
      const aLastShown = this.lastDisplayed[a.id];
      const bLastShown = this.lastDisplayed[b.id];
      if (!aLastShown && bLastShown) return -1;
      if (aLastShown && !bLastShown) return 1;
      if (aLastShown && bLastShown) {
        return aLastShown.getTime() - bLastShown.getTime();
      }
      return 0;
    });
  }

  /**
   * Check if a prompt should be shown based on conditions and limits
   */
  private shouldShowPrompt(prompt: UpgradePrompt, context: UserContext): boolean {
    // Check if already dismissed
    if (this.dismissedPrompts.has(prompt.id)) {
      return false;
    }

    // Check display limits
    const displayCount = this.promptDisplayCount[prompt.id] || 0;
    if (displayCount >= prompt.maxDisplays) {
      return false;
    }

    // Check cooldown period
    const lastShown = this.lastDisplayed[prompt.id];
    if (lastShown) {
      const daysSinceShown = (Date.now() - lastShown.getTime()) / (1000 * 60 * 60 * 24);
      if (daysSinceShown < prompt.cooldownDays) {
        return false;
      }
    }

    // Check conditions
    return prompt.conditions.every(condition =>
      this.checkCondition(condition, context)
    );
  }

  /**
   * Evaluate if a condition is met
   */
  private checkCondition(condition: UpgradeCondition, context: UserContext): boolean {
    switch (condition.type) {
      case 'event_count':
        return this.compareValues(context.eventCount, condition.value, condition.operator);

      case 'feature_used':
        return context.recentlyUsedFeatures.includes(condition.value as string);

      case 'time_since_signup': {
        const daysSinceSignup = (Date.now() - context.signupDate.getTime()) / (1000 * 60 * 60 * 24);
        return this.compareValues(daysSinceSignup, condition.value, condition.operator);
      }

      case 'page_view':
        return context.currentPage === condition.value;

      case 'streak_broken':
        return context.streakBroken === (condition.value as boolean);

      default:
        return false;
    }
  }

  /**
   * Generic value comparison
   */
  private compareValues(actual: number | string | boolean, expected: number | string | boolean, operator: string): boolean {
    switch (operator) {
      case 'gt': return (actual as number) > (expected as number);
      case 'gte': return (actual as number) >= (expected as number);
      case 'lt': return (actual as number) < (expected as number);
      case 'lte': return (actual as number) <= (expected as number);
      case 'eq': return actual === expected;
      case 'contains': return (actual as string).includes(expected as string);
      default: return false;
    }
  }

  /**
   * Mark a prompt as displayed
   */
  markPromptDisplayed(promptId: string): void {
    this.lastDisplayed[promptId] = new Date();
    this.promptDisplayCount[promptId] = (this.promptDisplayCount[promptId] || 0) + 1;
    this.saveToStorage();

    track('upgrade_prompt_shown', {
      prompt_id: promptId,
      display_count: this.promptDisplayCount[promptId]
    });
  }

  /**
   * Mark a prompt as dismissed
   */
  dismissPrompt(promptId: string): void {
    this.dismissedPrompts.add(promptId);
    this.saveToStorage();

    track('upgrade_prompt_dismissed', {
      prompt_id: promptId
    });
  }

  /**
   * Track when a user takes action from a prompt
   */
  trackPromptAction(promptId: string, action: 'upgrade_clicked' | 'feature_viewed'): void {
    track('upgrade_prompt_action', {
      prompt_id: promptId,
      action
    });
  }

  /**
   * Reset prompt tracking (for testing)
   */
  reset(): void {
    this.dismissedPrompts.clear();
    this.promptDisplayCount = {};
    this.lastDisplayed = {};
    this.saveToStorage();
  }

  /**
   * Load tracking data from localStorage
   */
  private loadFromStorage(): void {
    try {
      const data = localStorage.getItem('upgrade_prompts');
      if (data) {
        const parsed = JSON.parse(data);
        this.dismissedPrompts = new Set(parsed.dismissedPrompts || []);
        this.promptDisplayCount = parsed.promptDisplayCount || {};
        this.lastDisplayed = Object.fromEntries(
          Object.entries(parsed.lastDisplayed || {}).map(([key, value]) => [
            key,
            new Date(value as string)
          ])
        );
      }
    } catch (error) {
      console.error('Failed to load upgrade prompt data:', error);
    }
  }

  /**
   * Save tracking data to localStorage
   */
  private saveToStorage(): void {
    try {
      const data = {
        dismissedPrompts: Array.from(this.dismissedPrompts),
        promptDisplayCount: this.promptDisplayCount,
        lastDisplayed: Object.fromEntries(
          Object.entries(this.lastDisplayed).map(([key, value]) => [
            key,
            (value as Date).toISOString()
          ])
        )
      };
      localStorage.setItem('upgrade_prompts', JSON.stringify(data));
    } catch (error) {
      console.error('Failed to save upgrade prompt data:', error);
    }
  }
}

export interface UserContext {
  eventCount: number;
  signupDate: Date;
  currentPage: string;
  recentlyUsedFeatures: string[];
  streakBroken: boolean;
}

export const upgradePromptService = new UpgradePromptService();

