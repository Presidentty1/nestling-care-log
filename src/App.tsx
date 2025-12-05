// React imports
import { useState, useEffect, lazy, Suspense, memo } from 'react';

// External libraries
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from "react-router-dom";

// UI components
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";

// Internal components
import { NotificationBanner } from '@/components/NotificationBanner';

// Internal utilities
import { queryClient } from "@/lib/queryClient";

// Services
import { reminderService } from '@/services/reminderService';

// Store
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { page } from '@/analytics/analytics';
import { ResilientErrorBoundary } from '@/components/ResilientErrorBoundary';
import { SettingsErrorBoundary, MainAppErrorBoundary, FeatureErrorBoundary, OnboardingErrorBoundary } from '@/components/errorBoundaries/RouteErrorBoundary';
import { ConflictResolutionModal } from '@/components/ConflictResolutionModal';
import { reportWebVitals } from '@/hooks/usePerformance';
import * as Sentry from '@sentry/react';

// Initialize Sentry for web app
Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN || 'https://your-sentry-dsn@sentry.io/project-id',
  environment: import.meta.env.MODE || 'development',
  release: import.meta.env.VITE_APP_VERSION || '1.0.0',

  // Performance monitoring
  tracesSampleRate: 1.0,

  // Capture console logs as breadcrumbs
  integrations: [
    new Sentry.BrowserTracing({
      tracePropagationTargets: ['localhost', /^https:\/\/your-domain\.com/],
    }),
    new Sentry.Replay({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],

  // Capture more context
  beforeSend: (event) => {
    // Add user context if available
    const user = JSON.parse(localStorage.getItem('supabase.auth.token') || '{}');
    if (user?.user?.id) {
      event.user = {
        id: user.user.id,
        email: user.user.email,
      };
    }

    // Add app context
    event.tags = {
      ...event.tags,
      app_version: import.meta.env.VITE_APP_VERSION || '1.0.0',
      user_agent: navigator.userAgent,
    };

    return event;
  },
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],

  // Configure breadcrumbs
  maxBreadcrumbs: 100,

  // Release health
  enableTracing: true,
});

// Initialize performance monitoring
if (typeof window !== 'undefined') {
  // Defer web vitals reporting to avoid blocking initial load
  setTimeout(() => {
    reportWebVitals();
  }, 100);
}

// Core pages (eager loaded for fast initial load)
import Auth from "./pages/Auth";
import Onboarding from "./pages/Onboarding";
import OnboardingSimple from "./pages/OnboardingSimple";
import Home from "./pages/Home";
import History from "./pages/History";
import Settings from "./pages/Settings";
import NotFound from "./pages/NotFound";

// Settings pages (lazy loaded for better performance)
const ManageBabiesPage = lazy(() => import("./pages/Settings/ManageBabies"));
const NotificationSettingsPage = lazy(() => import("./pages/Settings/NotificationSettings"));
const ManageCaregiversPage = lazy(() => import("./pages/Settings/ManageCaregivers"));
const PrivacyDataPage = lazy(() => import("./pages/Settings/PrivacyData"));
const AIDataSharingPage = lazy(() => import("./pages/Settings/AIDataSharing"));

// Heavy pages (lazy loaded for better performance)
const Labs = lazy(() => import("./pages/Labs"));
const GrowthTracker = lazy(() => import("./pages/GrowthTracker"));
const HealthRecords = lazy(() => import("./pages/HealthRecords"));
const Milestones = lazy(() => import("./pages/Milestones"));
const PhotoGallery = lazy(() => import("./pages/PhotoGallery"));
const CryInsights = lazy(() => import("./pages/CryInsights"));
const AIAssistant = lazy(() => import("./pages/AIAssistant"));
const Analytics = lazy(() => import("./pages/Analytics"));
const AnalyticsDashboard = lazy(() => import("./pages/AnalyticsDashboard"));
const Patterns = lazy(() => import("./pages/Patterns"));
const ShortcutsSettings = lazy(() => import("./pages/ShortcutsSettings"));
const Subscription = lazy(() => import("./pages/Subscription"));
const SubscriptionManagement = lazy(() => import("./pages/SubscriptionManagement"));
const SleepTraining = lazy(() => import("./pages/SleepTraining"));
const ActivityFeed = lazy(() => import("./pages/ActivityFeed"));
const Predictions = lazy(() => import("./pages/Predictions"));
const Journal = lazy(() => import("./pages/Journal"));
const JournalEntry = lazy(() => import("./pages/JournalEntry"));
const NewSleepTrainingSession = lazy(() => import("./pages/NewSleepTrainingSession"));
const Referrals = lazy(() => import("./pages/Referrals"));
const Accessibility = lazy(() => import("./pages/Accessibility"));
const Feedback = lazy(() => import("./pages/Feedback"));
const PrivacyCenter = lazy(() => import("./pages/PrivacyCenter"));
const Privacy = lazy(() => import("./pages/Privacy"));
const ParentWellness = lazy(() => import("./pages/ParentWellness"));
const Achievements = lazy(() => import("./pages/Achievements"));

