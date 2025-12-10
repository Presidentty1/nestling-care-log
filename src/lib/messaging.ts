/**
 * Consistent messaging system for the Nestling app
 * Reinforces the north star: "The fastest shared baby logger"
 */

export const MESSAGING = {
  // North Star / Value Proposition
  northStar: 'The fastest shared baby logger',
  tagline: 'The fastest way to track baby care',
  
  // Core Value Props (3 pillars)
  valueProp: {
    speed: {
      short: 'Track in 2 taps',
      long: 'Track feeds, diapers, and sleep in just 2 taps. Designed for tired parents at 3 AM.',
      title: 'Ultra-Fast Logging',
    },
    ai: {
      short: 'AI-powered insights',
      long: 'Get smart nap predictions, pattern detection, and personalized recommendations.',
      title: 'AI-Powered Insights',
    },
    sync: {
      short: 'Sync with partner',
      long: 'Share with your partner, grandparents, or nanny. Everyone stays in sync, instantly.',
      title: 'Multi-Caregiver Sync',
    },
  },

  // Privacy Messaging
  privacy: {
    short: 'Your data stays private',
    long: 'No ads, no tracking. Data syncs only when you invite a caregiver.',
    tagline: 'Privacy-first design',
    features: [
      'Your data stays yours',
      'No ads, ever',
      'No tracking',
      'Export anytime',
      'Encrypted storage',
    ],
  },

  // Onboarding Messages
  onboarding: {
    welcome: {
      title: 'Welcome to Nestling',
      subtitle: "Let's get you set up in 60 seconds.",
      description: 'Track baby care in 2 taps. Get AI insights. Sync with partner.',
    },
    babyName: {
      title: "What is your baby's name?",
      subtitle: "We'll personalize everything for [Name]",
      description: "We'll use this to personalize your experience.",
    },
    dateOfBirth: {
      title: 'When was the big day?',
      subtitle: 'This helps us provide age-appropriate insights',
      description: 'This helps us track age-appropriate milestones.',
      example: "For a 2-month-old, we'll track wake windows and feeding patterns",
    },
    preferences: {
      title: 'Just a few details',
      subtitle: 'Customize how you want to track measurements',
      description: 'Customize how you want to track measurements.',
    },
    demo: {
      title: "Let's log your first event!",
      subtitle: 'Try it out - tap to log a sample event',
      description: 'See how fast and easy it is to track baby care.',
      success: "You're all set! Start tracking.",
    },
  },

  // First-Time User Experience
  firstTime: {
    welcome: {
      title: "Welcome! Let's log your first event",
      subtitle: 'Tap below to get started',
      cta: 'Log First Event',
    },
    emptyState: {
      title: 'Ready to start tracking',
      subtitle: 'Tap below to log your first event',
      description: "We'll start tracking patterns after a few logs",
    },
    firstLog: {
      title: 'Great start!',
      subtitle: "You've logged your first event.",
      next: "We'll start tracking patterns after a few more logs",
    },
  },

  // Quick Actions
  quickActions: {
    hint: 'Tap to quick log • Hold for details',
    logged: (type: string) => `${type.charAt(0).toUpperCase() + type.slice(1)} logged`,
  },

  // Features
  features: {
    predictions: {
      title: 'Smart Nap Predictions',
      description: 'AI learns your baby's patterns to predict optimal nap times',
    },
    insights: {
      title: 'Today's Insights',
      description: 'Get personalized recommendations based on your data',
    },
    history: {
      title: 'View History',
      description: 'Browse past days and see patterns over time',
    },
    analytics: {
      title: 'Advanced Analytics',
      description: 'Detailed charts and trends for deeper insights',
    },
    aiAssistant: {
      title: 'AI Assistant',
      description: '24/7 parenting Q&A powered by AI',
    },
    cryInsights: {
      title: 'Cry Analysis',
      description: 'Understand what baby needs when they cry',
    },
  },

  // Empty States
  emptyStates: {
    noEvents: {
      title: 'No events yet',
      subtitle: 'Start tracking to see your timeline',
      cta: 'Log First Event',
    },
    noHistory: {
      title: 'No history yet',
      subtitle: 'Start logging to build up your history',
    },
    noPredictions: {
      title: 'Not enough data yet',
      subtitle: 'Log a few more events to see predictions',
    },
  },

  // Success Messages
  success: {
    accountCreated: 'Account created! Setting up your profile...',
    welcomeBack: 'Welcome back!',
    babyCreated: (name: string) => `Welcome to Nestling, ${name}!`,
    eventLogged: (type: string) => `${type.charAt(0).toUpperCase() + type.slice(1)} logged`,
    eventUpdated: 'Event updated',
    eventDeleted: 'Event deleted',
  },

  // Error Messages
  errors: {
    generic: 'Something went wrong. Please try again.',
    network: 'Connection error. Your changes will sync when back online.',
    auth: 'Authentication failed. Please try again.',
  },

  // Tips & Contextual Help
  tips: {
    looseLogging: {
      title: 'Loose logging is okay',
      description: "Don't stress about exact times. Approximate is fine!",
    },
    trustYourself: {
      title: 'Trust yourself',
      description: "You know your baby best. This app is here to support, not judge.",
    },
    invitePartner: {
      title: 'Invite your partner',
      description: 'Sync logs across devices in real-time',
    },
    viewHistory: {
      title: 'View past days',
      description: 'Tap History to see patterns over time',
    },
    aiPredictions: {
      title: 'Try AI predictions',
      description: 'Get personalized nap time predictions',
    },
  },

  // Call to Actions
  cta: {
    getStarted: 'Get Started Free',
    signIn: 'Sign In',
    signUp: 'Sign Up',
    continue: 'Continue',
    skip: 'Skip',
    finish: 'Finish',
    logEvent: 'Log Event',
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    edit: 'Edit',
    viewAll: 'View All',
    learnMore: 'Learn More',
    tryIt: 'Try It',
  },

  // Disclaimers
  disclaimers: {
    medical: 'This app is not medical advice. Consult your pediatrician for guidance.',
    aiFeatures: 'AI features are experimental and should not replace professional medical advice.',
  },
} as const;

// Helper functions for dynamic messaging
export function getEventLoggedMessage(type: string, details?: string): string {
  const baseMessage = MESSAGING.success.eventLogged(type);
  return details ? `${baseMessage} • ${details}` : baseMessage;
}

export function getAgeBasedMessage(ageInMonths: number): string {
  if (ageInMonths < 1) {
    return 'Newborn care tracking';
  } else if (ageInMonths < 3) {
    return `${ageInMonths} month${ageInMonths === 1 ? '' : 's'} old - tracking wake windows`;
  } else if (ageInMonths < 6) {
    return `${ageInMonths} months old - tracking feeding patterns`;
  } else if (ageInMonths < 12) {
    return `${ageInMonths} months old - tracking milestones`;
  } else {
    return 'Toddler care tracking';
  }
}

export function getFeatureIntroMessage(featureKey: keyof typeof MESSAGING.features): {
  title: string;
  description: string;
} {
  return MESSAGING.features[featureKey];
}

export function getTimeSinceMessage(minutes: number): string {
  if (minutes < 1) {
    return 'Just now';
  } else if (minutes < 60) {
    return `${Math.round(minutes)}m ago`;
  } else if (minutes < 1440) {
    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  } else {
    const days = Math.floor(minutes / 1440);
    return `${days}d ago`;
  }
}



