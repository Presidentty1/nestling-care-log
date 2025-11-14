// TypeScript types for Nestling app data models

export interface Profile {
  id: string;
  email: string | null;
  name: string | null;
  created_at: string;
  updated_at: string;
}

export interface Family {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface FamilyMember {
  id: string;
  family_id: string;
  user_id: string;
  role: 'admin' | 'member' | 'viewer';
  created_at: string;
}

export interface Baby {
  id: string;
  family_id: string;
  name: string;
  date_of_birth: string;
  due_date?: string | null;
  sex?: 'male' | 'female' | 'other' | 'prefer_not_to_say' | null;
  timezone: string;
  primary_feeding_style?: 'breast' | 'formula' | 'combo' | null;
  created_at: string;
  updated_at: string;
}

export type EventType = 'feed' | 'sleep' | 'diaper' | 'tummy_time' | 'medication' | 'other';

export interface BabyEvent {
  id: string;
  baby_id: string;
  family_id: string;
  type: EventType;
  subtype?: string | null;
  start_time: string;
  end_time?: string | null;
  amount?: number | null;
  unit?: string | null;
  note?: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
}

export interface NapFeedback {
  id: string;
  baby_id: string;
  predicted_start: string;
  predicted_end: string;
  rating: 'too_early' | 'just_right' | 'too_late';
  created_at: string;
}

export type CryCategory = 'tired' | 'hungry' | 'uncomfortable' | 'pain_possible' | 'unknown';

export interface CryInsightSession {
  id: string;
  baby_id: string;
  created_by?: string | null;
  category: CryCategory;
  confidence: number;
  created_at: string;
}

export interface GrowthRecord {
  id: string;
  baby_id: string;
  recorded_at: string;
  weight?: number | null;
  length?: number | null;
  head_circumference?: number | null;
  unit_system: 'metric' | 'imperial';
  percentile_weight?: number | null;
  percentile_length?: number | null;
  percentile_head?: number | null;
  note?: string | null;
  recorded_by?: string | null;
  created_at: string;
  updated_at: string;
}

export interface Medication {
  id: string;
  baby_id: string;
  name: string;
  dose?: string | null;
  frequency?: string | null;
  start_date: string;
  end_date?: string | null;
  reminder_enabled: boolean;
  reminder_times?: string[] | null;
  note?: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
}

export type HealthRecordType = 'temperature' | 'doctor_visit' | 'vaccine' | 'allergy' | 'illness' | 'other';

export interface HealthRecord {
  id: string;
  baby_id: string;
  record_type: HealthRecordType;
  title: string;
  recorded_at: string;
  temperature?: number | null;
  vaccine_name?: string | null;
  vaccine_dose?: string | null;
  doctor_name?: string | null;
  diagnosis?: string | null;
  treatment?: string | null;
  note?: string | null;
  attachments?: any;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
}

export interface Milestone {
  id: string;
  baby_id: string;
  milestone_type: string;
  title: string;
  description?: string | null;
  achieved_date: string;
  photo_url?: string | null;
  video_url?: string | null;
  note?: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
}

export interface NotificationSettings {
  id: string;
  baby_id: string;
  user_id: string;
  enabled: boolean;
  quiet_hours_start?: string | null;
  quiet_hours_end?: string | null;
  feed_reminders_enabled: boolean;
  feed_reminder_interval_hours: number;
  nap_reminders_enabled: boolean;
  nap_window_reminder_minutes: number;
  diaper_reminders_enabled: boolean;
  diaper_reminder_interval_hours: number;
  medication_reminders_enabled: boolean;
  created_at: string;
  updated_at: string;
}
