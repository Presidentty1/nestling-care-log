import { useEffect, useRef } from 'react';
import type { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';
import { getPressEffect } from '@/lib/animations';

type Accent = 'feed' | 'sleep' | 'diaper' | 'tummy' | 'neutral';

interface SmartActionCardProps {
  label: string;
  status?: string;
  detail?: string;
  hint?: string;
  badge?: string;
  icon: LucideIcon;
  accent?: Accent;
  isActive?: boolean;
  onPress: () => void;
  onLongPress?: () => void;
}

const ACCENT_STYLES: Record<Accent, { bg: string; border: string; icon: string }> = {
  feed: {
    bg: 'bg-event-feed/8',
    border: 'border-event-feed/25',
    icon: 'text-event-feed',
  },
  sleep: {
    bg: 'bg-event-sleep/8',
    border: 'border-event-sleep/25',
    icon: 'text-event-sleep',
  },
  diaper: {
    bg: 'bg-event-diaper/8',
    border: 'border-event-diaper/25',
    icon: 'text-event-diaper',
  },
  tummy: {
    bg: 'bg-event-tummy/8',
    border: 'border-event-tummy/25',
    icon: 'text-event-tummy',
  },
  neutral: {
    bg: 'bg-muted/40',
    border: 'border-border/60',
    icon: 'text-muted-foreground',
  },
};

export function SmartActionCard({
  label,
  status,
  detail,
  hint,
  badge,
  icon: Icon,
  accent = 'neutral',
  isActive = false,
  onPress,
  onLongPress,
}: SmartActionCardProps) {
  const longPressTimer = useRef<NodeJS.Timeout | null>(null);
  const longPressTriggered = useRef(false);

  const handlePressStart = () => {
    if (!onLongPress) return;
    longPressTriggered.current = false;
    longPressTimer.current = setTimeout(() => {
      longPressTriggered.current = true;
      onLongPress();
    }, 450);
  };

  const clearTimer = () => {
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
  };

  const handlePressEnd = () => {
    clearTimer();
  };

  const handleClick = () => {
    if (longPressTriggered.current) return;
    onPress();
  };

  useEffect(() => clearTimer, []);

  const accentStyles = ACCENT_STYLES[accent];

  return (
    <button
      type='button'
      className={cn(
        'w-full text-left rounded-xl border-2 p-4 shadow-soft transition-all duration-200',
        'flex flex-col gap-2.5 min-h-[132px] justify-between',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary',
        accentStyles.bg,
        accentStyles.border,
        isActive ? 'shadow-md scale-[1.01]' : getPressEffect()
      )}
      onClick={handleClick}
      onMouseDown={handlePressStart}
      onMouseUp={handlePressEnd}
      onMouseLeave={handlePressEnd}
      onTouchStart={handlePressStart}
      onTouchEnd={handlePressEnd}
      onTouchCancel={handlePressEnd}
      aria-label={label}
    >
      <div className='flex items-start justify-between gap-2'>
        <div className='flex items-start gap-3'>
          <div
            className={cn(
              'h-11 w-11 rounded-lg bg-background/80 border flex items-center justify-center',
              accentStyles.border,
              accentStyles.bg
            )}
          >
            <Icon className={cn('h-6 w-6', accentStyles.icon)} strokeWidth={2.25} />
          </div>
          <div className='space-y-0.5'>
            <div className='flex items-center gap-2'>
              <p className='text-base font-semibold leading-tight'>{label}</p>
              {badge && (
                <span className='text-[10px] px-2 py-0.5 rounded-full bg-primary/10 text-primary font-medium'>
                  {badge}
                </span>
              )}
            </div>
            {status && <p className='text-sm font-medium text-foreground'>{status}</p>}
            {detail && <p className='text-xs text-muted-foreground leading-snug'>{detail}</p>}
          </div>
        </div>
        {isActive && (
          <span className='text-[11px] px-2 py-1 rounded-full bg-primary text-primary-foreground font-semibold'>
            Live
          </span>
        )}
      </div>
      {hint && <p className='text-[11px] text-muted-foreground'>{hint}</p>}
    </button>
  );
}
