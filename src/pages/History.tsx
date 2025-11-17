import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { EventTimeline } from '@/components/EventTimeline';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { supabase } from '@/integrations/supabase/client';
import { Baby, BabyEvent } from '@/lib/types';
import { format, subDays } from 'date-fns';
import { Moon, Milk, Baby as BabyIcon } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { SummaryChips } from '@/components/SummaryChips';
import { toast } from 'sonner';

export default function History() {
  const navigate = useNavigate();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [baby, setBaby] = useState<Baby | null>(null);
  const [dates, setDates] = useState<Date[]>([]);
  const [summary, setSummary] = useState<any>(null);

  useEffect(() => {
    loadBaby();
    generateDates();
  }, []);

  useEffect(() => {
    if (baby) {
      loadEvents();
    }
  }, [selectedDate, baby]);

  // Subscribe to dataService changes for real-time updates
  useEffect(() => {
    if (!baby) return;
    
    const unsubscribe = dataService.subscribe((action, data) => {
      if (action === 'add' || action === 'update' || action === 'delete') {
        loadEvents();
      }
    });
    return unsubscribe;
  }, [baby]);

  // Load summary when baby or events change
  useEffect(() => {
    if (baby) {
      const dayISO = format(selectedDate, 'yyyy-MM-dd');
      dataService.getDaySummary(baby.id, dayISO).then(setSummary);
    }
  }, [baby, selectedDate, events]);

  const generateDates = () => {
    const dateArray = [];
    for (let i = 13; i >= 0; i--) {
      dateArray.push(subDays(new Date(), i));
    }
    setDates(dateArray);
  };

  const loadBaby = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: familyMembers } = await supabase
      .from('family_members')
      .select('family_id')
      .eq('user_id', user.id);

    if (!familyMembers || familyMembers.length === 0) return;

    const { data: babies } = await supabase
      .from('babies')
      .select('*')
      .eq('family_id', familyMembers[0].family_id);

    if (!babies || babies.length === 0) return;

    const selectedBabyId = localStorage.getItem('selected_baby_id') || babies[0].id;
    const selectedBaby = babies.find((b) => b.id === selectedBabyId) || babies[0];
    setBaby(selectedBaby);
  };

  const loadEvents = useCallback(async () => {
    if (!baby) return;

    try {
      const dayISO = format(selectedDate, 'yyyy-MM-dd');
      const events = await dataService.listEventsByDay(baby.id, dayISO);
      
      // Map EventRecord to BabyEvent format for UI compatibility
      const mappedEvents: BabyEvent[] = events.map(e => ({
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
    } catch (error) {
      console.error('Error loading events:', error);
    }
  }, [baby, selectedDate]);

  const handleEdit = (event: BabyEvent) => {
    // Navigate to home with edit modal
    navigate('/home', { state: { editEvent: event } });
  };

  const handleDelete = async (eventId: string) => {
    try {
      await dataService.deleteEvent(eventId);
      toast.success('Event deleted');
    } catch (error) {
      toast.error('Failed to delete event');
    }
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <h1 className="text-2xl font-bold">History</h1>

        <div className="flex gap-2 overflow-x-auto pb-2">
          {dates.map((date) => (
            <Button
              key={date.toISOString()}
              variant={
                format(date, 'yyyy-MM-dd') === format(selectedDate, 'yyyy-MM-dd')
                  ? 'default'
                  : 'outline'
              }
              onClick={() => setSelectedDate(date)}
              className="flex-shrink-0"
            >
              <div className="text-center">
                <div className="text-xs">{format(date, 'EEE')}</div>
                <div className="font-bold">{format(date, 'd')}</div>
              </div>
            </Button>
          ))}
        </div>

        <div className="grid grid-cols-3 gap-3">
          <Card>
            <CardContent className="pt-6 text-center">
              <Moon className="h-6 w-6 mx-auto mb-2 text-purple-500" />
              <p className="text-2xl font-bold">
                {Math.floor(summary.sleepMinutes / 60)}h {Math.round(summary.sleepMinutes % 60)}m
              </p>
              <p className="text-xs text-muted-foreground">{summary.sleepCount} naps</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6 text-center">
              <Milk className="h-6 w-6 mx-auto mb-2 text-blue-500" />
              <p className="text-2xl font-bold">{summary.feedCount}</p>
              <p className="text-xs text-muted-foreground">feeds</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6 text-center">
              <BabyIcon className="h-6 w-6 mx-auto mb-2 text-green-500" />
              <p className="text-2xl font-bold">{summary.diaperCount}</p>
              <p className="text-xs text-muted-foreground">diapers</p>
            </CardContent>
          </Card>
        </div>

        <EventTimeline events={events} onEdit={() => {}} onDelete={() => {}} />
      </div>

      <MobileNav />
    </div>
  );
}
