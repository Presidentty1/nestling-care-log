import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { format, differenceInMonths, subDays } from 'date-fns';
import { EventType } from '@/types/events';
import { BabySwitcherModal } from '@/components/BabySwitcherModal';
import { QuickActions } from '@/components/QuickActions';
import { EventSheet } from '@/components/sheets/EventSheet';
import { SummaryChips } from '@/components/today/SummaryChips';
import { FloatingActionButtonRadial } from '@/components/FloatingActionButtonRadial';
import { MobileNav } from '@/components/MobileNav';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { eventsService, EventRecord } from '@/services/eventsService';
import { babyService, Baby } from '@/services/babyService';
import { napPredictorService } from '@/services/napPredictorService';
import { reminderService } from '@/services/reminderService';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { toast } from 'sonner';
import { TimelineList } from '@/components/today/TimelineList';
import { NapWindowCard } from '@/components/today/NapWindowCard';
import { NapPill } from '@/components/today/NapPill';

export default function Home() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { activeBabyId, setActiveBabyId } = useAppStore();
  const [babies, setBabies] = useState<Baby[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState<{ open: boolean; type: EventType; editingId?: string }>({
    open: false,
    type: 'feed',
  });
  const [napWindow, setNapWindow] = useState<{ start: Date; end: Date; reason: string } | null>(null);
  const [summary, setSummary] = useState<any>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  useEffect(() => {
    if (user) {
      loadBabies();
    }
  }, [user]);

  useEffect(() => {
    if (activeBabyId) {
      loadBabyData();
    }
  }, [activeBabyId]);

  useEffect(() => {
    const unsubscribe = eventsService.subscribe((action) => {
      if (action === 'add' || action === 'update' || action === 'delete') {
        loadTodayEvents();
      }
    });
    return unsubscribe;
  }, [activeBabyId]);

  const loadBabies = async () => {
    try {
      const babyList = await babyService.getUserBabies();
      setBabies(babyList);
      
      if (babyList.length === 0) {
        // Auto-provision a demo baby via backend, then continue to Home
        try {
          const { data: { session } } = await (await import('@/integrations/supabase/client')).supabase.auth.getSession();
          if (session) {
            const demoBirthdate = format(subDays(new Date(), 60), 'yyyy-MM-dd');
            const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            const { supabase } = await import('@/integrations/supabase/client');
            const response = await supabase.functions.invoke('bootstrap-user', {
              body: { babyName: 'Demo Baby', dateOfBirth: demoBirthdate, timezone },
              headers: { Authorization: `Bearer ${session.access_token}` }
            });
            if (!response.error) {
              const { babyId } = response.data as any;
              setActiveBabyId(babyId);
              localStorage.setItem('activeBabyId', babyId);
              setLoading(false);
              return; // Stay on Home, data effects will load
            }
          }
        } catch (e) {
          console.error('Auto-provision error:', e);
        }
        navigate('/onboarding');
        return;
      }
      
      const storedBabyId = localStorage.getItem('activeBabyId');
      const activeId = babyList.find(b => b.id === storedBabyId)?.id || babyList[0].id;
      setActiveBabyId(activeId);
      
      setLoading(false);
    } catch (error) {
      console.error('Failed to load babies:', error);
      toast.error('Failed to load babies');
      setLoading(false);
    }
  };

  const loadBabyData = async () => {
    if (!activeBabyId) return;
    
    try {
      const baby = await babyService.getBaby(activeBabyId);
      setSelectedBaby(baby);
      
      await loadTodayEvents();
    } catch (error) {
      console.error('Failed to load baby data:', error);
      toast.error('Failed to load data');
    }
  };

  const loadTodayEvents = async () => {
    if (!activeBabyId) return;
    
    try {
      const todayEvents = await eventsService.getTodayEvents(activeBabyId);
      setEvents(todayEvents);
      
      // Calculate summary
      const sum = eventsService.calculateSummary(todayEvents);
      setSummary(sum);
      
      // Calculate nap window
      if (selectedBaby) {
        const window = napPredictorService.calculateFromEvents(todayEvents, selectedBaby.date_of_birth);
        setNapWindow(window);
        
        // Update reminder service
        const lastFeed = await eventsService.getLastEventByType(activeBabyId, 'feed');
        reminderService.updateLastFeed(lastFeed);
        if (window) {
          reminderService.updateNapWindow({ start: window.start, end: window.end });
        }
      }
    } catch (error) {
      console.error('Failed to load events:', error);
      toast.error('Failed to load events');
    }
  };

  const handleQuickAction = (type: EventType) => {
    setModalState({ open: true, type });
  };

  const handleBabySwitch = (babyId: string) => {
    setActiveBabyId(babyId);
    localStorage.setItem('activeBabyId', babyId);
  };

  const handleEdit = (event: EventRecord) => {
    setModalState({ open: true, type: event.type as EventType, editingId: event.id });
  };

  const handleDelete = async (eventId: string) => {
    try {
      await eventsService.deleteEvent(eventId);
      toast.success('Event deleted');
    } catch (error) {
      console.error('Failed to delete event:', error);
      toast.error('Failed to delete event');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="max-w-2xl mx-auto px-4 pt-4 pb-4 space-y-5">
        {selectedBaby && (
          <div className="flex items-center justify-between mb-2">
            <Button
              variant="ghost"
              className="flex items-center gap-3 -ml-2 h-auto py-2"
              onClick={() => setIsSwitcherOpen(true)}
            >
              <Avatar className="h-11 w-11">
                <AvatarFallback className="text-base font-semibold">{getInitials(selectedBaby.name)}</AvatarFallback>
              </Avatar>
              <div className="text-left">
                <div className="font-semibold text-[17px] leading-[24px]">{selectedBaby.name}</div>
                <div className="text-secondary text-muted-foreground">
                  {differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth))} months
                </div>
              </div>
            </Button>
          </div>
        )}

        {summary && (
          <SummaryChips summary={summary} />
        )}

        {napWindow && selectedBaby && (
          <div className="mb-4">
            <NapPill 
              prediction={{
                nextWindowStartISO: napWindow.start.toISOString(),
                nextWindowEndISO: napWindow.end.toISOString(),
                reason: napWindow.reason,
                confidence: 0.85,
              }}
              babyId={activeBabyId}
            />
          </div>
        )}

        <QuickActions onActionSelect={handleQuickAction} />

        <div className="space-y-3">
          <h2 className="text-[22px] leading-[28px] font-semibold">Today's Timeline</h2>
          <TimelineList
            events={events}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        </div>
      </div>

      <FloatingActionButtonRadial />
      <MobileNav />

      {selectedBaby && activeBabyId && (
        <EventSheet
          isOpen={modalState.open}
          onClose={() => setModalState({ open: false, type: 'feed' })}
          eventType={modalState.type}
          babyId={activeBabyId}
          familyId={selectedBaby.family_id}
          editingEventId={modalState.editingId}
        />
      )}

      <BabySwitcherModal
        babies={babies}
        activeBabyId={activeBabyId}
        isOpen={isSwitcherOpen}
        onClose={() => setIsSwitcherOpen(false)}
        onSelect={handleBabySwitch}
        onAddNew={() => navigate('/onboarding')}
      />
    </div>
  );
}
