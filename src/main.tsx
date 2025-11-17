import { createRoot } from "react-dom/client";
import { useEffect } from "react";
import App from "./App.tsx";
import "./index.css";
import { useAppStore } from './store/appStore';
import { ErrorBoundary } from './components/ErrorBoundary';

function AppWrapper() {
  const caregiverMode = useAppStore((state) => state.caregiverMode);
  
  useEffect(() => {
    if (caregiverMode) {
      document.body.classList.add('caregiver-mode');
    } else {
      document.body.classList.remove('caregiver-mode');
    }
  }, [caregiverMode]);
  
  return <App />;
}

createRoot(document.getElementById("root")!).render(
  <ErrorBoundary>
    <AppWrapper />
  </ErrorBoundary>
);
