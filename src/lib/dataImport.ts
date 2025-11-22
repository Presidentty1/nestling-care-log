import { dataService } from '@/services/dataService';
import type { EventRecord } from '@/types/events';

interface ImportData {
  exported_at: string;
  app_version?: string;
  babies: any[];
  events: EventRecord[];
  nap_predictions?: any[];
  metadata?: any;
}

interface ImportResult {
  added: number;
  skipped: number;
  errors: string[];
}

export async function validateImportData(data: any): Promise<{ valid: boolean; error?: string }> {
  if (!data || typeof data !== 'object') {
    return { valid: false, error: 'Invalid data format' };
  }

  if (!Array.isArray(data.events)) {
    return { valid: false, error: 'Missing or invalid events array' };
  }

  if (!data.exported_at) {
    return { valid: false, error: 'Missing export timestamp' };
  }

  return { valid: true };
}

export async function importEventsToDataService(
  importData: ImportData,
  babyId: string,
  familyId: string
): Promise<ImportResult> {
  const result: ImportResult = {
    added: 0,
    skipped: 0,
    errors: [],
  };

  // Get all existing events to check for duplicates
  const existingEvents = await dataService.listEventsRange(
    babyId,
    new Date(0).toISOString(),
    new Date().toISOString()
  );
  const existingIds = new Set(existingEvents.map(e => e.id));

  for (const event of importData.events) {
    try {
      // Skip if already exists
      if (existingIds.has(event.id)) {
        result.skipped++;
        continue;
      }

      // Create event record with proper structure
      const eventRecord: Omit<EventRecord, 'id' | 'createdAt' | 'updatedAt' | 'source'> = {
        familyId,
        babyId,
        type: event.type,
        subtype: event.subtype,
        startTime: event.startTime,
        endTime: event.endTime,
        amount: event.amount,
        unit: event.unit,
        notes: event.notes,
        durationMin: event.durationMin,
        side: event.side,
        diaperColor: event.diaperColor,
        diaperTexture: event.diaperTexture,
      };

      await dataService.addEvent(eventRecord);
      result.added++;
    } catch (error) {
      result.errors.push(`Failed to import event ${event.id}: ${error}`);
    }
  }

  return result;
}

export async function parseImportFile(file: File): Promise<ImportData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target?.result as string);
        resolve(data);
      } catch (error) {
        reject(new Error('Failed to parse JSON file'));
      }
    };
    
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
}
