import { memo } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Milk, Moon, Baby } from 'lucide-react';
import { DailySummary } from '@/types/summary';

interface SummaryChipsProps {
  summary: DailySummary;
}

export const SummaryChips = memo(function SummaryChips({ summary }: SummaryChipsProps) {
  // Defensive: ensure values are numbers
  const sleepMinutes = summary.sleepMinutes || 0;
  const sleepHours = Math.floor(sleepMinutes / 60);
  const sleepMins = sleepMinutes % 60;

  // Format sleep display for iOS polish
  const formatSleepTime = () => {
    if (sleepMinutes === 0) return '—'; // Em dash for zero state
    if (sleepHours > 0) return `${sleepHours}h ${sleepMins}m`;
    return `${sleepMins}m`;
  };

  return (
    <div className="grid grid-cols-3 gap-md">
      {/* Feed Chip */}
      <Card className="shadow-soft border-event-feed/20 bg-event-feed/5">
        <CardContent className="pt-5 px-md pb-md text-center space-y-sm">
          <Milk className="h-7 w-7 mx-auto text-event-feed" strokeWidth={2.5} />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {summary.feedCount || 0}
            </div>
            <div className="text-caption text-muted-foreground">Feeds</div>
            {summary.totalMl > 0 && (
              <div className="text-caption text-text-subtle">
                {Math.round(summary.totalMl)} ml
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Sleep Chip */}
      <Card className="shadow-soft border-event-sleep/20 bg-event-sleep/5">
        <CardContent className="pt-5 px-md pb-md text-center space-y-sm">
          <Moon className="h-7 w-7 mx-auto text-event-sleep" strokeWidth={2.5} />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {formatSleepTime()}
            </div>
            <div className="text-caption text-muted-foreground">Sleep</div>
            {summary.sleepCount > 0 && (
              <div className="text-caption text-text-subtle">
                {summary.sleepCount} {summary.sleepCount === 1 ? 'nap' : 'naps'}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Diaper Chip */}
      <Card className="shadow-soft border-event-diaper/20 bg-event-diaper/5">
        <CardContent className="pt-5 px-md pb-md text-center space-y-sm">
          <Baby className="h-7 w-7 mx-auto text-event-diaper" strokeWidth={2.5} />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {summary.diaperTotal || 0}
            </div>
            <div className="text-caption text-muted-foreground">Diapers</div>
            {summary.diaperTotal > 0 && (
              <div className="text-caption text-text-subtle">
                💧{summary.diaperWet || 0} 💩{summary.diaperDirty || 0}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
});
