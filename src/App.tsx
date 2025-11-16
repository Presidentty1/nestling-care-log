import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { queryClient } from "@/lib/queryClient";
import { useNotificationHandler } from "@/hooks/useNotificationHandler";
import Auth from "./pages/Auth";
import Onboarding from "./pages/Onboarding";
import Home from "./pages/Home";
import History from "./pages/History";
import Labs from "./pages/Labs";
import Settings from "./pages/Settings";
import NapDetails from "./pages/NapDetails";
import CaregiverManagement from "./pages/CaregiverManagement";
import ManageBabies from "./pages/ManageBabies";
import AcceptInvite from "./pages/AcceptInvite";
import NotFound from "./pages/NotFound";
import GrowthTracker from "./pages/GrowthTracker";
import HealthRecords from "./pages/HealthRecords";
import Milestones from "./pages/Milestones";
import PhotoGallery from "./pages/PhotoGallery";
import NotificationSettings from "./pages/NotificationSettings";
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

function AppContent() {
  useNotificationHandler();
  
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/home" replace />} />
      <Route path="/auth" element={<Auth />} />
      <Route path="/onboarding" element={<Onboarding />} />
      <Route path="/home" element={<Home />} />
      <Route path="/history" element={<History />} />
      <Route path="/labs" element={<Labs />} />
      <Route path="/settings" element={<Settings />} />
      <Route path="/nap-details" element={<NapDetails />} />
      <Route path="/settings/caregivers" element={<CaregiverManagement />} />
      <Route path="/settings/babies" element={<ManageBabies />} />
      <Route path="/settings/notifications" element={<NotificationSettings />} />
      <Route path="/invite/:token" element={<AcceptInvite />} />
      <Route path="/growth" element={<GrowthTracker />} />
      <Route path="/health" element={<HealthRecords />} />
      <Route path="/milestones" element={<Milestones />} />
      <Route path="/photos" element={<PhotoGallery />} />
      <Route path="/cry-insights" element={<CryInsights />} />
      <Route path="/ai-assistant" element={<AIAssistant />} />
      <Route path="/analytics" element={<Analytics />} />
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
      {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
      <Route path="*" element={<NotFound />} />
    </Routes>
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
