import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';
import { Baby as BabyType, BabyEvent } from '@/lib/types';
import { Baby, Milk, Moon, Droplet, Clock } from 'lucide-react';
import { toast } from 'sonner';
import { format, formatDistanceToNow } from 'date-fns';

export default function Home() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [babies, setBabies] = useState<BabyType[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<BabyType | null>(null);
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && !user) {
      navigate('/auth');
    }
  }, [user, authLoading, navigate]);

  useEffect(() => {
    if (user) {
      loadBabies();
    }
  }, [user]);

  useEffect(() => {
    if (selectedBaby) {
      loadTodayEvents();
    }
  }, [selectedBaby]);

  const loadBabies = async () => {
    try {
      // Get families the user belongs to
      const { data: familyMembers, error: fmError } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user!.id);

      if (fmError) throw fmError;

      if (!familyMembers || familyMembers.length === 0) {
        navigate('/onboarding');
        return;
      }

      // Get babies from those families
      const familyIds = familyMembers.map(fm => fm.family_id);
      const { data: babiesData, error: babiesError } = await supabase
        .from('babies')
        .select('*')
        .in('family_id', familyIds);

      if (babiesError) throw babiesError;

      if (babiesData && babiesData.length > 0) {
        setBabies(babiesData as BabyType[]);
        setSelectedBaby(babiesData[0] as BabyType);
      } else {
        navigate('/onboarding');
      }
    } catch (error) {
      console.error('Error loading babies:', error);
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const loadTodayEvents = async () => {
    if (!selectedBaby) return;

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const { data, error } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .gte('start_time', today.toISOString())
        .order('start_time', { ascending: false })
        .limit(20);

      if (error) throw error;
      setEvents((data || []) as BabyEvent[]);
    } catch (error) {
      console.error('Error loading events:', error);
    }
  };

  const getEventIcon = (type: string) => {
    switch (type) {
      case 'feed':
        return <Milk className="h-4 w-4" />;
      case 'sleep':
        return <Moon className="h-4 w-4" />;
      case 'diaper':
        return <Droplet className="h-4 w-4" />;
      default:
        return <Clock className="h-4 w-4" />;
    }
  };

  const getEventColor = (type: string) => {
    switch (type) {
      case 'feed':
        return 'text-secondary';
      case 'sleep':
        return 'text-primary';
      case 'diaper':
        return 'text-accent';
      default:
        return 'text-muted-foreground';
    }
  };

  if (loading || authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-muted-foreground">Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
              <Baby className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-xl font-bold">{selectedBaby?.name}</h1>
              <p className="text-sm text-muted-foreground">
                {selectedBaby && format(new Date(selectedBaby.date_of_birth), 'MMM d, yyyy')}
              </p>
            </div>
          </div>
        </div>

        {/* Nap Predictor Card */}
        <Card>
          <CardHeader>
            <div className="flex items-start justify-between">
              <div className="space-y-1">
                <CardTitle className="text-lg">Next Nap Window</CardTitle>
                <CardDescription>Based on age and last wake time</CardDescription>
              </div>
              <Badge variant="secondary">Beta</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm">
              Complete a sleep event to see predictions
            </p>
          </CardContent>
        </Card>

        {/* Quick Log Buttons */}
        <div className="grid grid-cols-3 gap-3">
          <Button 
            variant="outline" 
            className="h-24 flex-col gap-2"
            onClick={() => toast.info('Feed logging coming soon')}
          >
            <Milk className="h-6 w-6 text-secondary" />
            <span className="text-sm font-medium">Feed</span>
          </Button>
          <Button 
            variant="outline" 
            className="h-24 flex-col gap-2"
            onClick={() => toast.info('Sleep logging coming soon')}
          >
            <Moon className="h-6 w-6 text-primary" />
            <span className="text-sm font-medium">Sleep</span>
          </Button>
          <Button 
            variant="outline" 
            className="h-24 flex-col gap-2"
            onClick={() => toast.info('Diaper logging coming soon')}
          >
            <Droplet className="h-6 w-6 text-accent" />
            <span className="text-sm font-medium">Diaper</span>
          </Button>
        </div>

        {/* Today's Timeline */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Today</CardTitle>
          </CardHeader>
          <CardContent>
            {events.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">
                No events logged today. Tap a button above to get started!
              </p>
            ) : (
              <div className="space-y-3">
                {events.map((event) => (
                  <div 
                    key={event.id}
                    className="flex items-center gap-3 p-3 rounded-lg bg-surface hover:bg-muted/50 transition-colors cursor-pointer"
                  >
                    <div className={`${getEventColor(event.type)}`}>
                      {getEventIcon(event.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium capitalize">
                        {event.type}
                        {event.subtype && ` · ${event.subtype}`}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {formatDistanceToNow(new Date(event.start_time), { addSuffix: true })}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
