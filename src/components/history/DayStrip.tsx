import { Button } from '@/components/ui/button';
import { Calendar } from 'lucide-react';
import { format, subDays, isSameDay, isToday, isFuture } from 'date-fns';
import { cn } from '@/lib/utils';

interface DayStripProps {
  selectedDate: Date;
  onDateSelect: (date: Date) => void;
  onOpenCalendar: () => void;
}

export function DayStrip({ selectedDate, onDateSelect, onOpenCalendar }: DayStripProps) {
  const days = Array.from({ length: 7 }, (_, i) => subDays(new Date(), 6 - i));

  return (
    <div className="flex items-center gap-2 overflow-x-auto pb-2">
      <div className="flex gap-2">
        {days.map((day) => {
          const isSelected = isSameDay(day, selectedDate);
          const isDisabled = isFuture(day);
          const today = isToday(day);

          return (
            <button
              key={day.toISOString()}
              onClick={() => !isDisabled && onDateSelect(day)}
              disabled={isDisabled}
              className={cn(
                'flex flex-col items-center justify-center min-w-[60px] h-16 rounded-lg border-2 transition-all',
                'hover:border-primary/50 active:scale-95',
                isSelected && 'border-primary bg-primary/10',
                !isSelected && 'border-border bg-card',
                isDisabled && 'opacity-50 cursor-not-allowed',
                today && !isSelected && 'border-primary/30'
              )}
            >
              <span className={cn(
                'text-xs font-medium',
                isSelected ? 'text-primary' : 'text-muted-foreground'
              )}>
                {format(day, 'EEE')}
              </span>
              <span className={cn(
                'text-lg font-bold',
                isSelected ? 'text-primary' : 'text-foreground'
              )}>
                {format(day, 'd')}
              </span>
              {today && (
                <span className="text-[10px] text-primary">Today</span>
              )}
            </button>
          );
        })}
      </div>

      <Button
        variant="outline"
        size="icon"
        onClick={onOpenCalendar}
        className="shrink-0 h-16 w-16"
      >
        <Calendar className="h-5 w-5" />
      </Button>
    </div>
  );
}
