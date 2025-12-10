import { useState, useEffect, useCallback } from 'react';
import type { BabyEvent } from '@/lib/types';

export function useActiveTimer(activeEvent: BabyEvent | null) {
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (!activeEvent) {
      setElapsed(0);
      return;
    }

    const updateElapsed = () => {
      const start = new Date(activeEvent.start_time).getTime();
      const now = Date.now();
      const diff = Math.floor((now - start) / 1000); // seconds
      setElapsed(diff);
    };

    updateElapsed();
    const interval = setInterval(updateElapsed, 1000);

    return () => clearInterval(interval);
  }, [activeEvent]);

  const formatTime = useCallback((seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  }, []);

  return {
    elapsed,
    formattedTime: formatTime(elapsed),
  };
}
