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
      <Card>
        <CardContent className="p-3 text-center">
          <Milk className="h-5 w-5 mx-auto mb-1 text-blue-500" />
          <div className="text-xs text-muted-foreground">Feeds</div>
          <div className="font-bold text-lg">{summary.feedCount}</div>
          {summary.totalMl > 0 && (
            <div className="text-xs text-muted-foreground">{summary.totalMl} ml</div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-3 text-center">
          <Moon className="h-5 w-5 mx-auto mb-1 text-purple-500" />
          <div className="text-xs text-muted-foreground">Sleep</div>
          <div className="font-bold text-lg">
            {sleepHours > 0 ? `${sleepHours}h` : ''} {sleepMins}m
          </div>
          {summary.sleepCount > 0 && (
            <div className="text-xs text-muted-foreground">
              {summary.sleepCount} {summary.sleepCount === 1 ? 'nap' : 'naps'}
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-3 text-center">
          <Baby className="h-5 w-5 mx-auto mb-1 text-green-500" />
          <div className="text-xs text-muted-foreground">Diapers</div>
          <div className="font-bold text-lg">{summary.diaperTotal}</div>
          {summary.diaperTotal > 0 && (
            <div className="text-xs text-muted-foreground">
              💧{summary.diaperWet} 💩{summary.diaperDirty}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
