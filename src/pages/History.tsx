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
import { eventsService, EventRecord } from '@/services/eventsService';
import { babyService } from '@/services/babyService';
import { toast } from 'sonner';
import { startOfDay, endOfDay } from 'date-fns';

export default function History() {
  const { activeBabyId } = useAppStore();
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [babyName, setBabyName] = useState<string>('');
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
    const baby = await babyService.getBaby(activeBabyId);
    if (baby) setBabyName(baby.name);
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
      console.error('Failed to load day data:', error);
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
          <h1 className="text-headline">History</h1>
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
                onEdit={(eventId) => console.log('Edit:', eventId)}
                onDelete={handleDelete}
              />
            </CardContent>
          </Card>
        )}
      </div>
      <MobileNav />
    </div>
  );
}
