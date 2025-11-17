import { format } from 'date-fns';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Milk, Moon, Baby } from 'lucide-react';

interface DaySummaryProps {
  date: Date;
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

export function DaySummary({ date, summary }: DaySummaryProps) {
  const sleepHours = Math.floor(summary.sleepMinutes / 60);
  const sleepMins = summary.sleepMinutes % 60;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">{format(date, 'EEEE, MMMM d')}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-3 gap-3">
          <div className="text-center p-3 rounded-lg bg-muted/50">
            <Milk className="h-5 w-5 mx-auto mb-1 text-blue-500" />
            <div className="text-xs text-muted-foreground">Feeds</div>
            <div className="font-bold text-lg">{summary.feedCount}</div>
            {summary.totalMl > 0 && (
              <div className="text-xs text-muted-foreground">{summary.totalMl} ml</div>
            )}
          </div>

          <div className="text-center p-3 rounded-lg bg-muted/50">
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
          </div>

          <div className="text-center p-3 rounded-lg bg-muted/50">
            <Baby className="h-5 w-5 mx-auto mb-1 text-green-500" />
            <div className="text-xs text-muted-foreground">Diapers</div>
            <div className="font-bold text-lg">{summary.diaperTotal}</div>
            {summary.diaperTotal > 0 && (
              <div className="text-xs text-muted-foreground">
                💧{summary.diaperWet} 💩{summary.diaperDirty}
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
