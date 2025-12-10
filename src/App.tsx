// React imports
import { useState, useEffect, lazy, Suspense, memo } from 'react';

// External libraries
import { QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';

// UI components
import { Toaster } from '@/components/ui/toaster';
import { Toaster as Sonner } from '@/components/ui/sonner';
import { TooltipProvider } from '@/components/ui/tooltip';

// Internal components
import { NotificationBanner } from '@/components/NotificationBanner';

// Internal utilities
import { queryClient } from '@/lib/queryClient';

// Services
import { reminderService } from '@/services/reminderService';

// Store
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { page } from '@/analytics/analytics';
import { ResilientErrorBoundary } from '@/components/ResilientErrorBoundary';
import {
  SettingsErrorBoundary,
  MainAppErrorBoundary,
  FeatureErrorBoundary,
  OnboardingErrorBoundary,
} from '@/components/errorBoundaries/RouteErrorBoundary';
import { ConflictResolutionModal } from '@/components/ConflictResolutionModal';
import { reportWebVitals } from '@/hooks/usePerformance';
import * as Sentry from '@sentry/react';

const sentryDsn = import.meta.env.VITE_SENTRY_DSN;

const initializeSentry = () => {
  if (!sentryDsn || sentryDsn === 'https://your-sentry-dsn@sentry.io/project-id') return;
  if (typeof window !== 'undefined' && (window as any).Capacitor) return;

  try {
    const integrations = [];

    if (typeof Sentry.browserTracingIntegration === 'function') {
      integrations.push(
        Sentry.browserTracingIntegration({
          tracePropagationTargets: ['localhost', /^https:\/\/your-domain\.com/],
        })
      );
    }

    if (typeof Sentry.replayIntegration === 'function') {
      integrations.push(
        Sentry.replayIntegration({
          maskAllText: true,
          blockAllMedia: true,
        })
      );
    }

    Sentry.init({
      dsn: sentryDsn,
      environment: import.meta.env.MODE || 'development',
      release: import.meta.env.VITE_APP_VERSION || '1.0.0',
      tracesSampleRate: 1.0,
      integrations,
      beforeSend: event => {
        try {
          const user = JSON.parse(localStorage.getItem('supabase.auth.token') || '{}');
          if (user?.user?.id) {
            event.user = {
              id: user.user.id,
              email: user.user.email,
            };
          }
        } catch (e) {
          // Ignore parsing errors
        }

        event.tags = {
          ...event.tags,
          app_version: import.meta.env.VITE_APP_VERSION || '1.0.0',
          user_agent: navigator.userAgent,
        };

        return event;
      },
      replaysSessionSampleRate: 0.1,
      replaysOnErrorSampleRate: 1.0,
      maxBreadcrumbs: 100,
      enableTracing: true,
    });
  } catch (error) {
    console.warn('Sentry initialization failed:', error);
  }
};

// Initialize performance monitoring
if (typeof window !== 'undefined' && import.meta.env.DEV) {
  // Defer web vitals reporting to avoid blocking initial load
  setTimeout(() => {
    reportWebVitals();
  }, 3000);
}

// Core pages
import Onboarding from './pages/Onboarding';
import Home from './pages/Home';
import History from './pages/History';
import Settings from './pages/Settings';
import NotFound from './pages/NotFound';

// Settings pages (lazy loaded for better performance)
const Landing = lazy(() => import('./pages/Landing'));
const ManageBabiesPage = lazy(() => import('./pages/Settings/ManageBabies'));
const NotificationSettingsPage = lazy(() => import('./pages/Settings/NotificationSettings'));
const ManageCaregiversPage = lazy(() => import('./pages/Settings/ManageCaregivers'));
const PrivacyDataPage = lazy(() => import('./pages/Settings/PrivacyData'));
const AIDataSharingPage = lazy(() => import('./pages/Settings/AIDataSharing'));

// Heavy pages (lazy loaded for better performance)
const Labs = lazy(() => import('./pages/Labs'));
const GrowthTracker = lazy(() => import('./pages/GrowthTracker'));
const HealthRecords = lazy(() => import('./pages/HealthRecords'));
const Milestones = lazy(() => import('./pages/Milestones'));
const PhotoGallery = lazy(() => import('./pages/PhotoGallery'));
const CryInsights = lazy(() => import('./pages/CryInsights'));
const AIAssistant = lazy(() => import('./pages/AIAssistant'));
const Analytics = lazy(() => import('./pages/Analytics'));
const AnalyticsDashboard = lazy(() => import('./pages/AnalyticsDashboard'));
const Patterns = lazy(() => import('./pages/Patterns'));
const ShortcutsSettings = lazy(() => import('./pages/ShortcutsSettings'));
const Subscription = lazy(() => import('./pages/Subscription'));
const SubscriptionManagement = lazy(() => import('./pages/SubscriptionManagement'));
const SleepTraining = lazy(() => import('./pages/SleepTraining'));
const ActivityFeed = lazy(() => import('./pages/ActivityFeed'));
const Predictions = lazy(() => import('./pages/Predictions'));
const Journal = lazy(() => import('./pages/Journal'));
const JournalEntry = lazy(() => import('./pages/JournalEntry'));
const NewSleepTrainingSession = lazy(() => import('./pages/NewSleepTrainingSession'));
const Referrals = lazy(() => import('./pages/Referrals'));
const Accessibility = lazy(() => import('./pages/Accessibility'));
const Feedback = lazy(() => import('./pages/Feedback'));
const PrivacyCenter = lazy(() => import('./pages/PrivacyCenter'));
const Privacy = lazy(() => import('./pages/Privacy'));
const ParentWellness = lazy(() => import('./pages/ParentWellness'));
const Achievements = lazy(() => import('./pages/Achievements'));

// Optimized Suspense wrapper for lazy loaded routes
const SuspenseWrapper = memo(({ children }: { children: React.ReactNode }) => (
  <Suspense
    fallback={
      <div className='flex items-center justify-center min-h-screen animate-fade-in'>
        <LoadingSpinner />
      </div>
    }
  >
    {children}
  </Suspense>
));

function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className='min-h-screen flex items-center justify-center bg-surface'>
        <div className='text-center'>
          <div className='animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto'></div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

function AppContent() {
  const { activeBabyId, caregiverMode } = useAppStore();
  const { user, loading: authLoading, signIn, signUp } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [showConflictModal, setShowConflictModal] = useState(false);
  const [autoLoginAttempted, setAutoLoginAttempted] = useState(false);

  // Track page views
  useEffect(() => {
    const pageName = location.pathname.replace('/', '') || 'home';
    page(pageName, {
      baby_id: activeBabyId || undefined,
    });
  }, [location.pathname, activeBabyId]);

  useEffect(() => {
    if (activeBabyId) {
      reminderService.start();
    }

    return () => {
      reminderService.stop();
    };
  }, [activeBabyId]);

  // Automatically sign in with dev account to skip the login screen
  useEffect(() => {
    if (authLoading || autoLoginAttempted || user) return;
    let cancelled = false;

    const autoLogin = async () => {
      try {
        let { error } = await signIn('dev@nestling.app', 'devpass123');

        if (error?.message?.includes('Invalid login credentials')) {
          const signUpResult = await signUp('dev@nestling.app', 'devpass123', 'Dev User');
          error = signUpResult.error;
        }

        if (error && !cancelled) {
          console.warn('Auto-login failed:', error.message);
        }
      } catch (err) {
        if (!cancelled) {
          console.warn('Auto-login threw an error:', err);
        }
      } finally {
        if (!cancelled) {
          setAutoLoginAttempted(true);
        }
      }
    };

    autoLogin();

    return () => {
      cancelled = true;
    };
  }, [authLoading, autoLoginAttempted, signIn, signUp, user]);

  const handleGoHome = () => {
    navigate('/home');
  };

  return (
    <ResilientErrorBoundary context='main-app' onGoHome={handleGoHome}>
      <div className={caregiverMode ? 'caregiver-mode' : ''}>
        <NotificationBanner />
        <Routes>
          {/* Root and auth routes */}
          <Route path='/' element={<Navigate to='/home' replace />} />
          <Route path='/auth' element={<Navigate to='/home' replace />} />
          <Route
            path='/landing'
            element={
              <SuspenseWrapper>
                <Landing />
              </SuspenseWrapper>
            }
          />
          {/* Onboarding flow with specific error boundary */}
          <Route
            path='/onboarding'
            element={
              <OnboardingErrorBoundary onGoHome={handleGoHome}>
                <AuthGuard>
                  <Onboarding />
                </AuthGuard>
              </OnboardingErrorBoundary>
            }
          />

          {/* Main app routes with error boundary */}
          <Route
            path='/home'
            element={
              <MainAppErrorBoundary onGoHome={handleGoHome}>
                <AuthGuard>
                  <Home />
                </AuthGuard>
              </MainAppErrorBoundary>
            }
          />
          <Route
            path='/history'
            element={
              <MainAppErrorBoundary onGoHome={handleGoHome}>
                <AuthGuard>
                  <History />
                </AuthGuard>
              </MainAppErrorBoundary>
            }
          />

          {/* Settings routes with specific error boundary */}
          <Route
            path='/settings'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <Settings />
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/babies'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <ManageBabiesPage />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/caregivers'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <ManageCaregiversPage />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/notifications'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <NotificationSettingsPage />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/privacy-data'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <PrivacyDataPage />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/ai-data-sharing'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AIDataSharingPage />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/settings/shortcuts'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <ShortcutsSettings />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />

          {/* Subscription routes */}
          <Route
            path='/subscription'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Subscription />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />
          <Route
            path='/subscription/manage'
            element={
              <SettingsErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <SubscriptionManagement />
                </SuspenseWrapper>
              </SettingsErrorBoundary>
            }
          />

          {/* Feature routes with specific error boundary */}
          <Route
            path='/labs'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Labs />
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/growth'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <GrowthTracker />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/health'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <HealthRecords />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/milestones'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <Milestones />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/photos'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <PhotoGallery />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/cry-insights'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <CryInsights />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/ai-assistant'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <AIAssistant />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/analytics'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <Analytics />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/analytics-dashboard'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <AnalyticsDashboard />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/patterns'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <Patterns />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/sleep-training'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <SleepTraining />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/sleep-training/new-session'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <NewSleepTrainingSession />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/activity-feed'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <ActivityFeed />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route path='/smart-predictions' element={<Navigate to='/predictions' replace />} />
          <Route
            path='/predictions'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <Predictions />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/journal'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <Journal />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/journal/new'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <JournalEntry />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/journal/entry/:id'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <JournalEntry />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/referrals'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Referrals />
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/accessibility'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Accessibility />
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/feedback'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Feedback />
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/privacy'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <Privacy />
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route
            path='/parent-wellness'
            element={
              <FeatureErrorBoundary onGoHome={handleGoHome}>
                <SuspenseWrapper>
                  <AuthGuard>
                    <ParentWellness />
                  </AuthGuard>
                </SuspenseWrapper>
              </FeatureErrorBoundary>
            }
          />
          <Route path='*' element={<NotFound />} />
        </Routes>

        {/* Global modals */}
        <ConflictResolutionModal
          isOpen={showConflictModal}
          onClose={() => setShowConflictModal(false)}
        />
      </div>
    </ResilientErrorBoundary>
  );
}

function App() {
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const scheduleInit = () => initializeSentry();

    if ('requestIdleCallback' in window) {
      (window as any).requestIdleCallback(scheduleInit, { timeout: 2000 });
    } else {
      setTimeout(scheduleInit, 500);
    }
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <AppContent />
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
