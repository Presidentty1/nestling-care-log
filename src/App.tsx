import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { queryClient } from "@/lib/queryClient";
import { useState, useEffect, lazy, Suspense } from 'react';
import { useAppStore } from '@/store/appStore';
import { reminderService } from '@/services/reminderService';
import { NotificationBanner } from '@/components/NotificationBanner';
import { useAuth } from '@/hooks/useAuth';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { page } from '@/analytics/analytics';

// Core pages (eager loaded)
import Auth from "./pages/Auth";
import Onboarding from "./pages/Onboarding";
import OnboardingSimple from "./pages/OnboardingSimple";
import Home from "./pages/Home";
import History from "./pages/History";
import Settings from "./pages/Settings";
import ManageBabiesPage from "./pages/Settings/ManageBabies";
import NotificationSettingsPage from "./pages/Settings/NotificationSettings";
import ManageCaregiversPage from "./pages/Settings/ManageCaregivers";
import PrivacyDataPage from "./pages/Settings/PrivacyData";
import AIDataSharingPage from "./pages/Settings/AIDataSharing";
import NotFound from "./pages/NotFound";

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

// Suspense wrapper for lazy loaded routes
function SuspenseWrapper({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="flex items-center justify-center min-h-screen animate-fade-in">
          <LoadingSpinner />
        </div>
      }
    >
      {children}
    </Suspense>
  );
}

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

  return (
    <div className={caregiverMode ? 'caregiver-mode' : ''}>
      <NotificationBanner />
      <Routes>
        <Route path="/" element={<Navigate to="/home" replace />} />
        <Route path="/auth" element={<Auth />} />
        <Route path="/onboarding" element={<AuthGuard><Onboarding /></AuthGuard>} />
        <Route path="/home" element={<AuthGuard><Home /></AuthGuard>} />
        <Route path="/history" element={<AuthGuard><History /></AuthGuard>} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/settings/babies" element={<ManageBabiesPage />} />
        <Route path="/settings/caregivers" element={<ManageCaregiversPage />} />
        <Route path="/settings/notifications" element={<NotificationSettingsPage />} />
        <Route path="/settings/privacy-data" element={<PrivacyDataPage />} />
        <Route path="/settings/ai-data-sharing" element={<AIDataSharingPage />} />
        <Route path="/settings/shortcuts" element={<SuspenseWrapper><ShortcutsSettings /></SuspenseWrapper>} />
        
        {/* Lazy loaded routes for better performance */}
        <Route path="/labs" element={<SuspenseWrapper><Labs /></SuspenseWrapper>} />
        <Route path="/growth" element={<SuspenseWrapper><AuthGuard><GrowthTracker /></AuthGuard></SuspenseWrapper>} />
        <Route path="/health" element={<SuspenseWrapper><AuthGuard><HealthRecords /></AuthGuard></SuspenseWrapper>} />
        <Route path="/milestones" element={<SuspenseWrapper><AuthGuard><Milestones /></AuthGuard></SuspenseWrapper>} />
        <Route path="/photos" element={<SuspenseWrapper><AuthGuard><PhotoGallery /></AuthGuard></SuspenseWrapper>} />
        <Route path="/cry-insights" element={<SuspenseWrapper><AuthGuard><CryInsights /></AuthGuard></SuspenseWrapper>} />
        <Route path="/ai-assistant" element={<SuspenseWrapper><AuthGuard><AIAssistant /></AuthGuard></SuspenseWrapper>} />
        <Route path="/analytics" element={<SuspenseWrapper><AuthGuard><Analytics /></AuthGuard></SuspenseWrapper>} />
        <Route path="/analytics-dashboard" element={<SuspenseWrapper><AuthGuard><AnalyticsDashboard /></AuthGuard></SuspenseWrapper>} />
        <Route path="/patterns" element={<SuspenseWrapper><AuthGuard><Patterns /></AuthGuard></SuspenseWrapper>} />
        <Route path="/sleep-training" element={<SuspenseWrapper><AuthGuard><SleepTraining /></AuthGuard></SuspenseWrapper>} />
        <Route path="/sleep-training/new-session" element={<SuspenseWrapper><AuthGuard><NewSleepTrainingSession /></AuthGuard></SuspenseWrapper>} />
        <Route path="/activity-feed" element={<SuspenseWrapper><AuthGuard><ActivityFeed /></AuthGuard></SuspenseWrapper>} />
        <Route path="/smart-predictions" element={<Navigate to="/predictions" replace />} />
        <Route path="/predictions" element={<SuspenseWrapper><AuthGuard><Predictions /></AuthGuard></SuspenseWrapper>} />
        <Route path="/journal" element={<SuspenseWrapper><AuthGuard><Journal /></AuthGuard></SuspenseWrapper>} />
        <Route path="/journal/new" element={<SuspenseWrapper><AuthGuard><JournalEntry /></AuthGuard></SuspenseWrapper>} />
        <Route path="/journal/entry/:id" element={<SuspenseWrapper><AuthGuard><JournalEntry /></AuthGuard></SuspenseWrapper>} />
        <Route path="/referrals" element={<SuspenseWrapper><Referrals /></SuspenseWrapper>} />
        <Route path="/accessibility" element={<SuspenseWrapper><Accessibility /></SuspenseWrapper>} />
        <Route path="/feedback" element={<SuspenseWrapper><Feedback /></SuspenseWrapper>} />
        <Route path="/privacy" element={<SuspenseWrapper><Privacy /></SuspenseWrapper>} />
        <Route path="/parent-wellness" element={<SuspenseWrapper><AuthGuard><ParentWellness /></AuthGuard></SuspenseWrapper>} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
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
