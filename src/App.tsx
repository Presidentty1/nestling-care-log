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
import AcceptInvite from "./pages/AcceptInvite";
import NotFound from "./pages/NotFound";
import GrowthTracker from "./pages/GrowthTracker";
import HealthRecords from "./pages/HealthRecords";
import Milestones from "./pages/Milestones";
import PhotoGallery from "./pages/PhotoGallery";
import NotificationSettings from "./pages/NotificationSettings";

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
      <Route path="/settings/notifications" element={<NotificationSettings />} />
      <Route path="/invite/:token" element={<AcceptInvite />} />
      <Route path="/growth" element={<GrowthTracker />} />
      <Route path="/health" element={<HealthRecords />} />
      <Route path="/milestones" element={<Milestones />} />
      <Route path="/photos" element={<PhotoGallery />} />
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
