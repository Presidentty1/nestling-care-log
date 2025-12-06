import { useState, useEffect } from 'react';

interface FeatureDiscoveryState {
  [featureKey: string]: {
    introduced: boolean;
    dismissedAt?: number;
  };
}

const STORAGE_KEY = 'featureDiscoveryState';

// Feature introduction timeline (in days since first log)
const FEATURE_TIMELINE = {
  'ai-predictions': 2,    // Day 2-3: Show AI prediction card
  'history': 4,            // Day 4-5: Introduce history view
  'invite-partner': 6,     // Day 6-7: Show invite partner prompt
  'analytics': 14,         // Week 2: Introduce analytics
  'ai-assistant': 14,      // Week 2: Introduce AI assistant
  'cry-insights': 21,      // Week 3: Introduce cry insights
};

export function useFeatureDiscovery() {
  const [state, setState] = useState<FeatureDiscoveryState>({});

  useEffect(() => {
    // Load state from localStorage
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setState(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Failed to load feature discovery state:', error);
    }
  }, []);

  const saveState = (newState: FeatureDiscoveryState) => {
    setState(newState);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newState));
    } catch (error) {
      console.error('Failed to save feature discovery state:', error);
    }
  };

  const getDaysSinceFirstLog = (): number => {
    const firstLogTime = localStorage.getItem('onboardingCompletedAt');
    if (!firstLogTime) return 0;
    const daysSince = Math.floor((Date.now() - parseInt(firstLogTime)) / (1000 * 60 * 60 * 24));
    return daysSince;
  };

  const shouldIntroduceFeature = (featureKey: string): boolean => {
    const daysSince = getDaysSinceFirstLog();
    const requiredDays = FEATURE_TIMELINE[featureKey as keyof typeof FEATURE_TIMELINE] || 0;
    
    // Check if feature has been introduced or dismissed
    const featureState = state[featureKey];
    if (featureState?.introduced || featureState?.dismissedAt) {
      return false;
    }
    
    // Check if enough days have passed
    return daysSince >= requiredDays;
  };

  const markFeatureIntroduced = (featureKey: string) => {
    const newState = {
      ...state,
      [featureKey]: {
        introduced: true,
      },
    };
    saveState(newState);
  };

  const dismissFeature = (featureKey: string) => {
    const newState = {
      ...state,
      [featureKey]: {
        introduced: false,
        dismissedAt: Date.now(),
      },
    };
    saveState(newState);
  };

  const hasSeenFeature = (featureKey: string): boolean => {
    return state[featureKey]?.introduced || false;
  };

  // Get the next feature to introduce (only one at a time)
  const getNextFeatureToIntroduce = (): string | null => {
    const daysSince = getDaysSinceFirstLog();
    
    // Find all features that are ready to introduce
    const readyFeatures = Object.keys(FEATURE_TIMELINE).filter(key => {
      const requiredDays = FEATURE_TIMELINE[key as keyof typeof FEATURE_TIMELINE];
      const featureState = state[key];
      return daysSince >= requiredDays && !featureState?.introduced && !featureState?.dismissedAt;
    });
    
    // Return the first ready feature (they're already in order of introduction)
    return readyFeatures[0] || null;
  };

  return {
    shouldIntroduceFeature,
    markFeatureIntroduced,
    dismissFeature,
    hasSeenFeature,
    getNextFeatureToIntroduce,
    daysSinceFirstLog: getDaysSinceFirstLog(),
  };
}

