import localforage from 'localforage';

const achievementStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'achievements',
});

export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlockedAt?: string;
}

const ACHIEVEMENTS: Achievement[] = [
  {
    id: 'first_week',
    title: 'First Week',
    description: 'Logged events for 7 consecutive days',
    icon: '🎉',
  },
  {
    id: 'night_owl',
    title: 'Night Owl',
    description: 'Logged a feed between 2am-5am',
    icon: '🦉',
  },
  {
    id: 'consistent_logger',
    title: 'Consistent Logger',
    description: 'Maintained a 7-day logging streak',
    icon: '📊',
  },
  {
    id: 'data_champion',
    title: 'Data Champion',
    description: 'Maintained a 30-day logging streak',
    icon: '🏆',
  },
  {
    id: 'early_adopter',
    title: 'Early Adopter',
    description: 'Signed up and started logging',
    icon: '⭐',
  },
  {
    id: 'milestone_master',
    title: 'Milestone Master',
    description: 'Logged 5 milestones',
    icon: '🎯',
  },
];

class AchievementService {
  async getAllAchievements(): Promise<Achievement[]> {
    return ACHIEVEMENTS;
  }

  async getUnlockedAchievements(babyId: string): Promise<Achievement[]> {
    const unlocked = await achievementStore.getItem<string[]>(`unlocked_${babyId}`);
    if (!unlocked) return [];

    return ACHIEVEMENTS.filter(a => unlocked.includes(a.id)).map(a => ({
      ...a,
      unlockedAt: unlocked.includes(a.id) ? new Date().toISOString() : undefined,
    }));
  }

  async unlockAchievement(babyId: string, achievementId: string): Promise<boolean> {
    const unlocked = (await achievementStore.getItem<string[]>(`unlocked_${babyId}`)) || [];

    if (unlocked.includes(achievementId)) {
      return false; // Already unlocked
    }

    unlocked.push(achievementId);
    await achievementStore.setItem(`unlocked_${babyId}`, unlocked);
    return true;
  }

  async checkAndUnlockAchievements(
    babyId: string,
    context: {
      streakDays?: number;
      eventType?: string;
      eventTime?: Date;
      milestoneCount?: number;
    }
  ): Promise<Achievement[]> {
    const newlyUnlocked: Achievement[] = [];

    // Check streak-based achievements
    if (context.streakDays) {
      if (context.streakDays >= 7) {
        const wasNew = await this.unlockAchievement(babyId, 'first_week');
        if (wasNew) {
          newlyUnlocked.push(ACHIEVEMENTS.find(a => a.id === 'first_week')!);
        }
      }
      if (context.streakDays >= 7) {
        const wasNew = await this.unlockAchievement(babyId, 'consistent_logger');
        if (wasNew) {
          newlyUnlocked.push(ACHIEVEMENTS.find(a => a.id === 'consistent_logger')!);
        }
      }
      if (context.streakDays >= 30) {
        const wasNew = await this.unlockAchievement(babyId, 'data_champion');
        if (wasNew) {
          newlyUnlocked.push(ACHIEVEMENTS.find(a => a.id === 'data_champion')!);
        }
      }
    }

    // Check night owl
    if (context.eventType === 'feed' && context.eventTime) {
      const hour = context.eventTime.getHours();
      if (hour >= 2 && hour < 5) {
        const wasNew = await this.unlockAchievement(babyId, 'night_owl');
        if (wasNew) {
          newlyUnlocked.push(ACHIEVEMENTS.find(a => a.id === 'night_owl')!);
        }
      }
    }

    // Check milestone master
    if (context.milestoneCount && context.milestoneCount >= 5) {
      const wasNew = await this.unlockAchievement(babyId, 'milestone_master');
      if (wasNew) {
        newlyUnlocked.push(ACHIEVEMENTS.find(a => a.id === 'milestone_master')!);
      }
    }

    return newlyUnlocked;
  }
}

export const achievementService = new AchievementService();
