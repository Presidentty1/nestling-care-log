import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import type { Analytics } from 'firebase/analytics';
import { getAnalytics } from 'firebase/analytics';

// Firebase configuration
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};

// Lazy Firebase initialization (only if config is valid and not in Capacitor)
let app: FirebaseApp | null = null;
let analytics: Analytics | null = null;

function initializeFirebase(): { app: FirebaseApp | null; analytics: Analytics | null } {
  // Skip in Capacitor (has its own analytics)
  if (typeof window !== 'undefined' && (window as any).Capacitor) {
    return { app: null, analytics: null };
  }

  // Only initialize if we have required config
  if (!firebaseConfig.projectId || !firebaseConfig.apiKey) {
    return { app: null, analytics: null };
  }

  // Return existing instance if already initialized
  if (app) {
    return { app, analytics };
  }

  try {
    // Check if Firebase is already initialized
    const existingApps = getApps();
    if (existingApps.length > 0) {
      app = existingApps[0];
    } else {
      app = initializeApp(firebaseConfig);
    }

    // Initialize Analytics lazily (defer to avoid blocking)
    if (typeof window !== 'undefined') {
      try {
        analytics = getAnalytics(app);
      } catch (error) {
        console.warn('[Analytics] Firebase Analytics initialization failed:', error);
      }
    }
  } catch (error) {
    console.warn('[Firebase] Initialization failed:', error);
    app = null;
    analytics = null;
  }

  return { app, analytics };
}

// Lazy getters
export function getFirebaseApp(): FirebaseApp | null {
  if (!app) {
    const result = initializeFirebase();
    app = result.app;
    analytics = result.analytics;
  }
  return app;
}

export function getFirebaseAnalytics(): Analytics | null {
  if (!analytics && typeof window !== 'undefined') {
    const result = initializeFirebase();
    app = result.app;
    analytics = result.analytics;
  }
  return analytics;
}

// For backward compatibility, export lazy-initialized values
export { app, analytics };
