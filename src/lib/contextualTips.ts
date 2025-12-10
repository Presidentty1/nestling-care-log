import { differenceInMonths, differenceInWeeks } from 'date-fns';

export interface ContextualTip {
  id: string;
  content: string;
  icon: string;
  category: 'sleep' | 'feeding' | 'development' | 'general';
}

export function getContextualTips(babyBirthDate: string, recentEvents?: any[]): ContextualTip[] {
  const ageInMonths = differenceInMonths(new Date(), new Date(babyBirthDate));
  const ageInWeeks = differenceInWeeks(new Date(), new Date(babyBirthDate));

  const tips: ContextualTip[] = [];

  // Age-based tips
  if (ageInWeeks < 4) {
    tips.push({
      id: 'newborn-feeding',
      content:
        'Newborns typically eat 8-12 times per day. Cluster feeding in the evening is normal!',
      icon: '🍼',
      category: 'feeding',
    });
    tips.push({
      id: 'newborn-sleep',
      content:
        'Newborns sleep 14-17 hours per day in short bursts. Wake windows are 45-60 minutes.',
      icon: '💤',
      category: 'sleep',
    });
  } else if (ageInMonths < 3) {
    tips.push({
      id: 'wake-windows-2mo',
      content: 'At 1-3 months, wake windows are typically 60-90 minutes. Watch for tired cues!',
      icon: '⏰',
      category: 'sleep',
    });
    tips.push({
      id: 'growth-spurt',
      content:
        'Growth spurts often happen around 3 weeks, 6 weeks, and 3 months. Extra feeds are normal!',
      icon: '📈',
      category: 'development',
    });
  } else if (ageInMonths < 6) {
    tips.push({
      id: 'wake-windows-4mo',
      content: '3-4 month wake windows are typically 90-120 minutes. Naps may start consolidating.',
      icon: '⏰',
      category: 'sleep',
    });
    tips.push({
      id: 'four-month-regression',
      content: 'The 4-month sleep regression is developmental, not a setback. Stay consistent!',
      icon: '🌙',
      category: 'sleep',
    });
  } else if (ageInMonths < 9) {
    tips.push({
      id: 'wake-windows-6mo',
      content:
        '6-8 months: wake windows are 2-3 hours. Most babies need 2-3 naps totaling 3-4 hours.',
      icon: '⏰',
      category: 'sleep',
    });
    tips.push({
      id: 'solids-intro',
      content:
        'Starting solids? Offer after milk feeds and watch for allergic reactions. Enjoy the mess!',
      icon: '🥄',
      category: 'feeding',
    });
  } else if (ageInMonths < 12) {
    tips.push({
      id: 'wake-windows-9mo',
      content: '9-12 months: wake windows are 2.5-4 hours. Many babies transition to 2 naps.',
      icon: '⏰',
      category: 'sleep',
    });
    tips.push({
      id: 'separation-anxiety',
      content: 'Separation anxiety peaks around 9 months. Extra cuddles and reassurance help!',
      icon: '💕',
      category: 'development',
    });
  } else {
    tips.push({
      id: 'toddler-transition',
      content: 'Most toddlers transition to 1 nap between 12-18 months. Follow their lead!',
      icon: '👶',
      category: 'sleep',
    });
  }

  // Pattern-based tips (if events provided)
  if (recentEvents && recentEvents.length > 0) {
    const sleepEvents = recentEvents.filter(e => e.type === 'sleep');
    const feedEvents = recentEvents.filter(e => e.type === 'feed');

    if (sleepEvents.length > 0) {
      const avgSleepMinutes =
        sleepEvents.reduce((sum, e) => {
          if (e.end_time) {
            const duration =
              (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / (1000 * 60);
            return sum + duration;
          }
          return sum;
        }, 0) / sleepEvents.length;

      if (avgSleepMinutes < 30 && ageInMonths < 6) {
        tips.push({
          id: 'short-naps',
          content:
            'Short naps (<30 min) are common for young babies. Try a darker room and white noise.',
          icon: '🌙',
          category: 'sleep',
        });
      }
    }

    if (feedEvents.length > 0) {
      const recentFeedCount = feedEvents.filter(e => {
        const hoursSince =
          (new Date().getTime() - new Date(e.start_time).getTime()) / (1000 * 60 * 60);
        return hoursSince <= 24;
      }).length;

      if (recentFeedCount > 12 && ageInWeeks > 4) {
        tips.push({
          id: 'frequent-feeding',
          content:
            'Feeding more than usual? Could be a growth spurt, teething, or just extra comfort needed.',
          icon: '🍼',
          category: 'feeding',
        });
      }
    }
  }

  // General parenting tips - always include these
  const essentialTips = [
    {
      id: 'loose-logging',
      content:
        "It's okay if you miss logs. We'll still use what you have and stay conservative if we're unsure.",
      icon: '✨',
      category: 'general' as const,
    },
    {
      id: 'trust-yourself',
      content: "You know your baby best. Trust your instincts—they're usually right!",
      icon: '💪',
      category: 'general' as const,
    },
  ];

  // Return max 3 tips, but always include at least one essential tip
  const otherTips = tips.slice(0, 2); // Get up to 2 other tips
  return [...otherTips, ...essentialTips].slice(0, 3); // Combine and limit to 3 total
}
