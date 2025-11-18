import localforage from 'localforage';
import { format, differenceInDays, startOfDay } from 'date-fns';

const streakStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'streaks',
});

interface StreakData {
  currentStreak: number;
  longestStreak: number;
  lastLogDate: string;
  totalDaysLogged: number;
}

interface DayCompletion {
  date: string;
  hasFeed: boolean;
  hasSleep: boolean;
  hasDiaper: boolean;
}

class StreakService {
  async getStreak(babyId: string): Promise<StreakData> {
    const streak = await streakStore.getItem<StreakData>(`streak_${babyId}`);
    return streak || {
      currentStreak: 0,
      longestStreak: 0,
      lastLogDate: '',
      totalDaysLogged: 0,
    };
  }

  async updateStreak(babyId: string): Promise<StreakData> {
    const today = format(startOfDay(new Date()), 'yyyy-MM-dd');
    const streak = await this.getStreak(babyId);

    // If already logged today, don't update
    if (streak.lastLogDate === today) {
      return streak;
    }

    // Check if streak continues (yesterday or today)
    const daysSinceLastLog = streak.lastLogDate 
      ? differenceInDays(new Date(today), new Date(streak.lastLogDate))
      : 999;

    let newStreak: StreakData;

    if (daysSinceLastLog === 1) {
      // Streak continues
      newStreak = {
        currentStreak: streak.currentStreak + 1,
        longestStreak: Math.max(streak.longestStreak, streak.currentStreak + 1),
        lastLogDate: today,
        totalDaysLogged: streak.totalDaysLogged + 1,
      };
    } else if (daysSinceLastLog === 0) {
      // Same day
      newStreak = streak;
    } else {
      // Streak broken, start new
      newStreak = {
        currentStreak: 1,
        longestStreak: streak.longestStreak,
        lastLogDate: today,
        totalDaysLogged: streak.totalDaysLogged + 1,
      };
    }

    await streakStore.setItem(`streak_${babyId}`, newStreak);
    return newStreak;
  }

  async getDayCompletion(babyId: string, date: string): Promise<DayCompletion> {
    const completion = await streakStore.getItem<DayCompletion>(`completion_${babyId}_${date}`);
    return completion || {
      date,
      hasFeed: false,
      hasSleep: false,
      hasDiaper: false,
    };
  }

  async markEventLogged(babyId: string, date: string, eventType: string): Promise<void> {
    const completion = await this.getDayCompletion(babyId, date);
    
    if (eventType === 'feed') completion.hasFeed = true;
    if (eventType === 'sleep') completion.hasSleep = true;
    if (eventType === 'diaper') completion.hasDiaper = true;

    await streakStore.setItem(`completion_${babyId}_${date}`, completion);
  }

  async isDayComplete(babyId: string, date: string): Promise<boolean> {
    const completion = await this.getDayCompletion(babyId, date);
    return completion.hasFeed && completion.hasSleep && completion.hasDiaper;
  }

  async shouldShowAffirmation(babyId: string): Promise<boolean> {
    const today = format(new Date(), 'yyyy-MM-dd');
    const isComplete = await this.isDayComplete(babyId, today);
    const shownKey = `affirmation_shown_${babyId}_${today}`;
    const hasShown = await streakStore.getItem<boolean>(shownKey);
    
    return isComplete && !hasShown;
  }

  async markAffirmationShown(babyId: string): Promise<void> {
    const today = format(new Date(), 'yyyy-MM-dd');
    await streakStore.setItem(`affirmation_shown_${babyId}_${today}`, true);
  }
}

export const streakService = new StreakService();
