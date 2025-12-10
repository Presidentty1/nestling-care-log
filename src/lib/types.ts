// TypeScript types for Nestling app data models
// REFACTORED: This file now re-exports from standard locations.
// Prefer using types from '@/types/domain' for new code.

import type {
  DbProfile,
  DbFamily,
  DbFamilyMember,
  DbBaby,
  DbEvent,
  DbEventType,
  DbNapFeedback,
  DbCryCategory,
  DbCryInsightSession,
  DbGrowthRecord,
  DbMedication,
  DbHealthRecordType,
  DbHealthRecord,
  DbMilestone,
  DbNotificationSettings
} from '@/types/db';

export type Profile = DbProfile;
export type Family = DbFamily;
export type FamilyMember = DbFamilyMember;
export type Baby = DbBaby;
export type EventType = DbEventType;
export type BabyEvent = DbEvent;
export type NapFeedback = DbNapFeedback;
export type CryCategory = DbCryCategory;
export type CryInsightSession = DbCryInsightSession;
export type GrowthRecord = DbGrowthRecord;
export type Medication = DbMedication;
export type HealthRecordType = DbHealthRecordType;
export type HealthRecord = DbHealthRecord;
export type Milestone = DbMilestone;
export type NotificationSettings = DbNotificationSettings;
