import { format } from 'date-fns';
import { dataService } from '@/services/dataService';
import { EventRecord } from '@/types/events';

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

  // Create CSV content
  const csv = [headers, ...rows]
    .map((row) => row.map((cell) => `"${cell}"`).join(','))
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
