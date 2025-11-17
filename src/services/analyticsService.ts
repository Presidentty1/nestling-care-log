import { EventType } from '@/types/events';

/**
 * Analytics service for tracking user actions
 * Console stub for MVP - will be replaced with real analytics later
 */
class AnalyticsService {
  private enabled = true;

  private log(event: string, data?: any) {
    if (!this.enabled) return;
    console.log(`[Analytics] ${event}`, data || '');
  }

  trackOnboardingComplete(babyId: string) {
    this.log('onboarding_completed', { babyId });
  }

  trackBabySwitch(babyId: string) {
    this.log('baby_switched', { babyId });
  }

  trackEventSaved(type: EventType, subtype?: string) {
    this.log('event_saved', { type, subtype });
  }

  trackEventEdited(eventId: string, type: EventType) {
    this.log('event_edited', { eventId, type });
  }

  trackEventDeleted(eventId: string, type: EventType) {
    this.log('event_deleted', { eventId, type });
  }

  trackNapRecalc(ageMonths: number) {
    this.log('nap_recalculated', { ageMonths });
  }

  trackFeedbackSubmitted(rating: string) {
    this.log('nap_feedback_submitted', { rating });
  }

  trackExport(format: 'csv' | 'pdf') {
    this.log('data_exported', { format });
  }

  trackDeleteAllData() {
    this.log('delete_all_data');
  }

  trackBabyCreated(babyId: string) {
    this.log('baby_created', { babyId });
  }

  trackBabyUpdated(babyId: string) {
    this.log('baby_updated', { babyId });
  }

  trackBabyDeleted(babyId: string) {
    this.log('baby_deleted', { babyId });
  }

  trackNotificationSettingsSaved() {
    this.log('notification_settings_saved');
  }

  trackNotificationPermissionRequested() {
    this.log('notification_permission_requested');
  }

  trackCaregiverModeToggled(enabled: boolean) {
    this.log('caregiver_mode_toggled', { enabled });
  }

  trackPageView(page: string) {
    this.log('page_view', { page });
  }

  trackError(error: string, context?: any) {
    this.log('error', { error, context });
  }

  disable() {
    this.enabled = false;
  }

  enable() {
    this.enabled = true;
  }
}

export const analyticsService = new AnalyticsService();
