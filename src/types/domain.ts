// Domain types for application logic (camelCase)

export type EventType = 'feed' | 'sleep' | 'diaper' | 'tummy_time' | 'medication' | 'other';
export type FeedSubtype = 'breast' | 'bottle' | 'combo';
export type DiaperSubtype = 'wet' | 'dirty' | 'both';
export type SleepSubtype = 'nap' | 'night';
export type Side = 'left' | 'right' | 'both';

export interface Baby {
  id: string;
  familyId: string;
  name: string;
  dateOfBirth: string; // ISO 8601
  dueDate?: string; // ISO 8601
  sex?: 'male' | 'female' | 'other' | 'prefer_not_to_say';
  timeZone: string;
  primaryFeedingStyle?: 'breast' | 'formula' | 'combo';
  createdAt: string;
  updatedAt: string;
}

export interface EventRecord {
  id: string;
  babyId: string;
  familyId: string;
  type: EventType;
  subtype?: string;
  startTime: string; // ISO 8601
  endTime?: string; // ISO 8601
  durationMin?: number;
  durationSec?: number;
  amount?: number;
  unit?: string;
  note?: string;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
  
  // Additional specific fields
  side?: Side;
  diaperColor?: string;
  diaperTexture?: string;
}

export interface Family {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface FamilyMember {
  id: string;
  familyId: string;
  userId: string;
  role: 'admin' | 'member' | 'viewer';
  createdAt: string;
}

export interface Profile {
  id: string;
  email: string | null;
  name: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface NapFeedback {
  id: string;
  babyId: string;
  predictedStart: string;
  predictedEnd: string;
  rating: 'too_early' | 'just_right' | 'too_late';
  createdAt: string;
}

export type CryCategory = 'tired' | 'hungry' | 'uncomfortable' | 'pain_possible' | 'unknown';

export interface CryInsightSession {
  id: string;
  babyId: string;
  createdBy?: string;
  category: CryCategory;
  confidence: number;
  createdAt: string;
}

export interface GrowthRecord {
  id: string;
  babyId: string;
  recordedAt: string;
  weight?: number;
  length?: number;
  headCircumference?: number;
  unitSystem: 'metric' | 'imperial';
  percentileWeight?: number;
  percentileLength?: number;
  percentileHead?: number;
  note?: string;
  recordedBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Medication {
  id: string;
  babyId: string;
  name: string;
  dose?: string;
  frequency?: string;
  startDate: string;
  endDate?: string;
  reminderEnabled: boolean;
  reminderTimes?: string[];
  note?: string;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

export type HealthRecordType = 'temperature' | 'doctor_visit' | 'vaccine' | 'allergy' | 'illness' | 'other';

export interface HealthRecord {
  id: string;
  babyId: string;
  recordType: HealthRecordType;
  title: string;
  recordedAt: string;
  temperature?: number;
  vaccineName?: string;
  vaccineDose?: string;
  doctorName?: string;
  diagnosis?: string;
  treatment?: string;
  note?: string;
  attachments?: any;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Milestone {
  id: string;
  babyId: string;
  milestoneType: string;
  title: string;
  description?: string;
  achievedDate: string;
  photoUrl?: string;
  videoUrl?: string;
  note?: string;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface NotificationSettings {
  id: string;
  babyId: string;
  userId: string;
  enabled: boolean;
  quietHoursStart?: string;
  quietHoursEnd?: string;
  feedRemindersEnabled: boolean;
  feedReminderIntervalHours: number;
  napRemindersEnabled: boolean;
  napWindowReminderMinutes: number;
  diaperRemindersEnabled: boolean;
  diaperReminderIntervalHours: number;
  medicationRemindersEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}


