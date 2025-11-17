import { format } from 'date-fns';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Milk, Moon, Baby } from 'lucide-react';
import { DailySummary } from '@/types/summary';

interface DaySummaryProps {
  date: Date;
  summary: DailySummary;
}

export function DaySummary({ date, summary }: DaySummaryProps) {
  const sleepMinutes = summary.sleepMinutes || 0;
  const sleepHours = Math.floor(sleepMinutes / 60);
  const sleepMins = sleepMinutes % 60;

  const formatSleepTime = () => {
    if (sleepMinutes === 0) return '—';
    if (sleepHours > 0) return `${sleepHours}h ${sleepMins}m`;
    return `${sleepMins}m`;
  };

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
            <div className="font-bold text-lg">{summary.feedCount || 0}</div>
            {summary.totalMl > 0 && (
              <div className="text-xs text-muted-foreground">{Math.round(summary.totalMl)} ml</div>
            )}
          </div>

          <div className="text-center p-3 rounded-lg bg-muted/50">
            <Moon className="h-5 w-5 mx-auto mb-1 text-purple-500" />
            <div className="text-xs text-muted-foreground">Sleep</div>
            <div className="font-bold text-lg">{formatSleepTime()}</div>
            {summary.sleepCount > 0 && (
              <div className="text-xs text-muted-foreground">
                {summary.sleepCount} {summary.sleepCount === 1 ? 'nap' : 'naps'}
              </div>
            )}
          </div>

          <div className="text-center p-3 rounded-lg bg-muted/50">
            <Baby className="h-5 w-5 mx-auto mb-1 text-green-500" />
            <div className="text-xs text-muted-foreground">Diapers</div>
            <div className="font-bold text-lg">{summary.diaperTotal || 0}</div>
            {summary.diaperTotal > 0 && (
              <div className="text-xs text-muted-foreground">
                💧{summary.diaperWet || 0} 💩{summary.diaperDirty || 0}
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
