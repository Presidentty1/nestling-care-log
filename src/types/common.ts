/**
 * Common types used across the application
 */

export type EventAction = 'add' | 'update' | 'delete';
export type DataAction = string;

export interface EventChangeData {
  id?: string;
  [key: string]: any;
}

export interface DataChangeData {
  [key: string]: any;
}

export type EventListener = (action: EventAction, data: EventChangeData) => void;
export type DataListener = (action: DataAction, data: DataChangeData) => void;

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export interface NapPrediction {
  windowStart: string;
  windowEnd: string;
  confidence: number;
  reasoning: string;
  source: 'age-based' | 'pattern-based';
  patterns?: {
    wakeTime?: string;
    lastNapDuration?: number;
    daySleepTotal?: number;
  };
}

export interface StorageEstimate {
  quota?: number;
  usage?: number;
  usageDetails?: {
    indexedDB?: number;
    caches?: number;
  };
}

export interface TimerData {
  timestamp: number;
  [key: string]: any;
}

export interface StoredEvent {
  id: string;
  baby_id: string;
  family_id: string;
  type: string;
  start_time: string;
  end_time?: string;
  duration_min?: number;
  duration_sec?: number;
  amount?: number;
  unit?: string;
  subtype?: string;
  side?: string;
  note?: string;
  diaper_color?: string;
  diaper_texture?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
  source?: string;
  [key: string]: any;
}

export interface StoredBaby {
  id: string;
  family_id: string;
  name: string;
  date_of_birth: string;
  sex?: string | null;
  primary_feeding_style?: string | null;
  timezone: string;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}
