import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { EventTimeline } from '@/components/EventTimeline';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { supabase } from '@/integrations/supabase/client';
import { Baby, BabyEvent } from '@/lib/types';
import { format, subDays, startOfDay, endOfDay } from 'date-fns';
import { Moon, Milk, Baby as BabyIcon } from 'lucide-react';

export default function History() {
  const navigate = useNavigate();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [baby, setBaby] = useState<Baby | null>(null);
  const [dates, setDates] = useState<Date[]>([]);

  useEffect(() => {
    loadBaby();
    generateDates();
  }, []);

  useEffect(() => {
    loadEvents();
  }, [selectedDate, baby]);

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

  const loadEvents = async () => {
    if (!baby) return;

    const start = startOfDay(selectedDate);
    const end = endOfDay(selectedDate);

    const { data } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', baby.id)
      .gte('start_time', start.toISOString())
      .lte('start_time', end.toISOString())
      .order('start_time', { ascending: false });

    setEvents(data || []);
  };

  const calculateSummary = (events: BabyEvent[]) => {
    const sleeps = events.filter((e) => e.type === 'sleep' && e.end_time);
    const feeds = events.filter((e) => e.type === 'feed');
    const diapers = events.filter((e) => e.type === 'diaper');

    const totalSleep = sleeps.reduce((total, sleep) => {
      if (sleep.end_time) {
        const duration =
          (new Date(sleep.end_time).getTime() - new Date(sleep.start_time).getTime()) / 60000;
        return total + duration;
      }
      return total;
    }, 0);

    return {
      sleepMinutes: totalSleep,
      sleepCount: sleeps.length,
      feedCount: feeds.length,
      diaperCount: diapers.length,
    };
  };

  const summary = calculateSummary(events);

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
