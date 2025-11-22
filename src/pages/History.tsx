import { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { CalendarDays } from 'lucide-react';
import { MobileNav } from '@/components/MobileNav';
import { DayStrip } from '@/components/history/DayStrip';
import { DaySummary } from '@/components/history/DaySummary';
import { EmptyState } from '@/components/common/EmptyState';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { TimelineList } from '@/components/today/TimelineList';
import { useAppStore } from '@/store/appStore';
import type { EventRecord } from '@/services/eventsService';
import { eventsService } from '@/services/eventsService';
import { babyService } from '@/services/babyService';
import { logger } from '@/lib/logger';
import { toast } from 'sonner';
import { startOfDay, endOfDay } from 'date-fns';
import type { DailySummary } from '@/types/summary';
import { DoctorShareModal } from '@/components/DoctorShareModal';
import { Share } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { EventSheet } from '@/components/sheets/EventSheet';
import type { EventType } from '@/types/events';

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
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);
  const [showDoctorShareModal, setShowDoctorShareModal] = useState(false);
  const [editModalState, setEditModalState] = useState<{ open: boolean; event: EventRecord | null }>({
    open: false,
    event: null,
  });

  useEffect(() => {
    if (!activeBabyId) return;
    loadBaby();
  }, [activeBabyId]);

  useEffect(() => {
    if (!activeBabyId) return;
    loadDayData();
  }, [activeBabyId, selectedDate]);

  const loadBaby = async () => {
    if (!activeBabyId) return;
    const baby = await babyService.getBaby(activeBabyId);
    if (baby) {
      setBabyName(baby.name);
      setBabySex(baby.sex || '');
      setBabyBirthDate(baby.date_of_birth);
      setFamilyId(baby.family_id); // Set familyId from baby data
    }
  };

  const loadDayData = async () => {
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
  };

  const handleDelete = async (eventId: string) => {
    try {
      await eventsService.deleteEvent(eventId);
      toast.success('Removed!');
      loadDayData();
    } catch (error) {
      toast.error("Couldn't remove that. Try again?");
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
      <div className="min-h-screen bg-surface pb-20">
        <div className="max-w-2xl mx-auto p-4">
          <EmptyState
            icon={CalendarDays}
            title="No Baby Selected"
            description="Select or add a baby to see their history"
            action={{ label: 'Go to Home', onClick: () => window.location.href = '/home' }}
          />
        </div>
        <MobileNav />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="font-display text-left">History</h1>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowDoctorShareModal(true)}
          >
            <Share className="h-4 w-4 mr-2" />
            Share with Doctor
          </Button>
        </div>

        {/* Day Strip with Calendar */}
        <DayStrip 
          selectedDate={selectedDate}
          onDateSelect={setSelectedDate}
          onOpenCalendar={() => setIsCalendarOpen(true)}
        />

        {/* Calendar Picker */}
        <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
          <PopoverTrigger asChild>
            <div className="hidden" />
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="center">
            <Calendar
              mode="single"
              selected={selectedDate}
              onSelect={(date) => {
                if (date) {
                  setSelectedDate(date);
                  setIsCalendarOpen(false);
                }
              }}
              disabled={(date) => date > new Date()}
            />
          </PopoverContent>
        </Popover>

        {/* Loading State */}
        {loading && (
          <div className="flex justify-center py-8">
            <LoadingSpinner />
          </div>
        )}

        {/* Empty State */}
        {!loading && events.length === 0 && (
          <EmptyState
            icon={CalendarDays}
            title="Nothing logged this day"
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
              <h2 className="text-title">Timeline</h2>
            </CardHeader>
            <CardContent>
              <TimelineList
                events={events}
                onEdit={handleEdit}
                onDelete={handleDelete}
              />
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
