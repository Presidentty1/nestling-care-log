import { subscriptionService } from './subscriptionService';

export type FeatureType =
  | 'aiPredictions'
  | 'cryAnalysis'
  | 'aiAssistant'
  | 'advancedAnalytics'
  | 'weeklySummaries';

class FeatureAccessService {
  /**
   * Check if user can access a specific feature
   */
  async canAccessFeature(feature: FeatureType, userId: string): Promise<boolean> {
    switch (feature) {
      case 'aiPredictions':
        // Free users get limited nap predictions
        return await subscriptionService.canAccessFeature('aiPredictions', userId);

      case 'cryAnalysis':
        // Free users get 2 cry analyses per week
        return await subscriptionService.canAccessFeature('cryAnalysis', userId);

      case 'aiAssistant':
        // Free users get 5 AI assistant queries per day
        return await subscriptionService.canAccessFeature('aiAssistant', userId);

      case 'advancedAnalytics':
        // Premium only
        return await subscriptionService.isPremium(userId);

      case 'weeklySummaries':
        // Premium only
        return await subscriptionService.isPremium(userId);

      default:
        return true; // Unknown features default to allowed
    }
  }

  /**
   * Get feature access status with usage info
   */
  async getFeatureStatus(
    feature: FeatureType,
    userId: string
  ): Promise<{
    canAccess: boolean;
    isPremium: boolean;
    usage?: { current: number; limit: number };
  }> {
    const isPremium = await subscriptionService.isPremium(userId);
    const canAccess = await this.canAccessFeature(feature, userId);

    // Get usage info for limited features
    let usage;
    if (!isPremium) {
      const limits = await subscriptionService.getLimits(userId);
      if (limits[feature as keyof typeof limits] > 0) {
        // This feature has usage limits, get current usage
        const currentUsage = await subscriptionService['getFeatureUsage'](
          feature as keyof typeof limits,
          userId
        );
        usage = {
          current: currentUsage,
          limit: limits[feature as keyof typeof limits],
        };
      }
    }

    return {
      canAccess,
      isPremium,
      usage,
    };
  }

  /**
   * Check if user should see upgrade prompts
   */
  async shouldShowUpgradePrompt(userId: string, feature?: FeatureType): Promise<boolean> {
    const isPremium = await subscriptionService.isPremium(userId);
    if (isPremium) return false;

    // Show upgrade prompt if trying to access premium features
    if (feature) {
      const canAccess = await this.canAccessFeature(feature, userId);
      return !canAccess;
    }

    // Show general upgrade prompt for free users (after trial period)
    const trialDays = await subscriptionService.getTrialDaysRemaining(userId);
    return trialDays !== null && trialDays <= 2; // Show when trial is ending
  }
}

export const featureAccessService = new FeatureAccessService();
export default featureAccessService;
