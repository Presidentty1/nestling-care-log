import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { format, isBefore, isAfter } from 'date-fns';
import { Baby, Milk, Moon, Baby as BabyIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { MobileNav } from '@/components/MobileNav';
import { EventSheet } from '@/components/sheets/EventSheet';
import { NapPredictionCard } from '@/components/NapPredictionCard';
import { dataService } from '@/services/dataService';
import { napService } from '@/services/napService';
import { analyticsService } from '@/services/analyticsService';
import { useEventSync } from '@/hooks/useEventSync';
import { differenceInMonths } from 'date-fns';
import { EventDialog } from '@/components/EventDialog';
import { EventTimeline } from '@/components/EventTimeline';
import { BabySelector } from '@/components/BabySelector';
import { OfflineIndicator } from '@/components/OfflineIndicator';
import { FloatingActionButton } from '@/components/FloatingActionButton';
import { QuickActions } from '@/components/QuickActions';
import { supabase } from '@/integrations/supabase/client';
import { useEventLogger } from '@/hooks/useEventLogger';
import { useRealtimeEvents } from '@/hooks/useRealtimeEvents';
import { predictNextNap } from '@/lib/napPredictor';
import { Baby as BabyType, BabyEvent, EventType as LibEventType } from '@/lib/types';
import { EventType } from '@/types/events';
import { toast } from 'sonner';

export default function Home() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [babies, setBabies] = useState<BabyType[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<BabyType | null>(null);
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalType, setModalType] = useState<LibEventType>('feed');
  const [editingEvent, setEditingEvent] = useState<BabyEvent | null>(null);
  const [napPrediction, setNapPrediction] = useState<any>(null);
  const eventSync = selectedBaby ? useEventSync(selectedBaby.id) : null;

  const { deleteEvent } = useEventLogger();

  useEffect(() => {
    const skipAuth = localStorage.getItem('dev_skip_auth') === 'true';
    if (!authLoading && !user && !skipAuth) {
      navigate('/auth');
    }
    if (skipAuth && !user) {
      setLoading(false);
    }
  }, [user, authLoading, navigate]);

  useEffect(() => {
    if (user) {
      loadBabies();
    }
  }, [user]);

  const loadBabies = async () => {
    try {
      const skipAuth = localStorage.getItem('dev_skip_auth') === 'true';
      if (skipAuth) {
        setLoading(false);
        return;
      }

      const { data: familyMembers, error: fmError } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user!.id);

      if (fmError) throw fmError;

      if (!familyMembers || familyMembers.length === 0) {
        navigate('/onboarding');
        return;
      }

      const familyIds = familyMembers.map((fm) => fm.family_id);
      const { data: babiesData, error: babiesError } = await supabase
        .from('babies')
        .select('*')
        .in('family_id', familyIds);

      if (babiesError) throw babiesError;

      if (babiesData && babiesData.length > 0) {
        setBabies(babiesData as BabyType[]);
        
        const savedBabyId = localStorage.getItem('selected_baby_id');
        const selectedBabyData = savedBabyId 
          ? babiesData.find(b => b.id === savedBabyId) || babiesData[0]
          : babiesData[0];
        
        setSelectedBaby(selectedBabyData as BabyType);
      } else {
        navigate('/onboarding');
      }
    } catch (error) {
      console.error('Error loading babies:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadTodayEvents = useCallback(async () => {
    if (!selectedBaby) return;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', selectedBaby.id)
      .gte('start_time', today.toISOString())
      .order('start_time', { ascending: false });

    if (error) {
      console.error('Error loading events:', error);
      return;
    }

    setEvents(data || []);
  }, [selectedBaby]);

  const handleBabySelect = (babyId: string) => {
    const baby = babies.find((b) => b.id === babyId);
    if (baby) {
      setSelectedBaby(baby);
      localStorage.setItem('selected_baby_id', babyId);
    }
  };

  const openModal = (type: EventType | LibEventType) => {
    setModalType(type);
    setEditingEvent(null);
    setIsModalOpen(true);
    
    if (!selectedBaby) {
      toast.info('No baby selected - logging locally only');
    }
  };

  const handleEdit = (event: BabyEvent) => {
    setEditingEvent(event);
    setModalType(event.type);
    setIsModalOpen(true);
  };

  const handleDelete = async (eventId: string) => {
    await deleteEvent(eventId);
    loadTodayEvents();
  };

  useRealtimeEvents(selectedBaby?.family_id, loadTodayEvents);

  useEffect(() => {
    loadTodayEvents();
  }, [loadTodayEvents]);

  if (loading) {
    return (
      <div className="min-h-screen bg-surface pb-20 flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
              <Baby className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-xl font-bold">{selectedBaby?.name}</h1>
              <p className="text-sm text-muted-foreground">
                {selectedBaby && format(new Date(selectedBaby.date_of_birth), 'MMM d, yyyy')}
              </p>
            </div>
          </div>
          <BabySelector
            babies={babies}
            selectedBabyId={selectedBaby?.id || null}
            onSelect={handleBabySelect}
          />
        </div>

        <OfflineIndicator />

        {selectedBaby && events.length > 0 && (() => {
          const prediction = predictNextNap(selectedBaby, events);
          const now = new Date();
          const isOpen = isAfter(now, prediction.napWindowStart) && isBefore(now, prediction.napWindowEnd);
          
          return (
            <Card className="cursor-pointer hover:bg-accent/5" onClick={() => navigate('/nap-details')}>
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  <span>💤 Next Nap Window</span>
                  <Badge variant={prediction.confidence === 'high' ? 'default' : 'secondary'}>
                    {prediction.confidence}
                  </Badge>
                </CardTitle>
              </CardHeader>
              <CardContent>
                {isOpen ? (
                  <div className="text-center">
                    <p className="text-lg font-semibold text-green-600 mb-2">Window Open Now!</p>
                    <p className="text-2xl font-bold">
                      {format(prediction.napWindowStart, 'h:mm a')} - {format(prediction.napWindowEnd, 'h:mm a')}
                    </p>
                  </div>
                ) : (
                  <div className="text-center">
                    <p className="text-2xl font-bold">
                      {format(prediction.napWindowStart, 'h:mm a')} - {format(prediction.napWindowEnd, 'h:mm a')}
                    </p>
                    <p className="text-sm text-muted-foreground mt-2">Tap for details →</p>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })()}

        <div className="grid grid-cols-3 gap-3">
          <Button size="lg" className="h-24 flex-col gap-2" onClick={() => openModal('feed')}>
            <Milk className="h-6 w-6" />
            <span>Feed</span>
          </Button>
          <Button size="lg" className="h-24 flex-col gap-2" onClick={() => openModal('sleep')}>
            <Moon className="h-6 w-6" />
            <span>Sleep</span>
          </Button>
          <Button size="lg" className="h-24 flex-col gap-2" onClick={() => openModal('diaper')}>
            <BabyIcon className="h-6 w-6" />
            <span>Diaper</span>
          </Button>
        </div>

        <QuickActions onActionSelect={(type) => openModal(type)} />

        <EventTimeline events={events} onEdit={handleEdit} onDelete={handleDelete} />
      </div>

      {isModalOpen && modalType && ['feed', 'sleep', 'diaper', 'tummy_time'].includes(modalType) && (
        <EventSheet
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setEditingEvent(null);
            loadTodayEvents();
          }}
          eventType={modalType as EventType}
          babyId={selectedBaby?.id ?? 'local-dev-baby'}
          familyId={selectedBaby?.family_id ?? 'local-dev-family'}
          editingEventId={editingEvent?.id}
        />
      )}

      <FloatingActionButton
        onVoiceCommand={(command) => {
          if (command.type) {
            openModal(command.type);
          }
        }}
      />

      <MobileNav />
    </div>
  );
}
