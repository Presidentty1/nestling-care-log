import { Clock } from 'lucide-react';
import { cn } from '@/lib/utils';

interface TrialCountdownProps {
  daysRemaining: number;
  className?: string;
}

export function TrialCountdown({ daysRemaining, className }: TrialCountdownProps) {
  const isUrgent = daysRemaining <= 3;

  return (
    <div className={cn(
      "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border",
      isUrgent 
        ? "bg-destructive/10 border-destructive/20 text-destructive"
        : "bg-primary/10 border-primary/20 text-primary",
      className
    )}>
      <Clock className="h-4 w-4" />
      <span className="text-sm font-medium">
        {daysRemaining} day{daysRemaining !== 1 ? 's' : ''} left in trial
      </span>
    </div>
  );
}
