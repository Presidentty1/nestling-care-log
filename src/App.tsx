import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { queryClient } from "@/lib/queryClient";
import { useState, useEffect } from 'react';
import { useAppStore } from '@/store/appStore';
import { dataService } from '@/services/dataService';
import { notifyService } from '@/services/notifyService';
import OnboardingSimple from "./pages/OnboardingSimple";
import Home from "./pages/Home";
import History from "./pages/History";
import Labs from "./pages/Labs";
import Settings from "./pages/Settings";
import ManageBabiesPage from "./pages/Settings/ManageBabies";
import NotificationSettingsPage from "./pages/Settings/NotificationSettings";
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

function HomeGuard({ children }: { children: React.ReactNode }) {
  const { activeBabyId } = useAppStore();
  const [hasChecked, setHasChecked] = useState(false);
  const [hasBabies, setHasBabies] = useState(false);

  useEffect(() => {
    checkBabies();
  }, []);

  const checkBabies = async () => {
    const babies = await dataService.listBabies();
    setHasBabies(babies.length > 0);
    setHasChecked(true);
  };

  if (!hasChecked) return null;
  if (!hasBabies || !activeBabyId) return <Navigate to="/onboarding-simple" replace />;
  
  return <>{children}</>;
}

function AppContent() {
  const { activeBabyId, caregiverMode } = useAppStore();

  useEffect(() => {
    if (activeBabyId) {
      notifyService.startMonitoring(activeBabyId);
    }

    return () => {
      notifyService.stopMonitoring();
    };
  }, [activeBabyId]);

  return (
    <div className={caregiverMode ? 'caregiver-mode' : ''}>
      <Routes>
        <Route path="/" element={<Navigate to="/home" replace />} />
        <Route path="/onboarding-simple" element={<OnboardingSimple />} />
        <Route path="/home" element={<HomeGuard><Home /></HomeGuard>} />
        <Route path="/history" element={<HomeGuard><History /></HomeGuard>} />
        <Route path="/labs" element={<Labs />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/settings/babies" element={<ManageBabiesPage />} />
        <Route path="/settings/notifications" element={<NotificationSettingsPage />} />
        <Route path="/settings/privacy" element={<PrivacyDataPage />} />
        <Route path="/growth" element={<GrowthTracker />} />
        <Route path="/health" element={<HealthRecords />} />
        <Route path="/milestones" element={<Milestones />} />
        <Route path="/photos" element={<PhotoGallery />} />
        <Route path="/cry-insights" element={<CryInsights />} />
        <Route path="/ai-assistant" element={<AIAssistant />} />
        <Route path="/analytics" element={<HomeGuard><Analytics /></HomeGuard>} />
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
