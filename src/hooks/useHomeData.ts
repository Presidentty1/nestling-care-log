import { useState, useEffect, useCallback } from 'react';
import { format, subDays, startOfDay, endOfDay } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import { logger } from '@/lib/logger';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { useRealtimeEvents } from '@/hooks/useRealtimeEvents';
import type { Baby } from '@/services/babyService';
import { babyService } from '@/services/babyService';
import type { EventRecord } from '@/services/eventsService';
import { eventsService } from '@/services/eventsService';
import { napPredictorService } from '@/services/napPredictorService';
import { reminderService } from '@/services/reminderService';
import { guestModeService } from '@/services/guestModeService';
import { streakService } from '@/services/streakService';
import { achievementService } from '@/services/achievementService';
import { trialService } from '@/services/trialService';
import { dataService } from '@/services/dataService';
import type { DailySummary } from '@/types/summary';
import { useLastUsedValues } from '@/hooks/useLastUsedValues';
import type { EventType } from '@/types/domain';

export function useHomeData() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { activeBabyId, setActiveBabyId, guestMode } = useAppStore();
  const { saveLastUsed } = useLastUsedValues();

  // State
  const [babies, setBabies] = useState<Baby[]>([]);
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState<DailySummary | null>(null);
  const [napWindow, setNapWindow] = useState<{ start: Date; end: Date; reason: string } | null>(
    null
  );
  const [streakDays, setStreakDays] = useState(0);
  const [showGuestBanner, setShowGuestBanner] = useState(false);
  const [showAffirmation, setShowAffirmation] = useState(false);
  const [trialDaysRemaining, setTrialDaysRemaining] = useState<number | null>(null);
  const [hasShownConfetti, setHasShownConfetti] = useState(false);
  const [hasShownFirstLogCelebration, setHasShownFirstLogCelebration] = useState(() => {
    const stored = localStorage.getItem(`first_log_celebration_${activeBabyId}`);
    return stored !== null ? JSON.parse(stored) : false;
  });

  // Load Initial Data (Babies/Guest Mode)
  useEffect(() => {
    const loadInitialData = async () => {
      if (guestMode) {
        await loadGuestMode();
      } else if (user) {
        await loadBabies();
      }
    };
    loadInitialData();
  }, [user, guestMode]);

  // Load Baby Specific Data
  useEffect(() => {
    if (activeBabyId) {
      loadBabyData();
      loadStreakData();
      checkTrialStatus();
    }
  }, [activeBabyId]);

  // Subscribe to events
  useEffect(() => {
    const unsubscribe = eventsService.subscribe((action, data) => {
      if (action === 'add') {
        handleEventAdded(data as EventRecord);
      } else if (action === 'update' || action === 'delete') {
        loadTodayEvents();
      }
    });
    return unsubscribe;
  }, [activeBabyId, events.length, hasShownConfetti, hasShownFirstLogCelebration]);

  // Real-time updates
  const handleRealtimeUpdate = useCallback(() => {
    if (activeBabyId) {
      loadTodayEvents();
    }
  }, [activeBabyId]);

  useRealtimeEvents(selectedBaby?.family_id, handleRealtimeUpdate);

  // Helper Functions
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

  const loadBabies = async () => {
    try {
      const babyList = await babyService.getUserBabies();
      setBabies(babyList);

      if (babyList.length === 0) {
        // Auto-provision logic
        try {
          const {
            data: { session },
          } = await supabase.auth.getSession();
          if (session) {
            const demoBirthdate = format(subDays(new Date(), 60), 'yyyy-MM-dd');
            const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            const response = await supabase.functions.invoke('bootstrap-user', {
              body: { babyName: 'Demo Baby', dateOfBirth: demoBirthdate, timezone },
            });
            if (!response.error) {
              const { babyId } = response.data as any;
              setActiveBabyId(babyId);
              localStorage.setItem('activeBabyId', babyId);
              setLoading(false);
              return;
            }
          }
        } catch (e) {
          logger.error('Auto-provision error', e, 'useHomeData');
        }
        navigate('/onboarding');
        return;
      }

      const storedBabyId = localStorage.getItem('activeBabyId');
      const activeId = babyList.find(b => b.id === storedBabyId)?.id || babyList[0].id;
      setActiveBabyId(activeId);
      setLoading(false);
    } catch (error) {
      logger.error('Failed to load babies', error, 'useHomeData');
      toast.error("Couldn't load your babies. Check your connection?");
      setLoading(false);
    }
  };

  const loadBabyData = async () => {
    if (!activeBabyId) return;
    try {
      const baby = await babyService.getBaby(activeBabyId);
      setSelectedBaby(baby);
      await refreshEvents(baby || undefined); // Pass baby directly to ensure it's used
    } catch (error) {
      logger.error('Failed to load baby data', error, 'useHomeData');
      toast.error('Failed to load data');
    }
  };

  const loadStreakData = async () => {
    if (!activeBabyId) return;
    const streak = await streakService.getStreak(activeBabyId);
    setStreakDays(streak.currentStreak);
  };

  const checkTrialStatus = async () => {
    if (!activeBabyId) return; // selectedBaby might be null initially
    const daysRemaining = await trialService.getTrialDaysRemaining();
    setTrialDaysRemaining(daysRemaining);
  };

  const loadTodayEvents = async () => {
    if (!activeBabyId) return;
    try {
      const today = new Date();
      const start = startOfDay(today);
      const end = endOfDay(today);

      const todayEvents = await eventsService.getEventsByRange(
        activeBabyId,
        start.toISOString(),
        end.toISOString()
      );

      setEvents(todayEvents);
      setSummary(eventsService.calculateSummary(todayEvents));
    } catch (error) {
      logger.error('Failed to load events', error, 'useHomeData');
    }
  };

  const refreshEvents = async (babyOverride?: Baby) => {
    if (!activeBabyId) return;
    const babyToUse = babyOverride || selectedBaby;

    const today = new Date();
    const start = startOfDay(today);
    const end = endOfDay(today);

    const todayEvents = await eventsService.getEventsByRange(
      activeBabyId,
      start.toISOString(),
      end.toISOString()
    );
    setEvents(todayEvents);
    setSummary(eventsService.calculateSummary(todayEvents));

    if (babyToUse) {
      const window = napPredictorService.calculateFromEvents(todayEvents, babyToUse.date_of_birth);
      setNapWindow(window);

      const lastFeed = await eventsService.getLastEventByType(activeBabyId, 'feed');
      reminderService.updateLastFeed(lastFeed);
      if (window) {
        reminderService.updateNapWindow({ start: window.start, end: window.end });
      }
    }
  };

  const handleEventAdded = (event: EventRecord) => {
    // Immediate UI updates (synchronous)
    if (event) {
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

    if (events.length === 0 && !hasShownConfetti) {
      setHasShownConfetti(true);
    }

    // Refresh events immediately for UI responsiveness
    refreshEvents();

    // Defer non-critical operations to idle time
    const scheduleIdleTask = (callback: () => void) => {
      if ('requestIdleCallback' in window) {
        requestIdleCallback(callback, { timeout: 2000 });
      } else {
        // Fallback for browsers without requestIdleCallback
        setTimeout(callback, 100);
      }
    };

    // Defer celebration toast (non-blocking)
    if (!hasShownFirstLogCelebration && activeBabyId) {
      scheduleIdleTask(() => {
        const hasFeeds = events.some(e => e.type === 'feed');
        const hasNaps = events.some(e => e.type === 'sleep');
        if (events.length >= 2 && hasFeeds && hasNaps) {
          toast.success('Great! With feeds + naps logged, we can now predict your next nap.');
          setHasShownFirstLogCelebration(true);
          localStorage.setItem(`first_log_celebration_${activeBabyId}`, 'true');
        }
      });
    }

    // Defer guest mode operations
    if (guestMode) {
      scheduleIdleTask(() => {
        guestModeService.incrementGuestEventCount().then(count => {
          if (count >= 3) setShowGuestBanner(true);
        });
      });
    }

    // Defer streak and achievement operations (non-critical for UI)
    if (activeBabyId) {
      scheduleIdleTask(() => {
        const today = format(new Date(), 'yyyy-MM-dd');
        // Batch streak operations
        streakService
          .markEventLogged(activeBabyId, today, event.type)
          .then(() => {
            return streakService.updateStreak(activeBabyId);
          })
          .then(streak => {
            setStreakDays(streak.currentStreak);
            // Defer achievement check further
            scheduleIdleTask(() => {
              achievementService
                .checkAndUnlockAchievements(activeBabyId, {
                  streakDays: streak.currentStreak,
                  eventType: event.type,
                  eventTime: new Date(event.start_time),
                })
                .then(newAchievements => {
                  newAchievements.forEach(achievement => {
                    toast.success(`Achievement unlocked: ${achievement.title}!`);
                  });
                });
            });
          });

        // Defer affirmation check
        scheduleIdleTask(() => {
          streakService.shouldShowAffirmation(activeBabyId).then(should => {
            if (should) setShowAffirmation(true);
          });
        });
      });
    }
  };

  return {
    babies,
    selectedBaby,
    events,
    loading,
    summary,
    napWindow,
    streakDays,
    showGuestBanner,
    showAffirmation,
    trialDaysRemaining,
    hasShownConfetti,
    refreshEvents,
    setHasShownConfetti,
    setActiveBabyId,
  };
}
