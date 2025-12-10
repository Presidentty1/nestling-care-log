import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { CalendarDays, Share } from 'lucide-react';
import { MobileNav } from '@/components/MobileNav';
import { DayStrip } from '@/components/history/DayStrip';
import { DaySummary } from '@/components/history/DaySummary';
import { EmptyState } from '@/components/common/EmptyState';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { TimelineList } from '@/components/today/TimelineList';
import { useAppStore } from '@/store/appStore';
import { eventsService, type EventRecord } from '@/services/eventsService';
import { babyService } from '@/services/babyService';
import { logger } from '@/lib/logger';
import { toast } from 'sonner';
import { startOfDay, endOfDay } from 'date-fns';
import type { DailySummary } from '@/types/summary';
import { DoctorShareModal } from '@/components/DoctorShareModal';
import { Button } from '@/components/ui/button';
import { EventSheet } from '@/components/sheets/EventSheet';
import type { EventType } from '@/types/events';
import { undoManager } from '@/lib/undoManager';
import { analyticsService } from '@/services/analyticsService';
import { track } from '@/analytics/analytics';

export default function History() {
  const { activeBabyId } = useAppStore();
  const [familyId, setFamilyId] = useState<string>('');
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [summary, setSummary] = useState<DailySummary | null>(null);
  const [babyName, setBabyName] = useState<string>('');
  const [babySex, setBabySex] = useState<string>('');
  const [babyBirthDate, setBabyBirthDate] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [showDoctorShareModal, setShowDoctorShareModal] = useState(false);
  const [editModalState, setEditModalState] = useState<{
    open: boolean;
    event: EventRecord | null;
  }>({
    open: false,
    event: null,
  });

  const loadBaby = useCallback(async () => {
    if (!activeBabyId) return;
    const baby = await babyService.getBaby(activeBabyId);
    if (baby) {
      setBabyName(baby.name);
      setBabySex(baby.sex || '');
      setBabyBirthDate(baby.date_of_birth);
      setFamilyId(baby.family_id); // Set familyId from baby data
    }
  }, [activeBabyId]);

  const loadDayData = useCallback(async () => {
    if (!activeBabyId) return;

    setLoading(true);
    try {
      const start = startOfDay(selectedDate);
      const end = endOfDay(selectedDate);

      const dayEvents = await eventsService.getEventsByRange(
        activeBabyId,
        start.toISOString(),
        end.toISOString()
      );

      setEvents(dayEvents);

      const totals = eventsService.calculateSummary(dayEvents);
      setSummary(totals);
    } catch (error) {
      logger.error('Failed to load day data', error, 'History');
      toast.error("Couldn't load events. Try again?");
    } finally {
      setLoading(false);
    }
  }, [activeBabyId, selectedDate]);

  useEffect(() => {
    if (!activeBabyId) return;
    loadBaby();
  }, [activeBabyId, loadBaby]);

  useEffect(() => {
    if (!activeBabyId) return;
    loadDayData();
  }, [activeBabyId, selectedDate, loadDayData]);

  const handleDelete = async (eventId: string) => {
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
          await loadDayData();
          toast.success('Event restored');
        } catch (error) {
          logger.error('Failed to restore event', error, 'History');
          toast.error('Failed to restore event');
        }
      });

      // Delete the event
      await eventsService.deleteEvent(eventId);
      await loadDayData();

      // Show toast with undo button
      toast.success('Event deleted', {
        action: {
          label: 'Undo',
          onClick: async () => {
            try {
              await undoManager.undo();
              analyticsService.trackEventDeleted(
                eventId,
                eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time'
              );
              track('undo_action', { action_type: 'event_deleted' });
            } catch (error) {
              if (error instanceof Error && error.message.includes('expired')) {
                toast.error('Undo window has expired');
              } else {
                logger.error('Failed to undo deletion', error, 'History');
                toast.error('Failed to undo');
              }
            }
          },
        },
        duration: 7000, // Match undo window
      });

      // Track analytics
      analyticsService.trackEventDeleted(
        eventId,
        eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time'
      );
      track('event_deleted', {
        event_type: eventToDelete.type,
        undo_available: true,
      });
    } catch (error) {
      logger.error('Failed to delete event', error, 'History');
      toast.error("Couldn't remove that. Try again?");
      undoManager.clear(); // Clear undo if delete failed
    }
  };

  const handleEdit = (event: EventRecord) => {
    setEditModalState({ open: true, event });
  };

  const handleEditClose = () => {
    setEditModalState({ open: false, event: null });
    loadDayData(); // Reload data after edit
  };

  if (!activeBabyId) {
    return (
      <div className='min-h-screen bg-background pb-20 overflow-x-hidden'>
        <div className='max-w-2xl mx-auto p-4 w-full'>
          <EmptyState
            icon={CalendarDays}
            title='No Baby Selected'
            description='Select or add a baby to see their history'
            action={{ label: 'Go to Home', onClick: () => (window.location.href = '/home') }}
          />
        </div>
        <MobileNav />
      </div>
    );
  }

  return (
    <div className='min-h-screen bg-background pb-20 overflow-x-hidden'>
      <div className='max-w-2xl mx-auto p-4 space-y-4 w-full'>
        {/* Header */}
        <div className='flex items-center justify-between'>
          <h1 className='font-display text-left'>History</h1>
          <Button variant='outline' size='sm' onClick={() => setShowDoctorShareModal(true)}>
            <Share className='h-4 w-4 mr-2' />
            Share with Doctor
          </Button>
        </div>

        {/* Day Strip */}
        <DayStrip selectedDate={selectedDate} onDateSelect={setSelectedDate} />

        {/* Loading State */}
        {loading && (
          <div className='flex justify-center py-8'>
            <LoadingSpinner />
          </div>
        )}

        {/* Empty State */}
        {!loading && events.length === 0 && (
          <EmptyState
            icon={CalendarDays}
            title='Nothing logged this day'
            description="Babies have calm days too! 🌙 It's perfectly normal to have quiet stretches."
          />
        )}

        {/* Day Summary */}
        {!loading && events.length > 0 && summary && (
          <DaySummary date={selectedDate} summary={summary} />
        )}

        {/* Events Timeline */}
        {!loading && events.length > 0 && (
          <Card>
            <CardHeader>
              <h2 className='text-title'>Timeline</h2>
            </CardHeader>
            <CardContent>
              <TimelineList events={events} onEdit={handleEdit} onDelete={handleDelete} />
            </CardContent>
          </Card>
        )}
      </div>
      <MobileNav />

      {/* Doctor Share Modal */}
      {activeBabyId && (
        <DoctorShareModal
          open={showDoctorShareModal}
          onOpenChange={setShowDoctorShareModal}
          babyId={activeBabyId}
          babyName={babyName}
          babySex={babySex}
          babyBirthDate={babyBirthDate}
        />
      )}

      {/* Edit Event Sheet */}
      {activeBabyId && familyId && editModalState.event && (
        <EventSheet
          isOpen={editModalState.open}
          onClose={handleEditClose}
          eventType={editModalState.event.type as EventType}
          babyId={activeBabyId}
          familyId={familyId}
          editingEventId={editModalState.event.id}
          prefillData={editModalState.event}
        />
      )}
    </div>
  );
}
