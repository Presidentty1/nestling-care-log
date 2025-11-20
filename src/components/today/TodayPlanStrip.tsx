import { format, differenceInMinutes } from 'date-fns';
import { Clock, Timer } from 'lucide-react';
import { EventRecord, DailySummary } from '@/types/events';

interface TodayPlanStripProps {
  events: EventRecord[];
  napWindow?: { start: Date; end: Date; reason: string } | null;
  summary: DailySummary | null;
}

export function TodayPlanStrip({ events, napWindow, summary }: TodayPlanStripProps) {
  // Calculate time since last feed
  const lastFeed = events
    .filter(e => e.type === 'feed')
    .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0];

  const timeSinceLastFeed = lastFeed
    ? differenceInMinutes(new Date(), new Date(lastFeed.start_time))
    : null;

  // Calculate time until next nap window
  const now = new Date();
  const timeUntilNextNap = napWindow && napWindow.start > now
    ? differenceInMinutes(napWindow.start, now)
    : null;

  const formatNapWindow = () => {
    if (!napWindow) return null;
    const start = format(napWindow.start, 'h:mm');
    const end = format(napWindow.end, 'h:mma').toLowerCase();
    return `${start}–${end}`;
  };

  const formatTime = (minutes: number) => {
    if (minutes < 60) return `${minutes}m`;
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
  };

  return (
    <div className="bg-background border border-border rounded-lg p-3 mb-4">
      <div className="flex items-center gap-3 text-sm text-muted-foreground">
        <div className="flex items-center gap-1">
          <Timer className="h-4 w-4" />
          <span className="font-medium text-foreground">Now:</span>
        </div>

        {/* Last feed */}
        {timeSinceLastFeed !== null && (
          <span className="text-event-feed">
            last feed {formatTime(timeSinceLastFeed)} ago
          </span>
        )}

        {/* Next nap window */}
        {napWindow && (
          <span className="text-event-sleep">
            next nap {formatNapWindow()}
            {timeUntilNextNap !== null && timeUntilNextNap > 0 && (
              <span className="ml-1 text-xs">
                (≈ in {formatTime(timeUntilNextNap)})
              </span>
            )}
          </span>
        )}

        {/* Diapers so far today */}
        {summary && summary.diaperTotal > 0 && (
          <span className="text-event-diaper">
            {summary.diaperTotal} diaper{summary.diaperTotal !== 1 ? 's' : ''} so far today
          </span>
        )}
      </div>
    </div>
  );
}
