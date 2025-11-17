import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { format, differenceInMonths } from 'date-fns';
import { Baby as BabyType, BabyEvent } from '@/lib/types';
import { EventType } from '@/types/events';
import { NapPrediction } from '@/types/events';
import { BabySwitcher } from '@/components/BabySwitcher';
import { QuickActions } from '@/components/QuickActions';
import { EventTimeline } from '@/components/EventTimeline';
import { EventSheet } from '@/components/sheets/EventSheet';
import { SummaryChips } from '@/components/SummaryChips';
import { NapPredictionCard } from '@/components/NapPredictionCard';
import { FloatingActionButton } from '@/components/FloatingActionButton';
import { MobileNav } from '@/components/MobileNav';
import { OfflineIndicator } from '@/components/OfflineIndicator';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { supabase } from '@/integrations/supabase/client';
import { dataService } from '@/services/dataService';
import { napService } from '@/services/napService';
import { useRealtimeEvents } from '@/hooks/useRealtimeEvents';
import { toast } from 'sonner';

export default function Home() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [babies, setBabies] = useState<BabyType[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<BabyType | null>(null);
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [events, setEvents] = useState<BabyEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState<{ open: boolean; type: EventType; editingId?: string }>({
    open: false,
    type: 'feed',
  });
  const [napPrediction, setNapPrediction] = useState<NapPrediction | null>(null);
  const [summary, setSummary] = useState<any>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

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
        setSelectedBabyId(selectedBabyData.id);
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

    try {
      const today = new Date().toISOString().split('T')[0];
      const events = await dataService.listEventsByDay(selectedBaby.id, today);
      
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
  }, [selectedBaby]);

  const handleBabySelect = (babyId: string) => {
    const baby = babies.find((b) => b.id === babyId);
    if (baby) {
      setSelectedBaby(baby);
      setSelectedBabyId(babyId);
      localStorage.setItem('selected_baby_id', babyId);
    }
  };

  const openModal = (type: EventType) => {
    setModalState({ open: true, type });
  };

  const handleEdit = (event: BabyEvent) => {
    setModalState({ open: true, type: event.type as EventType, editingId: event.id });
  };

  const handleDelete = async (eventId: string) => {
    try {
      await dataService.deleteEvent(eventId);
      toast.success('Event deleted');
    } catch (error) {
      toast.error('Failed to delete event');
    }
  };

  useRealtimeEvents(selectedBaby?.family_id, loadTodayEvents);

  useEffect(() => {
    if (selectedBaby) {
      loadTodayEvents();
    }
  }, [selectedBaby, loadTodayEvents]);

  // Subscribe to dataService changes for real-time updates
  useEffect(() => {
    if (!selectedBaby) return;
    
    const unsubscribe = dataService.subscribe((action, data) => {
      if (action === 'add' || action === 'update' || action === 'delete') {
        loadTodayEvents();
      }
    });
    return unsubscribe;
  }, [selectedBaby, loadTodayEvents]);

  // Load summary when baby or events change
  useEffect(() => {
    if (selectedBaby) {
      dataService.getTodaySummary(selectedBaby.id).then(setSummary);
    }
  }, [selectedBaby, events]);

  // Load nap prediction
  useEffect(() => {
    if (!selectedBaby) return;

    const loadNapPrediction = async () => {
      try {
        // Try to get cached prediction first
        const cached = await dataService.getNapPrediction(selectedBaby.id);
        if (cached) {
          setNapPrediction(cached);
          return;
        }

        // Calculate fresh prediction if no cache
        const ageMonths = differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth));
        const prediction = await napService.recalculate(selectedBaby.id, ageMonths);
        if (prediction) {
          setNapPrediction(prediction);
          await dataService.storeNapPrediction(selectedBaby.id, prediction);
        }
      } catch (error) {
        console.error('Failed to load nap prediction:', error);
      }
    };

    loadNapPrediction();
  }, [selectedBaby, events]);

  const handleFeedbackSubmitted = async () => {
    // Refresh prediction after feedback
    if (selectedBaby) {
      const ageMonths = differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth));
      const prediction = await napService.recalculate(selectedBaby.id, ageMonths);
      if (prediction) {
        setNapPrediction(prediction);
        await dataService.storeNapPrediction(selectedBaby.id, prediction);
      }
    }
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface pb-20 flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <OfflineIndicator />
      
      <div className="max-w-2xl mx-auto px-4 py-6 pb-24">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">
              {selectedBaby?.name || 'Welcome'}
            </h1>
            <p className="text-sm text-muted-foreground">
              {format(new Date(), 'EEEE, MMMM d')}
            </p>
          </div>
          {babies.length > 1 && selectedBaby && (
            <button
              onClick={() => setIsSwitcherOpen(true)}
              className="flex items-center gap-2 hover:opacity-80 transition-opacity"
            >
              <Avatar className="h-10 w-10">
                <AvatarFallback className="bg-primary text-primary-foreground">
                  {getInitials(selectedBaby.name)}
                </AvatarFallback>
              </Avatar>
            </button>
          )}
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

        {summary && <SummaryChips summary={summary} />}

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
