import { useState, useEffect, useMemo } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { format, differenceInMonths, differenceInMinutes, formatDistanceToNow } from 'date-fns';
import type { EventType } from '@/types/events';
import { BabySwitcherModal } from '@/components/BabySwitcherModal';
import { EventSheet } from '@/components/sheets/EventSheet';
import { SummaryChips } from '@/components/today/SummaryChips';
import { FloatingActionButtonRadial } from '@/components/FloatingActionButtonRadial';
import { MobileNav } from '@/components/MobileNav';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { eventsService, type EventRecord } from '@/services/eventsService';
import { logger } from '@/lib/logger';
import { DataComponentBoundary } from '@/components/errorBoundaries/ComponentErrorBoundary';
import { toast } from 'sonner';
import { TimelineList } from '@/components/today/TimelineList';
import { useKeyboardShortcuts } from '@/hooks/useKeyboardShortcuts';
import { useDismissibleBanner } from '@/hooks/useDismissibleBanner';
import { useLastUsedValues } from '@/hooks/useLastUsedValues';
import { Lock, Users, X, Milk, Moon, Droplet, Clock } from 'lucide-react';
import { ContextualTipCard } from '@/components/ContextualTipCard';
import { getContextualTips } from '@/lib/contextualTips';
import { GuestModeBanner } from '@/components/GuestModeBanner';
import { StreakCounter } from '@/components/StreakCounter';
import { TrialCountdown } from '@/components/TrialCountdown';
import { WelcomeCard } from '@/components/onboarding/WelcomeCard';
import { FirstLogCelebration } from '@/components/onboarding/FirstLogCelebration';
import { InstantAhaModal } from '@/components/InstantAhaModal';
import { MilestoneModal } from '@/components/MilestoneModal';
import { FeatureDiscoveryCard } from '@/components/FeatureDiscoveryCard';
import { ProgressionCard } from '@/components/ProgressionCard';
import { useHomeData } from '@/hooks/useHomeData';
import { useAppStore } from '@/store/appStore';
import { useFeatureDiscovery } from '@/hooks/useFeatureDiscovery';
import { track } from '@/analytics/analytics';
import type { MESSAGING } from '@/lib/messaging';
import { undoManager } from '@/lib/undoManager';
import { analyticsService } from '@/services/analyticsService';
import { SmartActionCard } from '@/components/today/SmartActionCard';

