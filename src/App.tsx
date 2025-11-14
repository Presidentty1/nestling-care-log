import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { queryClient } from "@/lib/queryClient";
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

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
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
          <Route path="/invite/:token" element={<AcceptInvite />} />
          <Route path="/growth" element={<GrowthTracker />} />
          <Route path="/health" element={<HealthRecords />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
