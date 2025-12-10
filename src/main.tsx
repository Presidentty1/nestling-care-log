import { createRoot } from 'react-dom/client';
import { useEffect } from 'react';
import App from './App.tsx';
import './index.css';
import { useAppStore } from './store/appStore';
import { ErrorBoundary } from './components/ErrorBoundary';
import { registerServiceWorker } from './lib/serviceWorker';

// Initialize dark mode immediately to prevent flash
const initializeTheme = () => {
  const savedTheme = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

  // Default to system preference if no saved theme
  const shouldBeDark = savedTheme === 'dark' || (!savedTheme && prefersDark);

  if (shouldBeDark) {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }

  return shouldBeDark;
};

// Initialize theme before rendering to prevent flash
const isDarkMode = initializeTheme();

function AppWrapper() {
  const caregiverMode = useAppStore(state => state.caregiverMode);

  useEffect(() => {
    if (caregiverMode) {
      document.body.classList.add('caregiver-mode');
    } else {
      document.body.classList.remove('caregiver-mode');
    }
  }, [caregiverMode]);

  // Listen for system theme changes when using system preference
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme');
    if (!savedTheme) {
      // Only listen if using system preference
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      const handleChange = (e: MediaQueryListEvent) => {
        const root = document.documentElement;
        if (e.matches) {
          root.classList.add('dark');
        } else {
          root.classList.remove('dark');
        }
      };

      mediaQuery.addEventListener('change', handleChange);
      return () => mediaQuery.removeEventListener('change', handleChange);
    }
  }, []);

  return <App />;
}

createRoot(document.getElementById('root')!).render(
  <ErrorBoundary>
    <AppWrapper />
  </ErrorBoundary>
);

// Register service worker for offline support (defer to avoid blocking)
// Skip in Capacitor as it's not supported and can cause WebContent to hang
if (typeof window !== 'undefined' && !(window as any).Capacitor) {
  // Defer service worker registration to avoid blocking initial render
  setTimeout(() => {
    registerServiceWorker().catch(() => {
      // Silently fail - service workers are optional
    });
  }, 1000);
}
