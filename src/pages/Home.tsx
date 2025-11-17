import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { format, differenceInMonths } from 'date-fns';
import { EventType, NapPrediction, Baby, EventRecord } from '@/types/events';
import { BabyEvent } from '@/lib/types';
import { BabySwitcherModal } from '@/components/BabySwitcherModal';
import { QuickActions } from '@/components/QuickActions';
import { EventTimeline } from '@/components/EventTimeline';
import { EventSheet } from '@/components/sheets/EventSheet';
import { SummaryChips } from '@/components/today/SummaryChips';
import { NapPredictionCard } from '@/components/NapPredictionCard';
import { FloatingActionButton } from '@/components/FloatingActionButton';
import { MobileNav } from '@/components/MobileNav';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { dataService } from '@/services/dataService';
import { napService } from '@/services/napService';
import { useAppStore } from '@/store/appStore';
import { toast } from 'sonner';

export default function Home() {
  const navigate = useNavigate();
  const { activeBabyId, setActiveBabyId } = useAppStore();
  const [babies, setBabies] = useState<Baby[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
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
    loadBabies();
  }, []);

  useEffect(() => {
    if (activeBabyId) {
      loadBabyData();
    }
  }, [activeBabyId]);

  useEffect(() => {
    const unsubscribe = dataService.subscribe((action) => {
      if (action === 'add' || action === 'update' || action === 'delete') {
        loadTodayEvents();
        loadSummary();
        loadNapPrediction();
      }
    });
    return unsubscribe;
  }, [activeBabyId]);

  const loadBabies = async () => {
    const babyList = await dataService.listBabies();
    setBabies(babyList);
    
    if (babyList.length === 0) {
      navigate('/onboarding-simple');
      return;
    }
    
    if (babyList.length > 0) {
      const activeId = activeBabyId || babyList[0].id;
      setActiveBabyId(activeId);
    }
    
    setLoading(false);
  };

  const loadBabyData = async () => {
    if (!activeBabyId) return;
    
    const baby = await dataService.getBaby(activeBabyId);
    setSelectedBaby(baby);
    
    await Promise.all([
      loadTodayEvents(),
      loadSummary(),
      loadNapPrediction(),
    ]);
  };

  const loadTodayEvents = async () => {
    if (!activeBabyId) return;
    const today = format(new Date(), 'yyyy-MM-dd');
    const todayEvents = await dataService.listEventsByDay(activeBabyId, today);
    
    // Map EventRecord to BabyEvent format for UI compatibility
    const mappedEvents: BabyEvent[] = todayEvents.map(e => ({
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
  };

  const loadSummary = async () => {
    if (!activeBabyId) return;
    const today = format(new Date(), 'yyyy-MM-dd');
    const todaySummary = await dataService.getDaySummary(activeBabyId, today);
    setSummary(todaySummary);
  };

  const loadNapPrediction = async () => {
    if (!activeBabyId) return;
    try {
      const prediction = await napService.calculateNapWindow(activeBabyId);
      setNapPrediction(prediction);
    } catch (error) {
      console.error('Failed to calculate nap prediction:', error);
    }
  };

  const handleQuickAction = (type: EventType) => {
    setModalState({ open: true, type });
  };

  const handleBabySwitch = (babyId: string) => {
    setActiveBabyId(babyId);
    localStorage.setItem('selected_baby_id', babyId);
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

  if (loading) {
    return <div className="min-h-screen bg-surface flex items-center justify-center">Loading...</div>;
  }

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        {selectedBaby && (
          <div className="flex items-center justify-between">
            <Button
              variant="ghost"
              className="flex items-center gap-2"
              onClick={() => setIsSwitcherOpen(true)}
            >
              <Avatar className="h-10 w-10">
                <AvatarFallback>{getInitials(selectedBaby.name)}</AvatarFallback>
              </Avatar>
              <div className="text-left">
                <div className="font-semibold">{selectedBaby.name}</div>
                <div className="text-xs text-muted-foreground">
                  {differenceInMonths(new Date(), new Date(selectedBaby.dobISO))} months
                </div>
              </div>
            </Button>
          </div>
        )}

        {napPrediction && selectedBaby && (
          <NapPredictionCard
            prediction={napPrediction}
            babyId={selectedBaby.id}
            onFeedbackSubmitted={loadNapPrediction}
          />
        )}

        {summary && (
          <SummaryChips summary={summary} />
        )}

        <QuickActions onActionSelect={handleQuickAction} />

        <div>
          <h2 className="text-xl font-semibold mb-3">Today's Timeline</h2>
          {events.length > 0 ? (
            <EventTimeline
              events={events}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ) : (
            <p className="text-muted-foreground text-center py-8">No events logged today</p>
          )}
        </div>
      </div>

      <FloatingActionButton />
      <MobileNav />

      {selectedBaby && (
        <EventSheet
          isOpen={modalState.open}
          onClose={() => setModalState({ open: false, type: 'feed' })}
          eventType={modalState.type}
          babyId={activeBabyId!}
          familyId="local"
          editingEventId={modalState.editingId}
        />
      )}

      <BabySwitcherModal
        babies={babies}
        activeBabyId={activeBabyId}
        isOpen={isSwitcherOpen}
        onClose={() => setIsSwitcherOpen(false)}
        onSelect={handleBabySwitch}
        onAddNew={() => navigate('/onboarding-simple')}
      />
    </div>
  );
}
