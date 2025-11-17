export type EventType = 'feed' | 'sleep' | 'diaper' | 'tummy_time';
export type FeedSubtype = 'breast' | 'bottle' | 'pumping';
export type Side = 'left' | 'right' | 'both';
export type DiaperSubtype = 'wet' | 'dirty' | 'both';
export type SleepSubtype = 'nap' | 'night';

export interface EventRecord {
  id: string;
  familyId: string;
  babyId: string;
  type: EventType;
  subtype?: string;
  side?: Side;
  amount?: number; // always stored in ml
  unit?: 'ml' | 'oz'; // user's preferred display unit
  startTime: string; // ISO 8601
  endTime?: string; // ISO 8601
  durationMin?: number;
  diaperColor?: string;
  diaperTexture?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  source: 'local' | 'sync';
  syncedAt?: string;
}

export interface TimerState {
  status: 'idle' | 'running' | 'paused' | 'stopped';
  eventId?: string;
  startTime?: string;
  pausedAt?: string;
  accumulatedMs: number;
}

export interface NapPrediction {
  nextWindowStartISO: string;
  nextWindowEndISO: string;
  confidence: number;
  reason: string;
}

export interface Baby {
  id: string;
  name: string;
  dobISO: string;
  sex?: 'm' | 'f' | 'other';
  timeZone: string;
  units: 'metric' | 'imperial';
  feedingStyle?: 'breast' | 'bottle' | 'both';
  createdAt: string;
  updatedAt: string;
}

export interface NapFeedback {
  id: string;
  babyId: string;
  predictionStartISO: string;
  predictionEndISO: string;
  rating: 'too_early' | 'just_right' | 'too_late';
  actualNapStartISO?: string;
  createdAt: string;
}

export interface NotificationSettings {
  feedReminderEnabled: boolean;
  feedReminderHours: number;
  napWindowAlertEnabled: boolean;
  diaperReminderEnabled: boolean;
  diaperReminderHours: number;
  quietHoursStart: string;
  quietHoursEnd: string;
}
