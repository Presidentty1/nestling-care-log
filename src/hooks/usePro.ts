import { useState, useEffect } from 'react';
import type { SubscriptionStatus } from '@/services/proService';
import { proService } from '@/services/proService';

export function usePro() {
  const [isPro, setIsPro] = useState(false);
  const [status, setStatus] = useState<SubscriptionStatus | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadProStatus();
  }, []);

  const loadProStatus = async () => {
    try {
      const subscriptionStatus = await proService.getSubscriptionStatus();
      setIsPro(subscriptionStatus.isPro);
      setStatus(subscriptionStatus);
    } catch (error) {
      console.error('Error loading Pro status:', error);
      setIsPro(false);
    } finally {
      setLoading(false);
    }
  };

  const canAccessFeature = async (feature: 'caregiver_invites' | 'ai_features' | 'csv_export' | 'advanced_analytics') => {
    return await proService.canAccessFeature(feature);
  };

  return {
    isPro,
    status,
    loading,
    canAccessFeature,
    refresh: loadProStatus,
  };
}


