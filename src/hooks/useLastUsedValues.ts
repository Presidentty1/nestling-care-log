import { EventType } from '@/types/events';

interface LastUsedValues {
  feed: {
    subtype: string;
    amount: number;
    unit: string;
    side?: string;
  };
  sleep: {
    note: string;
  };
  diaper: {
    subtype: string;
  };
  tummy_time: {
    duration_min: number;
  };
}

const STORAGE_KEY = 'nestling_last_used_values';

export function useLastUsedValues() {
  const getLastUsed = (type: EventType): any => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (!stored) return getDefaults(type);
      
      const parsed = JSON.parse(stored) as Partial<LastUsedValues>;
      return parsed[type] || getDefaults(type);
    } catch {
      return getDefaults(type);
    }
  };

  const saveLastUsed = (type: EventType, values: any) => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      const existing = stored ? JSON.parse(stored) : {};
      
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          ...existing,
          [type]: values,
        })
      );
    } catch (error) {
      console.error('Failed to save last used values:', error);
    }
  };

  const getDefaults = (type: EventType): any => {
    switch (type) {
      case 'feed':
        return { subtype: 'bottle', amount: 4, unit: 'oz' };
      case 'diaper':
        return { subtype: 'wet' };
      case 'sleep':
        return { note: '' };
      case 'tummy_time':
        return { duration_min: 5 };
      default:
        return {};
    }
  };

  return { getLastUsed, saveLastUsed };
}
