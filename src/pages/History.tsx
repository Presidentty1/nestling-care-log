import { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ChevronLeft, ChevronRight, CalendarDays } from 'lucide-react';
import { MobileNav } from '@/components/MobileNav';
import { EventTimeline } from '@/components/EventTimeline';
import { DayStrip } from '@/components/history/DayStrip';
import { DaySummary } from '@/components/history/DaySummary';
import { EmptyState } from '@/components/common/EmptyState';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { useAppStore } from '@/store/appStore';
import { dataService } from '@/services/dataService';
import { getDayTotals } from '@/store/selectors';
import { EventRecord, Baby } from '@/types/events';
import { BabyEvent } from '@/lib/types';
import { toast } from 'sonner';

export default function History() {
  const { activeBabyId } = useAppStore();
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [baby, setBaby] = useState<Baby | null>(null);
  const [loading, setLoading] = useState(true);
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);

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
    const b = await dataService.getBaby(activeBabyId);
    setBaby(b);
  };

  const loadDayData = async () => {
    if (!activeBabyId) return;
    
    setLoading(true);
    try {
      const dayISO = format(selectedDate, 'yyyy-MM-dd');
      const dayEvents = await dataService.listEventsByDay(activeBabyId, dayISO);
      
      // Map EventRecord to BabyEvent format
      const mappedEvents: BabyEvent[] = dayEvents.map(e => ({
        id: e.id,
        baby_id: e.babyId,
        family_id: e.familyId,
        type: e.type as any,
        subtype: e.subtype,
        start_time: e.startTime,
        end_time: e.endTime,
        amount: e.amount,
        unit: e.unit,
        note: e.notes,
        created_at: e.createdAt,
        updated_at: e.updatedAt,
        created_by: null,
      }));
      
      setEvents(mappedEvents);
      
      const totals = getDayTotals(dayEvents);
      setSummary(totals);
    } catch (error) {
      console.error('Failed to load day data:', error);
      toast.error('Failed to load events');
    } finally {
      setLoading(false);
    }
  };

  const goToPreviousDay = () => {
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() - 1);
    setSelectedDate(newDate);
  };

  const goToNextDay = () => {
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() + 1);
    setSelectedDate(newDate);
  };

  const handleDelete = async (eventId: string) => {
    try {
      await dataService.deleteEvent(eventId);
      toast.success('Event deleted');
      loadDayData();
    } catch (error) {
      toast.error('Failed to delete event');
    }
  };

  if (!activeBabyId) {
    return (
      <div className="min-h-screen bg-surface pb-20">
        <div className="max-w-2xl mx-auto p-4">
          <EmptyState
            icon={CalendarDays}
            title="No Baby Selected"
            description="Please select or create a baby to view history"
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
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">History</h1>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="icon"
              onClick={goToPreviousDay}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              onClick={goToNextDay}
              disabled={format(selectedDate, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>

        <Card className="p-4">
          <div className="mb-3">
            <h2 className="font-semibold text-lg mb-1">
              {format(selectedDate, 'EEEE, MMMM d, yyyy')}
            </h2>
          </div>
          <DayStrip
            selectedDate={selectedDate}
            onDateSelect={setSelectedDate}
            onOpenCalendar={() => setIsCalendarOpen(true)}
          />
        </Card>

        {summary && <DaySummary date={selectedDate} summary={summary} />}

        {loading ? (
          <LoadingSpinner text="Loading events..." />
        ) : events.length > 0 ? (
          <div>
            <h2 className="text-xl font-semibold mb-3">Timeline</h2>
            <EventTimeline
              events={events}
              onEdit={(event) => {
                toast.info('Edit functionality coming soon');
              }}
              onDelete={handleDelete}
            />
          </div>
        ) : (
          <EmptyState
            icon={CalendarDays}
            title="No Events Logged"
            description={`No activities were logged on ${format(selectedDate, 'MMMM d, yyyy')}`}
          />
        )}
      </div>

      <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
        <PopoverTrigger asChild>
          <div />
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
            initialFocus
          />
        </PopoverContent>
      </Popover>

      <MobileNav />
    </div>
  );
}
