import { z } from 'zod';

export const BabySchema = z.object({
  name: z.string()
    .trim()
    .min(1, 'Name is required')
    .max(40, 'Name must be 40 characters or less'),
  dobISO: z.string()
    .refine((date) => {
      const dob = new Date(date);
      return dob <= new Date();
    }, 'Date of birth cannot be in the future'),
  sex: z.enum(['m', 'f', 'other']).optional(),
  timeZone: z.string().min(1, 'Time zone is required'),
  units: z.enum(['metric', 'imperial']),
  feedingStyle: z.enum(['breast', 'bottle', 'both']).optional(),
});

export const EventRecordSchema = z.object({
  type: z.enum(['feed', 'sleep', 'diaper', 'tummy_time']),
  subtype: z.string().optional(),
  side: z.enum(['left', 'right', 'both']).optional(),
  amount: z.number().min(0, 'Amount cannot be negative').optional(),
  unit: z.enum(['ml', 'oz']).optional(),
  startTime: z.string(),
  endTime: z.string().optional(),
  durationMin: z.number().min(0, 'Duration cannot be negative').optional(),
  notes: z.string().max(500, 'Notes must be 500 characters or less').optional(),
}).refine((data) => {
  if (data.endTime && data.startTime) {
    return new Date(data.endTime) >= new Date(data.startTime);
  }
  return true;
}, {
  message: 'End time must be after start time',
  path: ['endTime'],
});

export function validateBaby(data: unknown) {
  return BabySchema.safeParse(data);
}

export function validateEvent(data: unknown) {
  return EventRecordSchema.safeParse(data);
}
