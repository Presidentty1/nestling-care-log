import { Card, CardContent } from '@/components/ui/card';
import { Milk, Moon, Baby } from 'lucide-react';

interface SummaryChipsProps {
  summary: {
    feedCount: number;
    totalMl: number;
    sleepMinutes: number;
    sleepCount: number;
    diaperWet: number;
    diaperDirty: number;
    diaperTotal: number;
  };
}

export function SummaryChips({ summary }: SummaryChipsProps) {
  const sleepHours = Math.floor(summary.sleepMinutes / 60);
  const sleepMins = summary.sleepMinutes % 60;

  return (
    <div className="grid grid-cols-3 gap-3">
      {/* Feed Chip */}
      <Card className="shadow-soft">
        <CardContent className="p-4 text-center space-y-2">
          <Milk className="h-6 w-6 mx-auto text-primary" />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {summary.feedCount}
            </div>
            <div className="text-secondary text-muted-foreground">Feeds</div>
            {summary.totalMl > 0 && (
              <div className="text-caption text-text-subtle">
                {summary.totalMl} ml
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Sleep Chip */}
      <Card className="shadow-soft">
        <CardContent className="p-4 text-center space-y-2">
          <Moon className="h-6 w-6 mx-auto text-primary" />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {sleepHours > 0 ? `${sleepHours}h` : ''} {sleepMins}m
            </div>
            <div className="text-secondary text-muted-foreground">Sleep</div>
            {summary.sleepCount > 0 && (
              <div className="text-caption text-text-subtle">
                {summary.sleepCount} {summary.sleepCount === 1 ? 'nap' : 'naps'}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Diaper Chip */}
      <Card className="shadow-soft">
        <CardContent className="p-4 text-center space-y-2">
          <Baby className="h-6 w-6 mx-auto text-primary" />
          <div className="space-y-1">
            <div className="text-[28px] leading-[34px] font-semibold tabular-nums">
              {summary.diaperTotal}
            </div>
            <div className="text-secondary text-muted-foreground">Diapers</div>
            {summary.diaperTotal > 0 && (
              <div className="text-caption text-text-subtle">
                💧{summary.diaperWet} 💩{summary.diaperDirty}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
