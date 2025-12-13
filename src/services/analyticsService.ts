import type { EventType } from '@/types/events';
import { track } from '@/analytics/analytics';
import * as Sentry from '@sentry/react';

interface AnalyticsData {
  [key: string]: unknown;
}

/**
 * Analytics service for tracking user actions with Firebase Analytics and Sentry error reporting
 */
class AnalyticsService {
  private enabled = true;

  private log(event: string, data?: AnalyticsData) {
    if (!this.enabled) return;

    // Send breadcrumb to Sentry for user actions
    Sentry.addBreadcrumb({
      message: event,
      category: 'user_action',
      level: 'info',
      data: data || {},
    });

    // Track with Firebase Analytics
    track(event, data);
  }

  trackOnboardingStarted() {
    this.log('onboarding_started');
  }

  trackOnboardingStepSkipped(stepId: string) {
    this.log('onboarding_step_skipped', { step_id: stepId });
  }

  trackOnboardingDropoff(stepId: string, timeSpentSeconds: number) {
    this.log('onboarding_dropoff', { step_id: stepId, time_spent_seconds: timeSpentSeconds });
  }

  trackOnboardingComplete(babyId: string, durationSeconds?: number, stepsCompleted?: number) {
    this.log('onboarding_completed', {
      babyId,
      ...(durationSeconds !== undefined && { duration_seconds: durationSeconds }),
      ...(stepsCompleted !== undefined && { steps_completed: stepsCompleted }),
    });
  }

  trackOnboardingStepViewed(stepId: string) {
    this.log('onboarding_step_viewed', { step_id: stepId });
  }

  trackOnboardingFieldError(stepId: string, fieldName: string, errorType: string) {
    this.log('onboarding_field_error', {
      step_id: stepId,
      field_name: fieldName,
      error_type: errorType,
    });
  }

  trackWelcomeCardInteraction(action: 'item_clicked' | 'dismissed') {
    this.log('welcome_card_interaction', { action });
  }

  trackTimeToFirstLog(timeFromOnboardingMs: number) {
    this.log('time_to_first_log', {
      time_from_onboarding_seconds: Math.floor(timeFromOnboardingMs / 1000),
    });
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

  trackError(error: string, context?: AnalyticsData) {
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
