import { DbBaby, DbEvent, DbProfile, DbFamily, DbFamilyMember } from './db';
import { Baby, EventRecord, Profile, Family, FamilyMember } from './domain';

export const toDomainBaby = (db: DbBaby): Baby => ({
  id: db.id,
  familyId: db.family_id,
  name: db.name,
  dateOfBirth: db.date_of_birth,
  dueDate: db.due_date || undefined,
  sex: db.sex as Baby['sex'],
  timeZone: db.timezone,
  primaryFeedingStyle: db.primary_feeding_style as Baby['primaryFeedingStyle'],
  createdAt: db.created_at,
  updatedAt: db.updated_at,
});

export const toDbBaby = (domain: Partial<Baby>): Partial<DbBaby> => {
  const db: any = {};
  if (domain.id) db.id = domain.id;
  if (domain.familyId) db.family_id = domain.familyId;
  if (domain.name) db.name = domain.name;
  if (domain.dateOfBirth) db.date_of_birth = domain.dateOfBirth;
  if (domain.dueDate) db.due_date = domain.dueDate;
  if (domain.sex) db.sex = domain.sex;
  if (domain.timeZone) db.timezone = domain.timeZone;
  if (domain.primaryFeedingStyle) db.primary_feeding_style = domain.primaryFeedingStyle;
  return db;
};

export const toDomainEvent = (db: DbEvent): EventRecord => ({
  id: db.id,
  babyId: db.baby_id,
  familyId: db.family_id,
  type: db.type,
  subtype: db.subtype || undefined,
  startTime: db.start_time,
  endTime: db.end_time || undefined,
  durationMin: db.duration_min || undefined,
  durationSec: db.duration_sec || undefined,
  amount: db.amount || undefined,
  unit: db.unit || undefined,
  note: db.note || undefined,
  createdBy: db.created_by || undefined,
  createdAt: db.created_at,
  updatedAt: db.updated_at,
});

export const toDbEvent = (domain: Partial<EventRecord>): Partial<DbEvent> => {
  const db: any = {};
  if (domain.id) db.id = domain.id;
  if (domain.babyId) db.baby_id = domain.babyId;
  if (domain.familyId) db.family_id = domain.familyId;
  if (domain.type) db.type = domain.type;
  if (domain.subtype) db.subtype = domain.subtype;
  if (domain.startTime) db.start_time = domain.startTime;
  if (domain.endTime) db.end_time = domain.endTime;
  if (domain.durationMin) db.duration_min = domain.durationMin;
  if (domain.durationSec) db.duration_sec = domain.durationSec;
  if (domain.amount) db.amount = domain.amount;
  if (domain.unit) db.unit = domain.unit;
  if (domain.note) db.note = domain.note;
  return db;
};


