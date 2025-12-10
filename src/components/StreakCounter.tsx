import { Flame } from 'lucide-react';
import { cn } from '@/lib/utils';

interface StreakCounterProps {
  days: number;
  className?: string;
}

export function StreakCounter({ days, className }: StreakCounterProps) {
  if (days === 0) return null;

  return (
    <div
      className={cn(
        'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-gradient-to-r from-orange-500/10 to-red-500/10 border border-orange-500/20',
        className
      )}
    >
      <Flame className='h-4 w-4 text-orange-500' />
      <span className='text-sm font-semibold text-orange-600 dark:text-orange-400'>
        {days} day streak
      </span>
    </div>
  );
}
