interface AnalyticsEvent {
  name: string;
  properties: Record<string, any>;
  timestamp: string;
}

class AnalyticsService {
  private events: AnalyticsEvent[] = [];
  private enabled = true;
  
  track(eventName: string, properties: Record<string, any> = {}): void {
    if (!this.enabled) return;
    
    const event: AnalyticsEvent = {
      name: eventName,
      properties: this.sanitizeProperties(properties),
      timestamp: new Date().toISOString(),
    };
    
    this.events.push(event);
    console.log('[Analytics]', event);
    
    if (this.events.length > 100) {
      this.events.shift();
    }
    localStorage.setItem('nestling_analytics', JSON.stringify(this.events));
  }
  
  private sanitizeProperties(properties: Record<string, any>): Record<string, any> {
    const sanitized = { ...properties };
    delete sanitized.babyName;
    delete sanitized.notes;
    delete sanitized.userId;
    return sanitized;
  }
  
  getEvents(): AnalyticsEvent[] {
    return this.events;
  }
  
  clearEvents(): void {
    this.events = [];
    localStorage.removeItem('nestling_analytics');
  }
  
  disable(): void {
    this.enabled = false;
  }
  
  enable(): void {
    this.enabled = true;
  }
}

export const analyticsService = new AnalyticsService();
