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
