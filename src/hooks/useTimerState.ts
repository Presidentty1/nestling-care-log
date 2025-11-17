import { useState, useEffect, useCallback, useRef } from 'react';
import { TimerState } from '@/types/events';
import { dataService } from '@/services/dataService';
import { getElapsedSeconds } from '@/utils/time';
import { toast } from 'sonner';

export function useTimerState(babyId: string) {
  const [state, setState] = useState<TimerState>({
    status: 'idle',
    accumulatedMs: 0,
  });
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const intervalRef = useRef<number | null>(null);
  
  useEffect(() => {
    loadPersistedTimer();
  }, [babyId]);
  
  useEffect(() => {
    if (state.status === 'running' && state.startTime) {
      intervalRef.current = window.setInterval(() => {
        const elapsed = getElapsedSeconds(state.startTime!);
        setElapsedSeconds(elapsed);
      }, 1000);
      
      return () => {
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
        }
      };
    }
  }, [state.status, state.startTime]);
  
  const loadPersistedTimer = async () => {
    const persisted = await dataService.getTimerState(babyId);
    if (persisted && persisted.status === 'running') {
      setState(persisted);
      if (persisted.startTime) {
        const elapsed = getElapsedSeconds(persisted.startTime);
        setElapsedSeconds(elapsed);
        
        // Show restoration toast
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        const timeStr = minutes > 0 
          ? `${minutes}m ${seconds}s` 
          : `${seconds}s`;
        
        toast.success(`Timer resumed from ${timeStr}`, {
          description: 'Your timer was running and has been restored.',
          duration: 4000,
        });
      }
    }
  };
  
  const start = useCallback(async (eventId: string) => {
    const newState: TimerState = {
      status: 'running',
      eventId,
      startTime: new Date().toISOString(),
      accumulatedMs: 0,
    };
    setState(newState);
    await dataService.saveTimerState(babyId, newState);
  }, [babyId]);
  
  const pause = useCallback(async () => {
    if (state.status !== 'running') return;
    
    const newState: TimerState = {
      ...state,
      status: 'paused',
      pausedAt: new Date().toISOString(),
    };
    setState(newState);
    await dataService.saveTimerState(babyId, newState);
  }, [state, babyId]);
  
  const resume = useCallback(async () => {
    if (state.status !== 'paused') return;
    
    const newState: TimerState = {
      ...state,
      status: 'running',
      startTime: new Date().toISOString(),
    };
    setState(newState);
    await dataService.saveTimerState(babyId, newState);
  }, [state, babyId]);
  
  const stop = useCallback(async () => {
    const finalSeconds = elapsedSeconds;
    const newState: TimerState = {
      status: 'stopped',
      accumulatedMs: 0,
    };
    setState(newState);
    await dataService.clearTimerState(babyId);
    return finalSeconds;
  }, [babyId, elapsedSeconds]);
  
  const reset = useCallback(async () => {
    setState({
      status: 'idle',
      accumulatedMs: 0,
    });
    setElapsedSeconds(0);
    await dataService.clearTimerState(babyId);
  }, [babyId]);
  
  return {
    state,
    elapsedSeconds,
    start,
    pause,
    resume,
    stop,
    reset,
  };
}
