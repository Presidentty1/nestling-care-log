import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { queryClient } from "@/lib/queryClient";
import { useState, useEffect } from 'react';
import { useAppStore } from '@/store/appStore';
import { reminderService } from '@/services/reminderService';
import { NotificationBanner } from '@/components/NotificationBanner';
import { useAuth } from '@/hooks/useAuth';
import Auth from "./pages/Auth";
import Onboarding from "./pages/Onboarding";
import Home from "./pages/Home";
import History from "./pages/History";
import Labs from "./pages/Labs";
import Settings from "./pages/Settings";
import ManageBabiesPage from "./pages/Settings/ManageBabies";
import NotificationSettingsPage from "./pages/Settings/NotificationSettings";
import ManageCaregiversPage from "./pages/Settings/ManageCaregivers";
import PrivacyDataPage from "./pages/Settings/PrivacyData";
import GrowthTracker from "./pages/GrowthTracker";
import HealthRecords from "./pages/HealthRecords";
import Milestones from "./pages/Milestones";
import PhotoGallery from "./pages/PhotoGallery";
import CryInsights from "./pages/CryInsights";
import AIAssistant from "./pages/AIAssistant";
import Analytics from "./pages/Analytics";
import ShortcutsSettings from "./pages/ShortcutsSettings";
import SleepTraining from "./pages/SleepTraining";
import ActivityFeed from "./pages/ActivityFeed";
import Predictions from "./pages/Predictions";
import Journal from "./pages/Journal";
import JournalEntry from "./pages/JournalEntry";
import NewSleepTrainingSession from "./pages/NewSleepTrainingSession";
import Referrals from "./pages/Referrals";
import Accessibility from "./pages/Accessibility";
import Feedback from "./pages/Feedback";
import PrivacyCenter from "./pages/PrivacyCenter";
import NotFound from "./pages/NotFound";

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
        <Route path="/labs" element={<Labs />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/settings/babies" element={<ManageBabiesPage />} />
        <Route path="/settings/caregivers" element={<ManageCaregiversPage />} />
        <Route path="/settings/notifications" element={<NotificationSettingsPage />} />
        <Route path="/settings/privacy" element={<PrivacyDataPage />} />
        <Route path="/growth" element={<GrowthTracker />} />
        <Route path="/health" element={<HealthRecords />} />
        <Route path="/milestones" element={<Milestones />} />
        <Route path="/photos" element={<PhotoGallery />} />
        <Route path="/cry-insights" element={<CryInsights />} />
        <Route path="/ai-assistant" element={<AIAssistant />} />
        <Route path="/analytics" element={<AuthGuard><Analytics /></AuthGuard>} />
        <Route path="/settings/shortcuts" element={<ShortcutsSettings />} />
        <Route path="/sleep-training" element={<SleepTraining />} />
        <Route path="/activity-feed" element={<ActivityFeed />} />
        <Route path="/predictions" element={<Predictions />} />
        <Route path="/journal" element={<Journal />} />
        <Route path="/journal/new" element={<JournalEntry />} />
        <Route path="/journal/entry/:id" element={<JournalEntry />} />
        <Route path="/sleep-training/new-session" element={<NewSleepTrainingSession />} />
        <Route path="/referrals" element={<Referrals />} />
        <Route path="/accessibility" element={<Accessibility />} />
        <Route path="/feedback" element={<Feedback />} />
        <Route path="/privacy" element={<PrivacyCenter />} />
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
