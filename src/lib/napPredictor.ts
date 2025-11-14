import { Baby, BabyEvent } from './types';
import { differenceInWeeks, addMinutes } from 'date-fns';

interface WakeWindow {
  min: number;
  max: number;
  unit: 'minutes';
}

interface NapPrediction {
  napWindowStart: Date;
  napWindowEnd: Date;
  confidence: 'high' | 'medium' | 'low';
  explanation: string;
  suggestedDuration: number;
  lastWakeTime: Date | null;
}

export function calculateWakeWindow(ageInWeeks: number): WakeWindow {
  if (ageInWeeks <= 6) {
    return { min: 45, max: 60, unit: 'minutes' };
  } else if (ageInWeeks <= 12) {
    return { min: 60, max: 90, unit: 'minutes' };
  } else if (ageInWeeks <= 16) {
    return { min: 75, max: 120, unit: 'minutes' };
  } else if (ageInWeeks <= 26) {
    return { min: 120, max: 150, unit: 'minutes' };
  } else if (ageInWeeks <= 39) {
    return { min: 150, max: 210, unit: 'minutes' };
  } else if (ageInWeeks <= 52) {
    return { min: 180, max: 240, unit: 'minutes' };
  } else if (ageInWeeks <= 78) {
    return { min: 240, max: 300, unit: 'minutes' };
  } else {
    return { min: 300, max: 360, unit: 'minutes' };
  }
}

export function getLastWakeTime(events: BabyEvent[]): Date | null {
  const sleepEvents = events
    .filter((e) => e.type === 'sleep' && e.end_time)
    .sort((a, b) => new Date(b.end_time!).getTime() - new Date(a.end_time!).getTime());

  if (sleepEvents.length > 0 && sleepEvents[0].end_time) {
    return new Date(sleepEvents[0].end_time);
  }

  return null;
}

export function predictNextNap(baby: Baby, events: BabyEvent[]): NapPrediction {
  const now = new Date();
  const birthDate = new Date(baby.date_of_birth);
  const ageInWeeks = differenceInWeeks(now, birthDate);

  const wakeWindow = calculateWakeWindow(ageInWeeks);
  const lastWakeTime = getLastWakeTime(events);

  // Calculate confidence based on available data
  const recentSleepEvents = events.filter(
    (e) => e.type === 'sleep' && e.end_time && 
    new Date(e.end_time).getTime() > Date.now() - 7 * 24 * 60 * 60 * 1000
  );
  
  let confidence: 'high' | 'medium' | 'low';
  if (recentSleepEvents.length >= 7) {
    confidence = 'high';
  } else if (recentSleepEvents.length >= 3) {
    confidence = 'medium';
  } else {
    confidence = 'low';
  }

  // If no wake time, use current time - average wake window
  const effectiveWakeTime = lastWakeTime || addMinutes(now, -(wakeWindow.min + wakeWindow.max) / 2);

  const napWindowStart = addMinutes(effectiveWakeTime, wakeWindow.min);
  const napWindowEnd = addMinutes(effectiveWakeTime, wakeWindow.max);

  // Generate explanation
  let explanation: string;
  if (confidence === 'high') {
    explanation = `Based on ${baby.name}'s age and recent sleep patterns, the ideal nap window is ${wakeWindow.min}-${wakeWindow.max} minutes after waking.`;
  } else if (confidence === 'medium') {
    explanation = `Based on ${baby.name}'s age, typical wake windows are ${wakeWindow.min}-${wakeWindow.max} minutes. Log more sleeps to improve accuracy.`;
  } else {
    explanation = `For babies around ${Math.floor(ageInWeeks / 4)} months old, wake windows are typically ${wakeWindow.min}-${wakeWindow.max} minutes. Start logging sleeps for personalized predictions.`;
  }

  // Suggested nap duration based on age
  let suggestedDuration: number;
  if (ageInWeeks <= 12) {
    suggestedDuration = 30;
  } else if (ageInWeeks <= 26) {
    suggestedDuration = 60;
  } else if (ageInWeeks <= 52) {
    suggestedDuration = 90;
  } else {
    suggestedDuration = 120;
  }

  return {
    napWindowStart,
    napWindowEnd,
    confidence,
    explanation,
    suggestedDuration,
    lastWakeTime,
  };
}