export default function Home() {
  const navigate = useNavigate();
  const location = useLocation();
  const { activeBabyId, guestMode, setActiveBabyId } = useAppStore();

  // Use custom hook for data
  const {
    babies,
    selectedBaby,
    events,
    loading,
    summary,
    napWindow,
    streakDays,
    showGuestBanner,
    trialDaysRemaining,
  } = useHomeData();

  // UI State
  const [modalState, setModalState] = useState<{
    open: boolean;
    type: EventType;
    editingId?: string;
    prefillData?: Record<string, unknown>;
  }>({
    open: false,
    type: 'feed',
  });
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);
  const [showFirstLogCelebration, setShowFirstLogCelebration] = useState(false);
  const [showInstantAha, setShowInstantAha] = useState(false);
  const [showMilestone, setShowMilestone] = useState<3 | 5 | 10 | null>(null);
  const [firstLogType, setFirstLogType] = useState<EventType>('feed');
  const [isFirstTimeUser, setIsFirstTimeUser] = useState(false);

  const privacyBanner = useDismissibleBanner('privacy_stance');
  const caregiverBanner = useDismissibleBanner('caregiver_invite');
  const { getLastUsed } = useLastUsedValues();
  const { getNextFeatureToIntroduce, markFeatureIntroduced, dismissFeature } =
    useFeatureDiscovery();

  // Check if this is a first-time user
  useEffect(() => {
    const hasSeenWelcome = localStorage.getItem('hasSeenWelcome');
    const hasAnyEvents = events.length > 0;
    setIsFirstTimeUser(!hasSeenWelcome && !hasAnyEvents);
  }, [events.length]);

  // Track days since first log for progressive banner display
  const daysSinceFirstLog = (() => {
    const firstLogTime = localStorage.getItem('onboardingCompletedAt');
    if (!firstLogTime) return 0;
    const daysSince = Math.floor((Date.now() - parseInt(firstLogTime)) / (1000 * 60 * 60 * 24));
    return daysSince;
  })();

  // Only show privacy banner for very new users (first 2 days)
  const shouldShowPrivacyBanner = !privacyBanner.isDismissed && daysSinceFirstLog < 2;

  // Only show caregiver banner after 3+ days of usage
  const shouldShowCaregiverBanner =
    !caregiverBanner.isDismissed && daysSinceFirstLog >= 3 && babies.length > 0;

  // Get next feature to introduce
  const nextFeature = getNextFeatureToIntroduce();

  const [dismissedTips, setDismissedTips] = useState<string[]>(() => {
    try {
      const stored = localStorage.getItem('dismissedTips');
      return stored ? JSON.parse(stored) : [];
    } catch {
      return [];
    }
  });

  useKeyboardShortcuts({
    escape: () => setModalState({ open: false, type: 'feed' }),
    newEvent: () => setModalState({ open: true, type: 'feed' }),
  });

  // Handle notification quick actions
  useEffect(() => {
    if (location.state?.openSheet) {
      setModalState({
        open: true,
        type: location.state.openSheet,
        prefillData: location.state.prefillData || {},
      });
      window.history.replaceState({}, document.title);
    }
  }, [location]);

  const handleQuickAction = (type: EventType) => {
    setModalState({ open: true, type });

    // Mark that user has seen welcome when they first interact
    if (isFirstTimeUser) {
      localStorage.setItem('hasSeenWelcome', 'true');
      setIsFirstTimeUser(false);
    }
  };

  const handleQuickLog = async (type: EventType) => {
    if (!selectedBaby) return;

    const lastUsed = getLastUsed(type);
    const now = new Date();

    // Ensure meaningful defaults for quick logging
    let feedAmount = lastUsed.amount || 4;
    const feedUnit = lastUsed.unit || 'oz';

    // Convert oz to ml if needed, and ensure minimum 10ml
    if (feedUnit === 'oz') {
      const mlAmount = feedAmount * 30; // 1oz = 30ml
      if (mlAmount < 10) {
        feedAmount = 4; // Default to 4oz (120ml)
      }
    } else if (feedUnit === 'ml' && feedAmount < 10) {
      feedAmount = 120; // Minimum 120ml
    }

    const sleepDurationMinutes = lastUsed.duration_min || 10;
    const sleepStartTime = new Date(now.getTime() - sleepDurationMinutes * 60000);

    const quickEvent: Partial<EventRecord> = {
      baby_id: selectedBaby.id,
      family_id: selectedBaby.family_id,
      type,
      start_time: type === 'sleep' ? sleepStartTime.toISOString() : now.toISOString(),
      ...(type === 'feed' && {
        subtype: lastUsed.subtype || 'bottle',
        amount: feedAmount,
        unit: feedUnit,
        side: lastUsed.side,
      }),
      ...(type === 'diaper' && {
        subtype: lastUsed.subtype || 'wet',
      }),
      ...(type === 'sleep' && {
        end_time: now.toISOString(),
        note: `Quick log nap (${sleepDurationMinutes} min)`,
      }),
      ...(type === 'tummy_time' && {
        duration_min: lastUsed.duration_min || 5,
        end_time: new Date(now.getTime() + (lastUsed.duration_min || 5) * 60000).toISOString(),
      }),
    };

    try {
      await eventsService.createEvent(
        quickEvent as Parameters<typeof eventsService.createEvent>[0]
      );

      // Track first log if this is the user's first event
      const onboardingCompletedAt = localStorage.getItem('onboardingCompletedAt');
      const hasTrackedFirstLog = localStorage.getItem('hasTrackedFirstLog');
      if (onboardingCompletedAt && !hasTrackedFirstLog) {
        const timeFromOnboarding = Date.now() - parseInt(onboardingCompletedAt);
        track('first_log', { timeFromOnboarding });
        localStorage.setItem('hasTrackedFirstLog', 'true');

        // Show instant aha moment instead of just celebration
        setFirstLogType(type);
        setShowInstantAha(true);
      } else {
        // Check for milestone celebrations (3rd, 5th, 10th log)
        const newEventCount = events.length + 1;
        const milestoneKey = `milestone_${newEventCount}`;
        const hasSeenMilestone = localStorage.getItem(milestoneKey);

        if (
          !hasSeenMilestone &&
          (newEventCount === 3 || newEventCount === 5 || newEventCount === 10)
        ) {
          localStorage.setItem(milestoneKey, 'true');
          setShowMilestone(newEventCount as 3 | 5 | 10);
        }
      }

      // Mark that user has seen welcome
      if (isFirstTimeUser) {
        localStorage.setItem('hasSeenWelcome', 'true');
        setIsFirstTimeUser(false);
      }

      const formattedTime = format(now, 'h:mm a');
      let details = '';
      if (type === 'feed') {
        details = ` • ${feedAmount}${feedUnit}`;
      } else if (type === 'sleep') {
        details = ` • ${sleepDurationMinutes} min`;
      }

      toast.success(`${type.charAt(0).toUpperCase() + type.slice(1)} logged`, {
        description: `${formattedTime}${details}`,
      });

      // Mark checklist items complete
      if (type === 'feed' && !localStorage.getItem('completed_firstFeed')) {
        localStorage.setItem('completed_firstFeed', 'true');
      } else if (type === 'diaper' && !localStorage.getItem('completed_firstDiaper')) {
        localStorage.setItem('completed_firstDiaper', 'true');
      } else if (type === 'sleep' && !localStorage.getItem('completed_firstSleep')) {
        localStorage.setItem('completed_firstSleep', 'true');
      }

      // No need to call loadTodayEvents, subscription in useHomeData handles it
    } catch (error) {
      logger.error('Quick log error', error, 'Home');
      toast.error('Failed to log event', {
        description: 'Please try again.',
      });
    }
  };

  const handleSleepToggle = async () => {
    if (!selectedBaby || !activeBabyId) return;

    try {
      if (activeSleepEvent) {
        await eventsService.updateEvent(activeSleepEvent.id, {
          end_time: new Date().toISOString(),
        });
        track('sleep_quick_action', { action: 'wake', event_id: activeSleepEvent.id });
        toast.success('Sleep ended');
      } else {
        const created = await eventsService.createEvent({
          baby_id: selectedBaby.id,
          family_id: selectedBaby.family_id,
          type: 'sleep',
          start_time: new Date().toISOString(),
        });
        track('sleep_quick_action', { action: 'start', event_id: created.id });
        toast.success('Sleep started');
      }
    } catch (error) {
      logger.error('Sleep toggle error', error, 'Home');
      toast.error('Unable to update sleep');
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
      // Get event before deleting for undo
      const eventToDelete = events.find(e => e.id === eventId);
      if (!eventToDelete) {
        toast.error('Event not found');
        return;
      }

      // Register deletion with undo manager
      undoManager.registerDeletion(eventToDelete, async () => {
        // Restore action: recreate the event
        try {
          const restoreData: Parameters<typeof eventsService.createEvent>[0] = {
            baby_id: eventToDelete.baby_id,
            family_id: eventToDelete.family_id,
            type: eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time',
            subtype: eventToDelete.subtype || undefined,
            amount: eventToDelete.amount || undefined,
            unit: (eventToDelete.unit as 'ml' | 'oz') || undefined,
            start_time: eventToDelete.start_time,
            end_time: eventToDelete.end_time || undefined,
            duration_min: eventToDelete.duration_min || undefined,
            duration_sec: eventToDelete.duration_sec || undefined,
            note: eventToDelete.note || undefined,
          };
          await eventsService.createEvent(restoreData);
          toast.success('Event restored');
        } catch (error) {
          logger.error('Failed to restore event', error, 'Home');
          toast.error('Failed to restore event');
        }
      });

      // Delete the event
      await eventsService.deleteEvent(eventId);

      // Show toast with undo button
      toast.success('Event deleted', {
        action: {
          label: 'Undo',
          onClick: async () => {
            try {
              await undoManager.undo();
              analyticsService.trackEventDeleted(
                eventId,
                eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time'
              );
              track('undo_action', { action_type: 'event_deleted' });
            } catch (error) {
              if (error instanceof Error && error.message.includes('expired')) {
                toast.error('Undo window has expired');
              } else {
                logger.error('Failed to undo deletion', error, 'Home');
                toast.error('Failed to undo');
              }
            }
          },
        },
        duration: 7000, // Match undo window
      });

      // Track analytics
      analyticsService.trackEventDeleted(
        eventId,
        eventToDelete.type as 'feed' | 'sleep' | 'diaper' | 'tummy_time'
      );
      track('event_deleted', {
        event_type: eventToDelete.type,
        undo_available: true,
      });
    } catch (error) {
      logger.error('Failed to delete event', error, 'Home');
      toast.error('Failed to delete event');
      undoManager.clear(); // Clear undo if delete failed
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

  // Memoize active sleep timer calculation
  const activeSleepTimer = useMemo(() => {
    const activeSleep = events.find(e => e.type === 'sleep' && !e.end_time);
    if (activeSleep) {
      return {
        startTime: new Date(activeSleep.start_time),
        isRunning: true,
      };
    }
    return null;
  }, [events]);

  const activeSleepEvent = useMemo(
    () => events.find(e => e.type === 'sleep' && !e.end_time),
    [events]
  );

  const lastFeed = useMemo(
    () =>
      events
        .filter(e => e.type === 'feed')
        .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0],
    [events]
  );
  const lastDiaper = useMemo(
    () =>
      events
        .filter(e => e.type === 'diaper')
        .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0],
    [events]
  );
  const lastTummyTime = useMemo(
    () =>
      events
        .filter(e => e.type === 'tummy_time')
        .sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime())[0],
    [events]
  );
  const lastCompletedSleep = useMemo(
    () =>
      events
        .filter(e => e.type === 'sleep' && e.end_time)
        .sort(
          (a, b) =>
            new Date(b.end_time || b.start_time).getTime() -
            new Date(a.end_time || a.start_time).getTime()
        )[0],
    [events]
  );

  const formatMinutes = (minutes: number | null | undefined) => {
    if (minutes === null || minutes === undefined) return '—';
    if (minutes < 60) return `${minutes}m`;
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
  };

  const timeSince = (iso?: string | null) => {
    if (!iso) return '—';
    return formatDistanceToNow(new Date(iso), { addSuffix: true });
  };

  const feedStatus = lastFeed
    ? timeSince(lastFeed.end_time || lastFeed.start_time)
    : 'No feeds yet';
  const feedDetail = lastFeed
    ? [
        lastFeed.amount ? `${lastFeed.amount}${lastFeed.unit || ''}` : null,
        lastFeed.subtype ? lastFeed.subtype : null,
      ]
        .filter(Boolean)
        .join(' • ')
    : 'Tap to log a feed';

  const diaperStatus = lastDiaper
    ? timeSince(lastDiaper.end_time || lastDiaper.start_time)
    : 'No diapers yet';
  const diaperDetail = lastDiaper?.subtype
    ? `Last was ${lastDiaper.subtype}`
    : 'Log the next change';

  const tummyStatus = lastTummyTime
    ? timeSince(lastTummyTime.end_time || lastTummyTime.start_time)
    : 'No tummy time yet';
  const tummyDetail = lastTummyTime?.duration_min
    ? `${lastTummyTime.duration_min} min session`
    : 'Tap to log tummy time';

  const awakeMinutes = useMemo(() => {
    if (activeSleepTimer?.isRunning) return null;
    if (!lastCompletedSleep?.end_time && !lastCompletedSleep?.start_time) return null;
    const endTime = lastCompletedSleep?.end_time || lastCompletedSleep?.start_time;
    if (!endTime) return null;
    return differenceInMinutes(new Date(), new Date(endTime));
  }, [activeSleepTimer?.isRunning, lastCompletedSleep?.end_time, lastCompletedSleep?.start_time]);

  const timeUntilNap =
    napWindow && napWindow.start > new Date()
      ? differenceInMinutes(napWindow.start, new Date())
      : null;

  const napWindowLabel =
    napWindow && napWindow.start && napWindow.end
      ? `${format(napWindow.start, 'h:mm')}–${format(napWindow.end, 'h:mma').toLowerCase()}`
      : null;

  const sleepStatus = activeSleepTimer?.isRunning
    ? `Sleeping • ${formatMinutes(differenceInMinutes(new Date(), activeSleepTimer.startTime))}`
    : awakeMinutes !== null
      ? `Awake • ${formatMinutes(awakeMinutes)}`
      : 'No sleep logged yet';

  const sleepDetail = activeSleepTimer?.isRunning
    ? 'Tap to wake and log the end time'
    : napWindowLabel
      ? `Next nap ${napWindowLabel}${
          timeUntilNap !== null && timeUntilNap > 0 ? ` (in ${formatMinutes(timeUntilNap)})` : ''
        }`
      : 'Start a nap when baby falls asleep';

  if (loading) {
    return (
      <div className='min-h-screen bg-background flex items-center justify-center p-4'>
        <div className='space-y-3 text-center'>
          <div className='animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto'></div>
          <p className='text-body text-muted-foreground'>Loading your day...</p>
        </div>
      </div>
    );
  }

  return (
    <div className='h-screen bg-background overflow-hidden flex flex-col safe-area-inset'>
      <div className='flex-1 overflow-y-auto overflow-x-hidden'>
        <div className='max-w-2xl mx-auto px-4 pt-4 pb-4 space-y-5 w-full'>
          {/* Page Title */}
          <h1 className='font-display text-left mb-6'>Home</h1>

          {selectedBaby && (
            <div className='flex items-center justify-between mb-2'>
              <Button
                variant='ghost'
                className='flex items-center gap-3 -ml-2 h-auto py-2'
                onClick={() => setIsSwitcherOpen(true)}
              >
                <Avatar className='h-11 w-11'>
                  <AvatarFallback className='text-base font-semibold'>
                    {getInitials(selectedBaby.name)}
                  </AvatarFallback>
                </Avatar>
                <div className='text-left'>
                  <div className='font-semibold text-[17px] leading-[24px]'>
                    {selectedBaby.name}
                  </div>
                  <div className='text-muted-foreground'>
                    {differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth))} months
                  </div>
                </div>
              </Button>
              <div className='flex items-center gap-2'>
                {trialDaysRemaining !== null && (
                  <TrialCountdown daysRemaining={trialDaysRemaining} />
                )}
                {streakDays > 0 && <StreakCounter days={streakDays} />}
              </div>
            </div>
          )}

          {guestMode && showGuestBanner && <GuestModeBanner />}

          {/* First-time user welcome card */}
          {isFirstTimeUser && events.length === 0 && (
            <WelcomeCard onLogFirstEvent={handleQuickAction} />
          )}

          {/* Progression Card - Show what's unlocking */}
          {events.length > 0 && events.length < 10 && (
            <ProgressionCard currentLogs={events.length} />
          )}

          {/* Smart Action Grid */}
          <div className='space-y-3'>
            <h2 className='text-headline'>Log & Status</h2>
            <div className='grid grid-cols-2 gap-3'>
              <SmartActionCard
                label='Feed'
                status={feedStatus}
                detail={feedDetail}
                hint='Tap to log • Long-press for details'
                icon={Milk}
                accent='feed'
                onPress={() => handleQuickLog('feed')}
                onLongPress={() => handleQuickAction('feed')}
              />
              <SmartActionCard
                label='Sleep'
                status={sleepStatus}
                detail={sleepDetail}
                hint={
                  activeSleepTimer
                    ? 'Tap to end sleep • Long-press for details'
                    : 'Tap to start sleep'
                }
                icon={Moon}
                accent='sleep'
                isActive={!!activeSleepTimer}
                badge={!activeSleepTimer && napWindowLabel ? 'Suggestion' : undefined}
                onPress={handleSleepToggle}
                onLongPress={() => handleQuickAction('sleep')}
              />
              <SmartActionCard
                label='Diaper'
                status={diaperStatus}
                detail={diaperDetail}
                hint='Tap to log • Long-press for details'
                icon={Droplet}
                accent='diaper'
                onPress={() => handleQuickLog('diaper')}
                onLongPress={() => handleQuickAction('diaper')}
              />
              <SmartActionCard
                label='Tummy Time'
                status={tummyStatus}
                detail={tummyDetail}
                hint='Tap to log • Long-press for details'
                icon={Clock}
                accent='tummy'
                onPress={() => handleQuickLog('tummy_time')}
                onLongPress={() => handleQuickAction('tummy_time')}
              />
            </div>
          </div>

          {/* Summary Chips */}
          {summary && (
            <DataComponentBoundary componentName='SummaryChips'>
              <SummaryChips summary={summary} />
            </DataComponentBoundary>
          )}

          {/* Feature Discovery - introduce new features progressively */}
          {nextFeature && (
            <FeatureDiscoveryCard
              featureKey={nextFeature as keyof typeof MESSAGING.features}
              onDismiss={() => dismissFeature(nextFeature)}
              onTryIt={() => {
                markFeatureIntroduced(nextFeature);
                // Navigation will be handled by the FeatureDiscoveryCard
              }}
            />
          )}

          {/* AI Contextual Tips - show max 1 at a time, only after first day, and only if no feature discovery card */}
          {!nextFeature &&
            selectedBaby &&
            daysSinceFirstLog >= 1 &&
            (() => {
              const tips = getContextualTips(selectedBaby.date_of_birth, events);
              const essentialTipIds = ['loose-logging', 'trust-yourself'];
              const essentialTips = tips.filter(tip => essentialTipIds.includes(tip.id));
              const otherTips = tips.filter(tip => !essentialTipIds.includes(tip.id));
              const visibleOtherTips = otherTips.filter(tip => !dismissedTips.includes(tip.id));

              // Show only 1 tip at a time for cleaner UX
              const visibleTips = [...essentialTips, ...visibleOtherTips].slice(0, 1);

              return visibleTips.length > 0 ? (
                <div className='space-y-2'>
                  {visibleTips.map(tip => (
                    <ContextualTipCard
                      key={tip.id}
                      tip={tip}
                      onDismiss={tipId => {
                        if (essentialTipIds.includes(tipId)) return;
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

          {/* Privacy banner - only for very new users */}
          {shouldShowPrivacyBanner && (
            <Card className='bg-primary/5 border-primary/20'>
              <CardContent className='p-4 flex items-start gap-3'>
                <Lock className='h-5 w-5 text-primary flex-shrink-0 mt-0.5' />
                <div className='flex-1 min-w-0'>
                  <p className='text-sm font-medium mb-1'>Your data stays private</p>
                  <p className='text-xs text-muted-foreground'>
                    No ads, no tracking. Data syncs only when you invite a caregiver.
                  </p>
                </div>
                <Button
                  variant='ghost'
                  size='sm'
                  onClick={privacyBanner.dismiss}
                  className='flex-shrink-0 -mr-2'
                >
                  <X className='h-4 w-4' />
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Caregiver invite banner - only after 3+ days */}
          {shouldShowCaregiverBanner && (
            <Card className='bg-secondary/5 border-secondary/20'>
              <CardContent className='p-4'>
                <div className='flex items-start gap-3 mb-3'>
                  <Users className='h-5 w-5 text-secondary flex-shrink-0 mt-0.5' />
                  <div className='flex-1 min-w-0'>
                    <p className='text-sm font-medium mb-1'>Invite your partner</p>
                    <p className='text-xs text-muted-foreground'>
                      Sync logs across devices in real-time
                    </p>
                  </div>
                </div>
                <div className='flex gap-2'>
                  <Button
                    size='sm'
                    onClick={() => navigate('/settings/caregivers')}
                    className='flex-1'
                  >
                    Invite
                  </Button>
                  <Button variant='ghost' size='sm' onClick={caregiverBanner.dismiss}>
                    Dismiss
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Secondary Content - Timeline */}
          <div className='space-y-3'>
            <h2 className='text-headline text-muted-foreground/70'>Today's Timeline</h2>
            <DataComponentBoundary componentName='TimelineList'>
              <TimelineList
                events={events}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onQuickAction={handleQuickAction}
              />
            </DataComponentBoundary>
          </div>

          <p className='text-xs text-center text-muted-foreground py-4 px-6'>
            This app is not medical advice. Consult your pediatrician for guidance.
          </p>
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

      {/* First log celebration */}
      <FirstLogCelebration
        isOpen={showFirstLogCelebration}
        onClose={() => setShowFirstLogCelebration(false)}
      />

      {/* Instant Aha Moment - Show AI value immediately */}
      {selectedBaby && (
        <InstantAhaModal
          isOpen={showInstantAha}
          onClose={() => {
            setShowInstantAha(false);
            // Show celebration after aha moment
            setShowFirstLogCelebration(true);
          }}
          babyAgeInWeeks={Math.floor(
            differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth)) * 4.33
          )}
          eventType={firstLogType}
        />
      )}

      {/* Milestone Celebrations - 3rd, 5th, 10th log */}
      {showMilestone && (
        <MilestoneModal
          isOpen={true}
          onClose={() => setShowMilestone(null)}
          milestone={showMilestone}
        />
      )}
    </div>
  );
}
