import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { format, differenceInMonths, subDays } from 'date-fns';
import { EventType } from '@/types/events';
import { DailySummary } from '@/types/summary';
import { BabySwitcherModal } from '@/components/BabySwitcherModal';
import { QuickActions } from '@/components/QuickActions';
import { EventSheet } from '@/components/sheets/EventSheet';
import { SummaryChips } from '@/components/today/SummaryChips';
import { FloatingActionButtonRadial } from '@/components/FloatingActionButtonRadial';
import { MobileNav } from '@/components/MobileNav';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
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
import { triggerConfetti } from '@/lib/confetti';
import { useKeyboardShortcuts } from '@/hooks/useKeyboardShortcuts';
import { useDismissibleBanner } from '@/hooks/useDismissibleBanner';
import { useLastUsedValues } from '@/hooks/useLastUsedValues';
import { Lock, Users, X } from 'lucide-react';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { ContextualTipCard } from '@/components/ContextualTipCard';
import { getContextualTips } from '@/lib/contextualTips';
import { GuestModeBanner } from '@/components/GuestModeBanner';
import { StreakCounter } from '@/components/StreakCounter';
import { DailyAffirmation } from '@/components/DailyAffirmation';
import { TrialCountdown } from '@/components/TrialCountdown';
import { TrialStartModal } from '@/components/TrialStartModal';
import { guestModeService } from '@/services/guestModeService';
import { streakService } from '@/services/streakService';
import { achievementService } from '@/services/achievementService';
import { trialService } from '@/services/trialService';
import { dataService } from '@/services/dataService';

