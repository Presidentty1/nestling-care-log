import { z } from 'zod';

export const BabySchema = z.object({
  name: z.string().trim().min(1, 'Name is required').max(40, 'Name must be 40 characters or less'),
  dobISO: z.string().refine(date => {
    const dob = new Date(date);
    return dob <= new Date();
  }, 'Date of birth cannot be in the future'),
  sex: z.enum(['m', 'f', 'other']).optional(),
  timeZone: z.string().min(1, 'Time zone is required'),
  units: z.enum(['metric', 'imperial']),
  feedingStyle: z.enum(['breast', 'bottle', 'both']).optional(),
});

export const EventRecordSchema = z
  .object({
    type: z.enum(['feed', 'sleep', 'diaper', 'tummy_time']),
    subtype: z.string().optional(),
    side: z.enum(['left', 'right', 'both']).optional(),
    amount: z.number().min(0, 'Amount cannot be negative').optional(),
    unit: z.enum(['ml', 'oz']).optional(),
    startTime: z.string(),
    endTime: z.string().optional(),
    durationMin: z.number().min(0, 'Duration cannot be negative').optional(),
    notes: z.string().max(500, 'Notes must be 500 characters or less').optional(),
  })
  .refine(
    data => {
      if (data.endTime && data.startTime) {
        return new Date(data.endTime) >= new Date(data.startTime);
      }
      return true;
    },
    {
      message: 'End time must be after start time',
      path: ['endTime'],
    }
  );

export const CryLogSchema = z.object({
  baby_id: z.string().uuid('Invalid baby ID'),
  family_id: z.string().uuid('Invalid family ID'),
  start_time: z.string(),
  end_time: z.string().optional(),
  cry_type: z.string().max(50, 'Cry type must be 50 characters or less').optional(),
  confidence: z.number().min(0).max(1, 'Confidence must be between 0 and 1').optional(),
  resolved_by: z.string().max(100, 'Resolution must be 100 characters or less').optional(),
  note: z.string().max(500, 'Note must be 500 characters or less').optional(),
  context: z.any().optional(),
});

export const MilestoneSchema = z.object({
  baby_id: z.string().uuid('Invalid baby ID'),
  category: z
    .string()
    .min(1, 'Category is required')
    .max(50, 'Category must be 50 characters or less'),
  title: z
    .string()
    .trim()
    .min(1, 'Title is required')
    .max(100, 'Title must be 100 characters or less'),
  description: z.string().max(500, 'Description must be 500 characters or less').optional(),
  achieved_at: z.string(),
  note: z.string().max(500, 'Note must be 500 characters or less').optional(),
  photo_url: z.string().url('Invalid photo URL').optional().nullable(),
});

export const JournalEntrySchema = z.object({
  baby_id: z.string().uuid('Invalid baby ID'),
  entry_date: z.string(),
  title: z.string().trim().max(200, 'Title must be 200 characters or less').optional(),
  content: z
    .string()
    .trim()
    .min(1, 'Content is required')
    .max(5000, 'Content must be 5000 characters or less'),
  mood: z.string().max(50, 'Mood must be 50 characters or less').optional(),
  weather: z.string().max(50, 'Weather must be 50 characters or less').optional(),
  firsts: z.array(z.string()).optional(),
});

export const GrowthRecordSchema = z.object({
  baby_id: z.string().uuid('Invalid baby ID'),
  recorded_at: z.string(),
  weight: z
    .number()
    .min(0, 'Weight cannot be negative')
    .max(50, 'Weight must be less than 50kg')
    .optional(),
  length: z
    .number()
    .min(0, 'Length cannot be negative')
    .max(200, 'Length must be less than 200cm')
    .optional(),
  head_circumference: z
    .number()
    .min(0, 'Head circumference cannot be negative')
    .max(100, 'Head circumference must be less than 100cm')
    .optional(),
  note: z.string().max(500, 'Note must be 500 characters or less').optional(),
  unit_system: z.enum(['metric', 'imperial']).optional(),
});

export const HealthRecordSchema = z.object({
  baby_id: z.string().uuid('Invalid baby ID'),
  record_type: z.enum(['vaccine', 'illness', 'doctor_visit', 'medication']),
  title: z
    .string()
    .trim()
    .min(1, 'Title is required')
    .max(200, 'Title must be 200 characters or less'),
  recorded_at: z.string(),
  temperature: z.number().min(35).max(42, 'Temperature must be between 35-42°C').optional(),
  vaccine_name: z.string().max(100, 'Vaccine name must be 100 characters or less').optional(),
  vaccine_dose: z.string().max(50, 'Vaccine dose must be 50 characters or less').optional(),
  doctor_name: z.string().max(100, 'Doctor name must be 100 characters or less').optional(),
  diagnosis: z.string().max(500, 'Diagnosis must be 500 characters or less').optional(),
  treatment: z.string().max(500, 'Treatment must be 500 characters or less').optional(),
  note: z.string().max(1000, 'Note must be 1000 characters or less').optional(),
});

export function validateBaby(data: unknown) {
  return BabySchema.safeParse(data);
}

export function validateEvent(data: unknown) {
  return EventRecordSchema.safeParse(data);
}

export function validateCryLog(data: unknown) {
  return CryLogSchema.safeParse(data);
}

export function validateMilestone(data: unknown) {
  return MilestoneSchema.safeParse(data);
}

export function validateJournalEntry(data: unknown) {
  return JournalEntrySchema.safeParse(data);
}

export function validateGrowthRecord(data: unknown) {
  return GrowthRecordSchema.safeParse(data);
}

export function validateHealthRecord(data: unknown) {
  return HealthRecordSchema.safeParse(data);
}