// Optimized Suspense wrapper for lazy loaded routes
const SuspenseWrapper = memo(({ children }: { children: React.ReactNode }) => (
  <Suspense
    fallback={
      <div className="flex items-center justify-center min-h-screen animate-fade-in">
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
      <div className="min-h-screen flex items-center justify-center bg-surface">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  return <>{children}</>;
}

function AppContent() {
  const { activeBabyId, caregiverMode } = useAppStore();
  const location = useLocation();
  const navigate = useNavigate();
  const [showConflictModal, setShowConflictModal] = useState(false);

  // Track page views
  useEffect(() => {
    const pageName = location.pathname.replace('/', '') || 'home';
    page(pageName, {
      baby_id: activeBabyId || undefined
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

  const handleGoHome = () => {
    navigate('/home');
  };

  return (
    <ResilientErrorBoundary
      context="main-app"
      onGoHome={handleGoHome}
    >
      <div className={caregiverMode ? 'caregiver-mode' : ''}>
        <NotificationBanner />
        <Routes>
          {/* Root and auth routes */}
          <Route path="/" element={<Navigate to="/home" replace />} />
          <Route path="/auth" element={<Auth />} />

          {/* Onboarding flow with specific error boundary */}
          <Route path="/onboarding" element={
            <OnboardingErrorBoundary onGoHome={handleGoHome}>
              <AuthGuard><Onboarding /></AuthGuard>
            </OnboardingErrorBoundary>
          } />

          {/* Main app routes with error boundary */}
          <Route path="/home" element={
            <MainAppErrorBoundary onGoHome={handleGoHome}>
              <AuthGuard><Home /></AuthGuard>
            </MainAppErrorBoundary>
          } />
          <Route path="/history" element={
            <MainAppErrorBoundary onGoHome={handleGoHome}>
              <AuthGuard><History /></AuthGuard>
            </MainAppErrorBoundary>
          } />

          {/* Settings routes with specific error boundary */}
          <Route path="/settings" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <Settings />
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/babies" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><ManageBabiesPage /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/caregivers" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><ManageCaregiversPage /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/notifications" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><NotificationSettingsPage /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/privacy-data" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><PrivacyDataPage /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/ai-data-sharing" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AIDataSharingPage /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/settings/shortcuts" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><ShortcutsSettings /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />

          {/* Subscription routes */}
          <Route path="/subscription" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Subscription /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />
          <Route path="/subscription/manage" element={
            <SettingsErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><SubscriptionManagement /></SuspenseWrapper>
            </SettingsErrorBoundary>
          } />

          {/* Feature routes with specific error boundary */}
          <Route path="/labs" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Labs /></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/growth" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><GrowthTracker /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/health" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><HealthRecords /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/milestones" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><Milestones /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/photos" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><PhotoGallery /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/cry-insights" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><CryInsights /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/ai-assistant" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><AIAssistant /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/analytics" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><Analytics /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/analytics-dashboard" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><AnalyticsDashboard /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/patterns" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><Patterns /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/sleep-training" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><SleepTraining /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/sleep-training/new-session" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><NewSleepTrainingSession /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/activity-feed" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><ActivityFeed /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/smart-predictions" element={<Navigate to="/predictions" replace />} />
          <Route path="/predictions" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><Predictions /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/journal" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><Journal /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/journal/new" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><JournalEntry /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/journal/entry/:id" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><JournalEntry /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/referrals" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Referrals /></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/accessibility" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Accessibility /></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/feedback" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Feedback /></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/privacy" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><Privacy /></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="/parent-wellness" element={
            <FeatureErrorBoundary onGoHome={handleGoHome}>
              <SuspenseWrapper><AuthGuard><ParentWellness /></AuthGuard></SuspenseWrapper>
            </FeatureErrorBoundary>
          } />
          <Route path="*" element={<NotFound />} />
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

const App = () => (
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

export default App;
