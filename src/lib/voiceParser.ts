import type { EventType } from './types';

export interface VoiceCommand {
  type: EventType | null;
  subtype?: string;
  amount?: number;
  unit?: string;
  note?: string;
}

export function parseVoiceCommand(transcript: string): VoiceCommand {
  const lowerTranscript = transcript.toLowerCase();
  const command: VoiceCommand = { type: null };

  // Feed detection
  if (
    lowerTranscript.includes('feed') ||
    lowerTranscript.includes('bottle') ||
    lowerTranscript.includes('breast')
  ) {
    command.type = 'feed';

    // Detect feed type
    if (lowerTranscript.includes('bottle')) {
      command.subtype = 'bottle';
    } else if (lowerTranscript.includes('breast') || lowerTranscript.includes('nursing')) {
      command.subtype = 'breast';
    } else if (lowerTranscript.includes('solid')) {
      command.subtype = 'solids';
    }

    // Extract amount (look for numbers followed by ml, oz, or ounces)
    const mlMatch = lowerTranscript.match(/(\d+)\s*(ml|milliliter)/);
    const ozMatch = lowerTranscript.match(/(\d+)\s*(oz|ounce)/);

    if (mlMatch) {
      command.amount = parseInt(mlMatch[1]);
      command.unit = 'ml';
    } else if (ozMatch) {
      command.amount = parseInt(ozMatch[1]);
      command.unit = 'oz';
    }
  }

  // Sleep detection
  if (lowerTranscript.includes('sleep') || lowerTranscript.includes('nap')) {
    command.type = 'sleep';
    command.subtype = lowerTranscript.includes('nap') ? 'nap' : 'sleep';
  }

  // Diaper detection
  if (
    lowerTranscript.includes('diaper') ||
    lowerTranscript.includes('poop') ||
    lowerTranscript.includes('pee')
  ) {
    command.type = 'diaper';

    if (lowerTranscript.includes('wet') || lowerTranscript.includes('pee')) {
      command.subtype = 'wet';
    } else if (lowerTranscript.includes('dirty') || lowerTranscript.includes('poop')) {
      command.subtype = 'dirty';
    } else if (
      lowerTranscript.includes('both') ||
      (lowerTranscript.includes('wet') && lowerTranscript.includes('dirty'))
    ) {
      command.subtype = 'both';
    }
  }

  // Tummy time detection
  if (lowerTranscript.includes('tummy time')) {
    command.type = 'tummy_time';
  }

  // Medication detection
  if (lowerTranscript.includes('medicine') || lowerTranscript.includes('medication')) {
    command.type = 'medication';
  }

  // Extract duration for sleep (look for numbers followed by minutes/hours)
  if (command.type === 'sleep') {
    const minutesMatch = lowerTranscript.match(/(\d+)\s*minute/);
    const hoursMatch = lowerTranscript.match(/(\d+)\s*hour/);

    if (hoursMatch) {
      command.amount = parseInt(hoursMatch[1]) * 60;
      command.unit = 'minutes';
    } else if (minutesMatch) {
      command.amount = parseInt(minutesMatch[1]);
      command.unit = 'minutes';
    }
  }

  return command;
}

// Example voice commands that work:
// "Log bottle feed 120 ml"
// "Baby had a wet diaper"
// "Start sleep timer"
// "Log nap 2 hours"
// "Dirty diaper"
// "Breast feeding"
