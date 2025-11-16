import { formatTimerDisplay } from '@/utils/time';

interface TimerDisplayProps {
  seconds: number;
  isRunning: boolean;
}

export function TimerDisplay({ seconds, isRunning }: TimerDisplayProps) {
  return (
    <div className="flex flex-col items-center justify-center p-6">
      <div 
        className={`
          text-5xl font-mono font-bold tracking-wider
          ${isRunning ? 'text-primary animate-pulse' : 'text-muted-foreground'}
        `}
        data-testid="timer-display"
        aria-live="polite"
      >
        {formatTimerDisplay(seconds)}
      </div>
      <p className="text-sm text-muted-foreground mt-2">
        {isRunning ? 'Timer running' : 'Timer stopped'}
      </p>
    </div>
  );
}