export default function Home() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();
  const { activeBabyId, setActiveBabyId, guestMode } = useAppStore();
  const [babies, setBabies] = useState<Baby[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState<{ open: boolean; type: EventType; editingId?: string; prefillData?: any }>({
    open: false,
    type: 'feed',
  });
  const [napWindow, setNapWindow] = useState<{ start: Date; end: Date; reason: string } | null>(null);
  const [summary, setSummary] = useState<DailySummary | null>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);
  const [hasShownConfetti, setHasShownConfetti] = useState(false);
  const [streakDays, setStreakDays] = useState(0);
  const [showGuestBanner, setShowGuestBanner] = useState(false);
  const [showAffirmation, setShowAffirmation] = useState(false);
  const [trialDaysRemaining, setTrialDaysRemaining] = useState<number | null>(null);
  
  const privacyBanner = useDismissibleBanner('privacy_stance');
  const caregiverBanner = useDismissibleBanner('caregiver_invite');
  const { getLastUsed, saveLastUsed } = useLastUsedValues();
  const [dismissedTips, setDismissedTips] = useState<string[]>([]);

  useKeyboardShortcuts({
    escape: () => setModalState({ open: false, type: 'feed' }),
    newEvent: () => setModalState({ open: true, type: 'feed' }),
  });

  useEffect(() => {
    if (guestMode) {
      loadGuestMode();
    } else if (user) {
      loadBabies();
    }
  }, [user, guestMode]);

  // Handle notification quick actions
  useEffect(() => {
    if (location.state?.openSheet) {
      setModalState({
        open: true,
        type: location.state.openSheet,
        prefillData: location.state.prefillData || {},
      });
      
      // Clear navigation state to prevent reopening
      window.history.replaceState({}, document.title);
    }
  }, [location]);

  useEffect(() => {
    if (activeBabyId) {
      loadBabyData();
      loadStreakData();
      checkTrialStatus();
    }
  }, [activeBabyId]);

  useEffect(() => {
    const unsubscribe = eventsService.subscribe((action, data) => {
      if (action === 'add') {
        // Show confetti on first event
        if (events.length === 0 && !hasShownConfetti) {
          triggerConfetti();
          setHasShownConfetti(true);
        }
        
        // Increment guest event count and update streak
        if (guestMode) {
          guestModeService.incrementGuestEventCount().then(count => {
            if (count >= 3) setShowGuestBanner(true);
          });
        }
        
        if (data && activeBabyId) {
          const event = data as EventRecord;
          // Update streak
          const today = format(new Date(), 'yyyy-MM-dd');
          streakService.markEventLogged(activeBabyId, today, event.type).then(() => {
            streakService.updateStreak(activeBabyId).then(streak => {
              setStreakDays(streak.currentStreak);
              // Check for achievements
              achievementService.checkAndUnlockAchievements(activeBabyId, {
                streakDays: streak.currentStreak,
                eventType: event.type,
                eventTime: new Date(event.start_time),
              }).then(newAchievements => {
                newAchievements.forEach(achievement => {
                  toast.success(`Achievement unlocked: ${achievement.title}!`, {
                    description: achievement.description,
                    icon: achievement.icon,
                  });
                });
              });
            });
          });
          
          // Check for daily affirmation
          streakService.shouldShowAffirmation(activeBabyId).then(should => {
            if (should) setShowAffirmation(true);
          });
        }
        
        // Save last used values for quick log
        if (data && !modalState.editingId) {
          const event = data as EventRecord;
          const values: any = {};
          if (event.type === 'feed') {
            values.subtype = event.subtype;
            values.amount = event.amount;
            values.unit = event.unit;
            values.side = event.side;
          } else if (event.type === 'diaper') {
            values.subtype = event.subtype;
          } else if (event.type === 'tummy_time') {
            values.duration_min = event.duration_min;
          }
          saveLastUsed(event.type as EventType, values);
        }
        
        loadTodayEvents();
      } else if (action === 'update' || action === 'delete') {
        loadTodayEvents();
      }
    });
    return unsubscribe;
  }, [activeBabyId, events.length, hasShownConfetti, modalState.editingId]);

  const loadGuestMode = async () => {
    const guestBaby = await guestModeService.getGuestBaby();
    if (!guestBaby) {
      await guestModeService.enableGuestMode();
      const baby = await dataService.addBaby({
        name: 'Demo Baby',
        dobISO: format(subDays(new Date(), 60), 'yyyy-MM-dd'),
        timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        units: 'imperial',
      });
      await guestModeService.setGuestBaby(baby);
      setActiveBabyId(baby.id);
    } else {
      setActiveBabyId(guestBaby.id);
    }
    
    const count = await guestModeService.getGuestEventCount();
    setShowGuestBanner(count >= 3);
    setLoading(false);
  };

  const loadStreakData = async () => {
    if (!activeBabyId) return;
    const streak = await streakService.getStreak(activeBabyId);
    setStreakDays(streak.currentStreak);
  };

  const checkTrialStatus = async () => {
    if (!activeBabyId || !selectedBaby) return;
    const daysRemaining = await trialService.getTrialDaysRemaining();
    setTrialDaysRemaining(daysRemaining);
  };

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
      toast.error("Couldn't load your babies. Check your connection?");
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

  const handleQuickLog = async (type: EventType) => {
    if (!selectedBaby) return;
    
    const lastUsed = getLastUsed(type);
    const now = new Date();
    
    const quickEvent: Partial<EventRecord> = {
      baby_id: selectedBaby.id,
      family_id: selectedBaby.family_id,
      type,
      start_time: now.toISOString(),
      ...(type === 'feed' && {
        subtype: lastUsed.subtype || 'bottle',
        amount: lastUsed.amount || 4,
        unit: lastUsed.unit || 'oz',
        side: lastUsed.side,
      }),
      ...(type === 'diaper' && {
        subtype: lastUsed.subtype || 'wet',
      }),
      ...(type === 'sleep' && {
        end_time: now.toISOString(),
      }),
      ...(type === 'tummy_time' && {
        duration_min: lastUsed.duration_min || 5,
        end_time: new Date(now.getTime() + (lastUsed.duration_min || 5) * 60000).toISOString(),
      }),
    };

    try {
      await eventsService.createEvent(quickEvent as EventRecord);
      
      const formattedTime = format(now, 'h:mm a');
      let details = '';
      if (type === 'feed') {
        details = ` • ${lastUsed.amount || 4}${lastUsed.unit || 'oz'}`;
      }
      
      toast.success(`${type.charAt(0).toUpperCase() + type.slice(1)} logged`, {
        description: `${formattedTime}${details} (last used)`,
      });

      // Check if this is the first event
      if (events.length === 0 && !hasShownConfetti) {
        triggerConfetti();
        setHasShownConfetti(true);
      }

      loadTodayEvents();
    } catch (error) {
      console.error('Quick log error:', error);
      toast.error('Failed to log event', {
        description: 'Please try again.',
      });
    }
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
      <div className="min-h-screen bg-background flex items-center justify-center p-4">
        <div className="space-y-3 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-body text-muted-foreground">Loading your day...</p>
        </div>
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
            <div className="flex items-center gap-2">
              {trialDaysRemaining !== null && <TrialCountdown daysRemaining={trialDaysRemaining} />}
              {streakDays > 0 && <StreakCounter days={streakDays} />}
            </div>
          </div>
        )}

        {guestMode && showGuestBanner && <GuestModeBanner />}

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

        {/* AI Contextual Tips */}
        {selectedBaby && (() => {
          const tips = getContextualTips(selectedBaby.date_of_birth, events);
          const visibleTips = tips.filter(tip => !dismissedTips.includes(tip.id));
          
          return visibleTips.length > 0 ? (
            <div className="space-y-2">
              {visibleTips.map(tip => (
                <ContextualTipCard
                  key={tip.id}
                  tip={tip}
                  onDismiss={(tipId) => {
                    setDismissedTips(prev => {
                      const newDismissed = [...prev, tipId];
                      localStorage.setItem('dismissedTips', JSON.stringify(newDismissed));
                      return newDismissed;
                    });
                  }}
                />
              ))}
            </div>
          ) : null;
        })()}

        {!privacyBanner.isDismissed && (
          <Card className="bg-primary/5 border-primary/20">
            <CardContent className="p-4 flex items-start gap-3">
              <Lock className="h-5 w-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium mb-1">Your data stays private</p>
                <p className="text-xs text-muted-foreground">
                  No ads, no tracking. Data syncs only when you invite a caregiver.
                </p>
              </div>
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={privacyBanner.dismiss}
                className="flex-shrink-0 -mr-2"
              >
                <X className="h-4 w-4" />
              </Button>
            </CardContent>
          </Card>
        )}

        {!caregiverBanner.isDismissed && babies.length > 0 && (
          <Card className="bg-secondary/5 border-secondary/20">
            <CardContent className="p-4">
              <div className="flex items-start gap-3 mb-3">
                <Users className="h-5 w-5 text-secondary flex-shrink-0 mt-0.5" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium mb-1">Invite your partner</p>
                  <p className="text-xs text-muted-foreground">
                    Sync logs across devices in real-time
                  </p>
                </div>
              </div>
              <div className="flex gap-2">
                <Button 
                  size="sm" 
                  onClick={() => navigate('/settings/caregivers')}
                  className="flex-1"
                >
                  Invite
                </Button>
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={caregiverBanner.dismiss}
                >
                  Dismiss
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        <QuickActions 
          onActionSelect={handleQuickAction}
          onQuickLog={handleQuickLog}
          recentEvents={events}
        />

        <div className="space-y-3">
          <h2 className="text-headline">Today's Timeline</h2>
          <TimelineList
            events={events}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        </div>

        <p className="text-xs text-center text-muted-foreground py-4 px-6">
          This app is not medical advice. Consult your pediatrician for guidance.
        </p>
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
          prefillData={modalState.prefillData}
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
