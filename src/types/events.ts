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
