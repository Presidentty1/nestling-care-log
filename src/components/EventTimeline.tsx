import { BabyEvent } from '@/lib/types';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby as BabyIcon, Trash2, Edit } from 'lucide-react';
import { formatDistanceToNow, format, isToday } from 'date-fns';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { useState } from 'react';

interface EventTimelineProps {
  events: BabyEvent[];
  onEdit: (event: BabyEvent) => void;
  onDelete: (eventId: string) => void;
}

type TimeBand = 'morning' | 'afternoon' | 'evening' | 'night';

function getTimeBand(date: Date): TimeBand {
  const hour = date.getHours();
  if (hour >= 6 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 18) return 'afternoon';
  if (hour >= 18 && hour < 24) return 'evening';
  return 'night';
}

function groupEventsByTimeBand(events: BabyEvent[]) {
  const groups: Record<TimeBand, BabyEvent[]> = {
    morning: [],
    afternoon: [],
    evening: [],
    night: [],
  };

  events.forEach((event) => {
    const band = getTimeBand(new Date(event.start_time));
    groups[band].push(event);
  });

  return groups;
}

const timeBandLabels: Record<TimeBand, string> = {
  morning: 'Morning (6 AM - 12 PM)',
  afternoon: 'Afternoon (12 PM - 6 PM)',
  evening: 'Evening (6 PM - 12 AM)',
  night: 'Night (12 AM - 6 AM)',
};

const eventIcons = {
  feed: Milk,
  sleep: Moon,
  diaper: BabyIcon,
};

const eventColors = {
  feed: 'text-blue-500',
  sleep: 'text-purple-500',
  diaper: 'text-green-500',
};

export function EventTimeline({ events, onEdit, onDelete }: EventTimelineProps) {
  const [deleteId, setDeleteId] = useState<string | null>(null);
  
  if (events.length === 0) {
    return (
      <Card>
        <CardContent className="p-8 text-center text-muted-foreground">
          No events logged yet. Tap a button above to get started!
        </CardContent>
      </Card>
    );
  }

  const grouped = groupEventsByTimeBand(events);
  const bands: TimeBand[] = ['morning', 'afternoon', 'evening', 'night'];

  const formatEventTitle = (event: BabyEvent) => {
    let title = event.type.charAt(0).toUpperCase() + event.type.slice(1);
    
    if (event.subtype) {
      if (event.subtype.startsWith('breast_')) {
        const side = event.subtype.replace('breast_', '');
        title += ` · ${side.charAt(0).toUpperCase() + side.slice(1)}`;
      } else {
        title += ` · ${event.subtype.charAt(0).toUpperCase() + event.subtype.slice(1)}`;
      }
    }

    if (event.amount && event.unit) {
      title += ` · ${event.amount}${event.unit}`;
    }

    if (event.end_time) {
      const start = new Date(event.start_time);
      const end = new Date(event.end_time);
      const duration = Math.round((end.getTime() - start.getTime()) / 60000);
      title += ` · ${duration} min`;
    }

    return title;
  };

  return (
    <>
      <div className="space-y-6">
        {bands.map((band) => {
          const bandEvents = grouped[band];
          if (bandEvents.length === 0) return null;

          return (
            <div key={band}>
              <h3 className="text-sm font-medium text-muted-foreground mb-3">
                {timeBandLabels[band]}
              </h3>
              <div className="space-y-2">
                {bandEvents.map((event) => {
                  const Icon = eventIcons[event.type] || BabyIcon;
                  const color = eventColors[event.type] || 'text-gray-500';

                  return (
                    <Card key={event.id} className="overflow-hidden">
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <div className={`mt-1 ${color}`}>
                            <Icon className="h-5 w-5" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <div className="flex-1 min-w-0">
                                <p className="font-medium text-sm">
                                  {formatEventTitle(event)}
                                </p>
                                <p className="text-xs text-muted-foreground mt-1">
                                  {isToday(new Date(event.start_time))
                                    ? formatDistanceToNow(new Date(event.start_time), {
                                        addSuffix: true,
                                      })
                                    : format(new Date(event.start_time), 'h:mm a')}
                                </p>
                                {event.note && (
                                  <p className="text-sm text-muted-foreground mt-2 line-clamp-2">
                                    {event.note}
                                  </p>
                                )}
                              </div>
                              <div className="flex gap-1">
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => onEdit(event)}
                                >
                                  <Edit className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => setDeleteId(event.id)}
                                >
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>

      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Event</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this event? This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (deleteId) {
                  onDelete(deleteId);
                  setDeleteId(null);
                }
              }}
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
