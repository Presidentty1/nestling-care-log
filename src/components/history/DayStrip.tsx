import { format, subDays, isSameDay, isToday, isFuture, startOfDay } from 'date-fns';
import { cn } from '@/lib/utils';

interface DayStripProps {
  selectedDate: Date;
  onDateSelect: (date: Date) => void;
  onOpenCalendar?: () => void;
}

export function DayStrip({ selectedDate, onDateSelect }: DayStripProps) {
  // Generate 7 days: 6 days ago to today (left to right, oldest to newest)
  const today = startOfDay(new Date());
  const days = Array.from({ length: 7 }, (_, i) => {
    const day = subDays(today, 6 - i);
    return startOfDay(day);
  });

  return (
    <div className='flex items-center gap-3 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide'>
      <div className='flex gap-2.5 flex-nowrap'>
        {days.map(day => {
          const isSelected = isSameDay(day, selectedDate);
          const isDisabled = isFuture(day);
          const isTodayDate = isToday(day);

          // Show month abbreviation if it's the first day or if month changes
          const showMonth =
            day.getDate() === 1 ||
            (days.indexOf(day) > 0 && day.getMonth() !== days[days.indexOf(day) - 1]?.getMonth());

          return (
            <button
              key={day.toISOString()}
              onClick={() => !isDisabled && onDateSelect(day)}
              disabled={isDisabled}
              className={cn(
                'flex flex-col items-center justify-center min-w-[68px] h-[72px] rounded-2xl border-2 transition-all shrink-0',
                'active:scale-95',
                isSelected && 'border-primary bg-primary/10 shadow-sm',
                !isSelected && 'border-border bg-surface hover:border-primary/40',
                isDisabled && 'opacity-40 cursor-not-allowed',
                isTodayDate && !isSelected && 'border-primary/30 bg-primary/5'
              )}
            >
              <span
                className={cn(
                  'text-xs font-semibold mb-0.5',
                  isSelected ? 'text-primary' : 'text-muted-foreground'
                )}
              >
                {format(day, 'EEE')}
              </span>
              <span
                className={cn('text-xl font-bold', isSelected ? 'text-primary' : 'text-foreground')}
              >
                {format(day, 'd')}
              </span>
              {showMonth && (
                <span
                  className={cn(
                    'text-[9px] font-medium mt-0.5',
                    isSelected ? 'text-primary' : 'text-muted-foreground'
                  )}
                >
                  {format(day, 'MMM')}
                </span>
              )}
              {isTodayDate && !showMonth && (
                <span className='text-[9px] font-semibold text-primary mt-0.5'>Today</span>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
