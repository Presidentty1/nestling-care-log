import { logEvent, setUserId, setUserProperties } from 'firebase/analytics';
import { getFirebaseAnalytics } from '@/lib/firebase';

/**
 * Analytics abstraction layer for Nestling web app using Firebase Analytics.
 */

export interface AnalyticsEvent {
  name: string;
  properties?: Record<string, any>;
  timestamp?: Date;
}

export interface AnalyticsService {
  track(eventName: string, properties?: Record<string, any>): void;
  identify(userId: string, traits?: Record<string, any>): void;
  page(name: string, properties?: Record<string, any>): void;
}

/**
 * Firebase Analytics implementation.
 * Tracks events to Firebase Analytics for production insights.
 */
class FirebaseAnalytics implements AnalyticsService {
  private get analytics() {
    return getFirebaseAnalytics();
  }

  private get isInitialized() {
    return !!this.analytics;
  }

  constructor() {
    // Defer initialization check to avoid blocking
    setTimeout(() => {
      if (this.isInitialized) {
        console.log('[Analytics] Firebase Analytics initialized');
      } else {
        console.warn('[Analytics] Firebase Analytics not available, using console logging');
      }
    }, 0);
  }

  track(eventName: string, properties?: Record<string, any>): void {
    const analyticsInstance = this.analytics;
    if (!analyticsInstance) {
      console.log('[Analytics]', eventName, properties || {});
      return;
    }

    try {
      // Firebase event names must be alphanumeric with underscores, max 40 chars
      const firebaseEventName = eventName.replace(/[^a-zA-Z0-9_]/g, '_').substring(0, 40);

      logEvent(analyticsInstance, firebaseEventName, properties);
    } catch (error) {
      console.error('[Analytics] Failed to track event:', error);
    }
  }

  identify(userId: string, traits?: Record<string, any>): void {
    const analyticsInstance = this.analytics;
    if (!analyticsInstance) {
      console.log('[Analytics] Identify:', userId, traits || {});
      return;
    }

    try {
      setUserId(analyticsInstance, userId);

      if (traits) {
        // Convert trait names to Firebase-friendly format
        const userProperties: Record<string, any> = {};
        Object.entries(traits).forEach(([key, value]) => {
          const firebaseKey = key.replace(/[^a-zA-Z0-9_]/g, '_').substring(0, 24);
          userProperties[firebaseKey] = value;
        });
        setUserProperties(analyticsInstance, userProperties);
      }
    } catch (error) {
      console.error('[Analytics] Failed to identify user:', error);
    }
  }

  page(name: string, properties?: Record<string, any>): void {
    const analyticsInstance = this.analytics;
    if (!analyticsInstance) {
      console.log('[Analytics] Page:', name, properties || {});
      return;
    }

    try {
      logEvent(analyticsInstance, 'page_view', {
        page_title: name,
        ...properties
      });
    } catch (error) {
      console.error('[Analytics] Failed to track page view:', error);
    }
  }
}

// Singleton instance
let analyticsInstance: AnalyticsService = new FirebaseAnalytics();

/**
 * Initialize analytics with a custom service.
 * Call this once at app startup if using a production analytics service.
 */
export function initAnalytics(service: AnalyticsService): void {
  analyticsInstance = service;
}

/**
 * Track an event.
 * 
 * @param eventName - Name of the event (e.g., 'event_logged', 'settings_changed')
 * @param properties - Optional event properties
 * 
 * @example
 * ```ts
 * track('event_logged', {
 *   event_type: 'feed',
 *   amount: 120,
 *   unit: 'ml'
 * });
 * ```
 */
export function track(eventName: string, properties?: Record<string, any>): void {
  analyticsInstance.track(eventName, properties);
}

/**
 * Identify a user.
 * 
 * @param userId - User ID
 * @param traits - User traits/properties
 * 
 * @example
 * ```ts
 * identify(user.id, {
 *   email: user.email,
 *   name: user.name
 * });
 * ```
 */
export function identify(userId: string, traits?: Record<string, any>): void {
  analyticsInstance.identify(userId, traits);
}

/**
 * Track a page view.
 * 
 * @param name - Page name (e.g., 'home', 'settings')
 * @param properties - Optional page properties
 * 
 * @example
 * ```ts
 * page('home', {
 *   baby_count: 2
 * });
 * ```
 */
export function page(name: string, properties?: Record<string, any>): void {
  analyticsInstance.page(name, properties);
}

// Export default instance for advanced usage
export default analyticsInstance;


