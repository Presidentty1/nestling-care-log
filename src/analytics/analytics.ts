/**
 * Analytics abstraction layer for Nestling web app.
 * 
 * Default implementation logs to console. Can be swapped with
 * production analytics service (e.g., PostHog, Mixpanel, Amplitude).
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
 * Default console-based analytics implementation.
 * Logs events to console in development, no-op in production.
 */
class ConsoleAnalytics implements AnalyticsService {
  private isDevelopment = import.meta.env.DEV;

  track(eventName: string, properties?: Record<string, any>): void {
    if (this.isDevelopment) {
      console.log('[Analytics]', eventName, properties || {});
    }
    // In production, this would send to analytics service
    // Example: analyticsService.track(eventName, properties);
  }

  identify(userId: string, traits?: Record<string, any>): void {
    if (this.isDevelopment) {
      console.log('[Analytics] Identify:', userId, traits || {});
    }
  }

  page(name: string, properties?: Record<string, any>): void {
    if (this.isDevelopment) {
      console.log('[Analytics] Page:', name, properties || {});
    }
  }
}

// Singleton instance
let analyticsInstance: AnalyticsService = new ConsoleAnalytics();

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


