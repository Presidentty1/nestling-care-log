import { format, differenceInMinutes, differenceInSeconds } from 'date-fns';

export function formatDuration(durationMin: number): string {
  const hours = Math.floor(durationMin / 60);
  const mins = durationMin % 60;

  if (hours > 0) {
    return `${hours}h ${mins}m`;
  }
  return `${mins}m`;
}

export function formatTimerDisplay(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function formatTimeRange(start: string, end: string): string {
  const startTime = format(new Date(start), 'h:mm a');
  const endTime = format(new Date(end), 'h:mm a');
  return `${startTime} - ${endTime}`;
}

export function calculateDuration(start: string, end: string): number {
  return differenceInMinutes(new Date(end), new Date(start));
}

export function getElapsedSeconds(startTime: string): number {
  return differenceInSeconds(new Date(), new Date(startTime));
}

export function isCrossMidnight(start: string, end: string): boolean {
  const startDate = new Date(start);
  const endDate = new Date(end);
  return startDate.getDate() !== endDate.getDate();
}
