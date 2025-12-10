import { format } from 'date-fns';
import { dataService } from '@/services/dataService';
import type { EventRecord } from '@/types/events';

export async function exportEventsCSV(
  babyId: string,
  babyName: string,
  startDate: Date,
  endDate: Date
) {
  // Get events from IndexedDB
  const events = await dataService.listEventsRange(
    babyId,
    startDate.toISOString(),
    endDate.toISOString()
  );

  // Calculate daily summaries
  const dailySummaries = calculateDailySummaries(events);

  // CSV headers
  const headers = [
    'Date',
    'Time',
    'Type',
    'Subtype',
    'Amount',
    'Unit',
    'Duration (min)',
    'Start Time',
    'End Time',
    'Notes',
  ];

  // Convert events to CSV rows
  const rows = events.map((event: EventRecord) => {
    const duration = event.endTime
      ? Math.round(
          (new Date(event.endTime).getTime() - new Date(event.startTime).getTime()) / 60000
        )
      : event.durationMin || '';

    return [
      format(new Date(event.startTime), 'yyyy-MM-dd'),
      format(new Date(event.startTime), 'HH:mm'),
      event.type,
      event.subtype || '',
      event.amount || '',
      event.unit || '',
      duration,
      format(new Date(event.startTime), 'HH:mm'),
      event.endTime ? format(new Date(event.endTime), 'HH:mm') : '',
      event.notes || '',
    ];
  });

  // Add daily summary section
  const summaryRows: string[][] = [
    [],
    ['DAILY SUMMARIES'],
    [
      'Date',
      'Total Feeds',
      'Total Milk (ml)',
      'Total Sleep (hrs)',
      'Total Diapers',
      'Wet Diapers',
      'Dirty Diapers',
    ],
  ];

  Object.entries(dailySummaries).forEach(([date, summary]) => {
    summaryRows.push([
      date,
      summary.feedCount.toString(),
      summary.totalMl.toString(),
      (summary.sleepMinutes / 60).toFixed(1),
      summary.diaperTotal.toString(),
      summary.diaperWet.toString(),
      summary.diaperDirty.toString(),
    ]);
  });

  // Create CSV content with event details and summaries
  const csv = [['EVENT LOG'], headers, ...rows, ...summaryRows]
    .map(row => row.map(cell => `"${cell}"`).join(','))
    .join('\n');

  // Create and download file
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `nestling-export-${babyName}-${format(startDate, 'yyyy-MM-dd')}-to-${format(endDate, 'yyyy-MM-dd')}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

function calculateDailySummaries(events: EventRecord[]): Record<string, any> {
  const summaries: Record<string, any> = {};

  events.forEach(event => {
    const date = format(new Date(event.startTime), 'yyyy-MM-dd');

    if (!summaries[date]) {
      summaries[date] = {
        feedCount: 0,
        totalMl: 0,
        sleepMinutes: 0,
        diaperTotal: 0,
        diaperWet: 0,
        diaperDirty: 0,
      };
    }

    if (event.type === 'feed') {
      summaries[date].feedCount++;
      if (event.amount && event.unit === 'ml') {
        summaries[date].totalMl += event.amount;
      }
    }

    if (event.type === 'sleep' && event.endTime) {
      const duration =
        (new Date(event.endTime).getTime() - new Date(event.startTime).getTime()) / 60000;
      summaries[date].sleepMinutes += duration;
    }

    if (event.type === 'diaper') {
      summaries[date].diaperTotal++;
      if (event.subtype === 'wet' || event.subtype === 'mixed') {
        summaries[date].diaperWet++;
      }
      if (event.subtype === 'dirty' || event.subtype === 'mixed') {
        summaries[date].diaperDirty++;
      }
    }
  });

  return summaries;
}
