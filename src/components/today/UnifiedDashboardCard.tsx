import { format, differenceInMinutes } from 'date-fns';
import { Card, CardContent } from '@/components/ui/card';
import { Milk, Droplet, Moon, Timer, CheckCircle2, CloudOff, RefreshCw } from 'lucide-react';
import type { DailySummary } from '@/types/summary';
import type { EventRecord } from '@/services/eventsService';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { offlineQueue } from '@/lib/offlineQueue';
import { useState, useEffect } from 'react';
import { cn } from '@/lib/utils';

interface UnifiedDashboardCardProps {
  events: EventRecord[];
  napWindow?: { start: Date; end: Date; reason: string } | null;
  summary: DailySummary | null;
  activeSleepTimer?: { startTime: Date; isRunning: boolean } | null;
}

export function UnifiedDashboardCard({
  events,
  napWindow,
  summary,
  activeSleepTimer,
}: UnifiedDashboardCardProps) {
  const { isOnline } = useNetworkStatus();
  const [syncStatus, setSyncStatus] = useState<{ pending: number; isSyncing: boolean }>({
    pending: 0,
    isSyncing: false,
  });

  useEffect(() => {
    const updateSyncStatus = () => {
      const status = offlineQueue.getStatus();
      setSyncStatus({ pending: status.pending, isSyncing: false });
    };
    updateSyncStatus();
    const interval = setInterval(updateSyncStatus, 2000);
    return () => clearInterval(interval);
  }, []);

  // Calculate last feed time
  const lastFeed = events
    .filter(e => e.type === 'feed')
    .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0];
  const timeSinceLastFeed = lastFeed
    ? differenceInMinutes(new Date(), new Date(lastFeed.start_time))
    : null;

  // Calculate last diaper time
  const lastDiaper = events
    .filter(e => e.type === 'diaper')
    .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0];
  const timeSinceLastDiaper = lastDiaper
    ? differenceInMinutes(new Date(), new Date(lastDiaper.start_time))
    : null;

  // Calculate time until next nap
  const now = new Date();
  const timeUntilNextNap =
    napWindow && napWindow.start > now ? differenceInMinutes(napWindow.start, now) : null;

  // Calculate active sleep duration
  const sleepDuration = activeSleepTimer?.isRunning
    ? differenceInMinutes(now, activeSleepTimer.startTime)
    : null;

  const formatTime = (minutes: number) => {
    if (minutes < 60) return `${minutes}m`;
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
  };

  const formatNapWindow = () => {
    if (!napWindow) return null;
    const start = format(napWindow.start, 'h:mm');
    const end = format(napWindow.end, 'h:mma').toLowerCase();
    return `${start}–${end}`;
  };

  return (
    <Card className='border-2 border-border bg-card shadow-soft animate-in fade-in slide-in-from-top-2 duration-300'>
      <CardContent className='p-4 space-y-4'>
        {/* Header with sync indicator */}
        <div className='flex items-center justify-between'>
          <h2 className='font-title text-foreground'>Right Now</h2>
          {/* Small sync indicator */}
          <div className='flex items-center gap-1.5'>
            {isOnline ? (
              syncStatus.pending > 0 ? (
                <div className='flex items-center gap-1 text-xs text-muted-foreground'>
                  <RefreshCw className='h-3.5 w-3.5 animate-spin text-primary' />
                  <span className='hidden sm:inline'>Syncing</span>
                </div>
              ) : (
                <div className='flex items-center gap-1 text-xs text-muted-foreground'>
                  <CheckCircle2 className='h-3.5 w-3.5 text-success' />
                  <span className='hidden sm:inline'>Synced</span>
                </div>
              )
            ) : (
              <div className='flex items-center gap-1 text-xs text-muted-foreground'>
                <CloudOff className='h-3.5 w-3.5' />
                <span className='hidden sm:inline'>Offline</span>
              </div>
            )}
          </div>
        </div>

        {/* Dashboard items in grid */}
        <div className='grid grid-cols-2 gap-3'>
          {/* Last Feed */}
          <div className='flex items-start gap-2.5 p-2.5 rounded-lg bg-event-feed/5 border border-event-feed/20'>
            <Milk className='h-5 w-5 text-event-feed flex-shrink-0 mt-0.5' />
            <div className='flex-1 min-w-0'>
              <div className='text-xs text-muted-foreground mb-0.5'>Last Feed</div>
              {timeSinceLastFeed !== null ? (
                <div className='text-sm font-semibold text-foreground'>
                  {formatTime(timeSinceLastFeed)} ago
                </div>
              ) : (
                <div className='text-sm font-semibold text-muted-foreground'>—</div>
              )}
            </div>
          </div>

          {/* Last Diaper */}
          <div className='flex items-start gap-2.5 p-2.5 rounded-lg bg-event-diaper/5 border border-event-diaper/20'>
            <Droplet className='h-5 w-5 text-event-diaper flex-shrink-0 mt-0.5' />
            <div className='flex-1 min-w-0'>
              <div className='text-xs text-muted-foreground mb-0.5'>Last Diaper</div>
              {timeSinceLastDiaper !== null ? (
                <div className='text-sm font-semibold text-foreground'>
                  {formatTime(timeSinceLastDiaper)} ago
                </div>
              ) : (
                <div className='text-sm font-semibold text-muted-foreground'>—</div>
              )}
            </div>
          </div>

          {/* Active Sleep Timer */}
          {activeSleepTimer?.isRunning && sleepDuration !== null && (
            <div className='flex items-start gap-2.5 p-2.5 rounded-lg bg-event-sleep/5 border border-event-sleep/20 col-span-2'>
              <Timer className='h-5 w-5 text-event-sleep flex-shrink-0 mt-0.5 animate-pulse' />
              <div className='flex-1 min-w-0'>
                <div className='text-xs text-muted-foreground mb-0.5'>Sleep Timer</div>
                <div className='text-sm font-semibold text-foreground'>
                  {formatTime(sleepDuration)} and counting
                </div>
              </div>
            </div>
          )}

          {/* Next Nap Prediction */}
          {napWindow && (
            <div
              className={cn(
                'flex items-start gap-2.5 p-2.5 rounded-lg border col-span-2',
                timeUntilNextNap !== null && timeUntilNextNap <= 30
                  ? 'bg-warning/5 border-warning/20'
                  : 'bg-event-sleep/5 border-event-sleep/20'
              )}
            >
              <Moon className='h-5 w-5 text-event-sleep flex-shrink-0 mt-0.5' />
              <div className='flex-1 min-w-0'>
                <div className='flex items-center gap-1.5 mb-0.5'>
                  <div className='text-xs text-muted-foreground'>Next Nap</div>
                  <span className='text-[10px] px-1.5 py-0.5 rounded bg-primary/10 text-primary font-medium'>
                    Suggestion
                  </span>
                </div>
                {formatNapWindow() && (
                  <div className='text-sm font-semibold text-foreground mb-1'>
                    {formatNapWindow()}
                    {timeUntilNextNap !== null && timeUntilNextNap > 0 && (
                      <span className='ml-1.5 text-xs font-normal text-muted-foreground'>
                        (in {formatTime(timeUntilNextNap)})
                      </span>
                    )}
                  </div>
                )}
                <div className='text-[11px] text-muted-foreground leading-tight'>
                  Based on age and last wake time
                </div>
              </div>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
