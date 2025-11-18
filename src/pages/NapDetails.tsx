import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';
import { Baby, BabyEvent } from '@/lib/types';
import { predictNextNap } from '@/lib/napPredictor';
import { format, formatDistanceToNow, isBefore, isAfter } from 'date-fns';
import { ArrowLeft, Moon } from 'lucide-react';
import { toast } from 'sonner';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';

export default function NapDetails() {
  const navigate = useNavigate();
  const [baby, setBaby] = useState<Baby | null>(null);
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        navigate('/auth');
        return;
      }

      // Get user's families
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id);

      if (!familyMembers || familyMembers.length === 0) return;

      // Get babies
      const { data: babies } = await supabase
        .from('babies')
        .select('*')
        .eq('family_id', familyMembers[0].family_id);

      if (!babies || babies.length === 0) return;

      const selectedBabyId = localStorage.getItem('selected_baby_id') || babies[0].id;
      const selectedBaby = babies.find((b) => b.id === selectedBabyId) || babies[0];
      setBaby(selectedBaby);

      // Get last 7 days of sleep events
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { data: sleepEvents } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .eq('type', 'sleep')
        .gte('start_time', sevenDaysAgo.toISOString())
        .order('start_time', { ascending: false });

      setEvents(sleepEvents || []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const submitFeedback = async (rating: 'too_early' | 'just_right' | 'too_late') => {
    if (!baby) return;

    try {
      const prediction = predictNextNap(baby, events);

      await supabase.from('nap_feedback').insert({
        baby_id: baby.id,
        predicted_start: prediction.napWindowStart.toISOString(),
        predicted_end: prediction.napWindowEnd.toISOString(),
        rating,
      });

      toast.success('Thank you for your feedback!');
    } catch (error) {
      console.error('Error submitting feedback:', error);
      toast.error('Failed to submit feedback');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface pb-20 flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  if (!baby) {
    return (
      <div className="min-h-screen bg-surface pb-20 flex items-center justify-center">
        <p>No baby found</p>
      </div>
    );
  }

  const prediction = predictNextNap(baby, events);
  const now = new Date();
  const isWindowOpen =
    isAfter(now, prediction.napWindowStart) && isBefore(now, prediction.napWindowEnd);
  const isPast = isAfter(now, prediction.napWindowEnd);

  const todaysSleeps = events.filter((e) => {
    const eventDate = new Date(e.start_time);
    return eventDate.toDateString() === now.toDateString();
  });

  const totalSleepMinutes = todaysSleeps.reduce((total, event) => {
    if (event.end_time) {
      const duration =
        (new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 60000;
      return total + duration;
    }
    return total;
  }, 0);

  const confidenceColors = {
    high: 'bg-green-500',
    medium: 'bg-yellow-500',
    low: 'bg-gray-500',
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center gap-3 mb-4">
          <Button variant="ghost" size="sm" onClick={() => navigate('/home')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <h1 className="text-2xl font-bold">Nap Prediction</h1>
        </div>

        <MedicalDisclaimer variant="predictions" />

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>Current Prediction</span>
              <Badge className={confidenceColors[prediction.confidence]}>
                {prediction.confidence} confidence
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center py-6">
              {isWindowOpen ? (
                <>
                  <p className="text-lg font-semibold text-green-600 mb-2">
                    Nap Window Open Now! 💤
                  </p>
                  <p className="text-3xl font-bold">
                    {format(prediction.napWindowStart, 'h:mm a')} -{' '}
                    {format(prediction.napWindowEnd, 'h:mm a')}
                  </p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Closes in {formatDistanceToNow(prediction.napWindowEnd)}
                  </p>
                </>
              ) : isPast ? (
                <>
                  <p className="text-lg font-semibold text-orange-600 mb-2">
                    Window has passed
                  </p>
                  <p className="text-2xl font-bold">
                    {format(prediction.napWindowStart, 'h:mm a')} -{' '}
                    {format(prediction.napWindowEnd, 'h:mm a')}
                  </p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Ended {formatDistanceToNow(prediction.napWindowEnd, { addSuffix: true })}
                  </p>
                </>
              ) : (
                <>
                  <p className="text-lg font-semibold mb-2">Next Nap Window</p>
                  <p className="text-3xl font-bold">
                    {format(prediction.napWindowStart, 'h:mm a')} -{' '}
                    {format(prediction.napWindowEnd, 'h:mm a')}
                  </p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Starts in {formatDistanceToNow(prediction.napWindowStart)}
                  </p>
                </>
              )}
            </div>

            <div className="border-t pt-4">
              <p className="text-sm text-muted-foreground">{prediction.explanation}</p>
            </div>

            {prediction.lastWakeTime && (
              <div className="text-sm">
                <span className="text-muted-foreground">Last wake time: </span>
                <span className="font-medium">
                  {format(prediction.lastWakeTime, 'h:mm a')} (
                  {formatDistanceToNow(prediction.lastWakeTime, { addSuffix: true })})
                </span>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Today's Sleep</CardTitle>
          </CardHeader>
          <CardContent>
            {todaysSleeps.length === 0 ? (
              <p className="text-muted-foreground text-center py-4">No sleeps logged today</p>
            ) : (
              <div className="space-y-3">
                {todaysSleeps.map((sleep) => {
                  const duration = sleep.end_time
                    ? Math.round(
                        (new Date(sleep.end_time).getTime() -
                          new Date(sleep.start_time).getTime()) /
                          60000
                      )
                    : null;

                  return (
                    <div key={sleep.id} className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <Moon className="h-4 w-4 text-purple-500" />
                        <div>
                          <p className="text-sm font-medium">
                            {format(new Date(sleep.start_time), 'h:mm a')}
                            {sleep.end_time && ` - ${format(new Date(sleep.end_time), 'h:mm a')}`}
                          </p>
                          {duration && (
                            <p className="text-xs text-muted-foreground">{duration} min</p>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
                <div className="border-t pt-3 mt-3">
                  <p className="text-sm font-medium">
                    Total: {Math.floor(totalSleepMinutes / 60)}h {Math.round(totalSleepMinutes % 60)}
                    m ({todaysSleeps.length} {todaysSleeps.length === 1 ? 'nap' : 'naps'})
                  </p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {isPast && (
          <Card>
            <CardHeader>
              <CardTitle>How was the timing?</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground mb-4">
                Your feedback helps us improve predictions for {baby.name}.
              </p>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => submitFeedback('too_early')}
                >
                  Too Early
                </Button>
                <Button
                  variant="default"
                  className="flex-1"
                  onClick={() => submitFeedback('just_right')}
                >
                  Just Right
                </Button>
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => submitFeedback('too_late')}
                >
                  Too Late
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      <MobileNav />
    </div>
  );
}
