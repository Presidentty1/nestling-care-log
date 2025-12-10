import type { BabyEvent } from '@/lib/types';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby as BabyIcon, Trash2, Edit } from 'lucide-react';
import { formatDistanceToNow, format, isToday } from 'date-fns';
import { useState } from 'react';
import { toast } from 'sonner';
import { undoManager } from '@/lib/undoManager';
import { eventsService } from '@/services/eventsService';
import { analyticsService } from '@/services/analyticsService';
import { track } from '@/analytics/analytics';
import { logger } from '@/lib/logger';

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
  const handleDeleteWithUndo = async (eventId: string) => {
    try {
      // Get event before deleting for undo
      const eventToDelete = events.find(e => e.id === eventId);
      if (!eventToDelete) {
        toast.error('Event not found');
        return;
      }

      // Register deletion with undo manager
      undoManager.registerDeletion(eventToDelete, async () => {
        // Restore action: recreate the event
        try {
          const restoreData: Parameters<typeof eventsService.createEvent>[0] = {
            baby_id: eventToDelete.baby_id,
            family_id: eventToDelete.family_id,
            type: eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time',
            subtype: eventToDelete.subtype || undefined,
            amount: eventToDelete.amount || undefined,
            unit: (eventToDelete.unit as 'ml' | 'oz') || undefined,
            start_time: eventToDelete.start_time,
            end_time: eventToDelete.end_time || undefined,
            duration_min: eventToDelete.duration_min || undefined,
            duration_sec: eventToDelete.duration_sec || undefined,
            note: eventToDelete.note || undefined,
          };
          await eventsService.createEvent(restoreData);
          toast.success('Event restored');
          // Parent component should refresh via React Query or eventsService subscription
        } catch (error) {
          logger.error('Failed to restore event', error, 'EventTimeline');
          toast.error('Failed to restore event');
        }
      });

      // Delete the event
      await eventsService.deleteEvent(eventId);
      onDelete(eventId); // Notify parent

      // Show toast with undo button
      toast.success('Event deleted', {
        action: {
          label: 'Undo',
          onClick: async () => {
            try {
              await undoManager.undo();
              analyticsService.trackEventDeleted(eventId, eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time');
              track('undo_action', { action_type: 'event_deleted' });
            } catch (error) {
              if (error instanceof Error && error.message.includes('expired')) {
                toast.error('Undo window has expired');
              } else {
                logger.error('Failed to undo deletion', error, 'EventTimeline');
                toast.error('Failed to undo');
              }
            }
          },
        },
        duration: 7000, // Match undo window
      });

      // Track analytics
      analyticsService.trackEventDeleted(eventId, eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time');
      track('event_deleted', {
        event_type: eventToDelete.type,
        undo_available: true,
      });
    } catch (error) {
      logger.error('Failed to delete event', error, 'EventTimeline');
      toast.error('Failed to delete event');
      undoManager.clear(); // Clear undo if delete failed
    }
  };
  
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
      const duration = event.duration_sec || 
        Math.round((new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 1000);
      
      if (duration < 60) {
        title += ` · ${duration}s`;
      } else if (duration < 3600) {
        const mins = Math.floor(duration / 60);
        const secs = duration % 60;
        title += secs > 0 ? ` · ${mins}m ${secs}s` : ` · ${mins}m`;
      } else {
        const hours = Math.floor(duration / 3600);
        const mins = Math.floor((duration % 3600) / 60);
        title += mins > 0 ? ` · ${hours}h ${mins}m` : ` · ${hours}h`;
      }
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
                                  onClick={() => handleDeleteWithUndo(event.id)}
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

    </>
  );
}
