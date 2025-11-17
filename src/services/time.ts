import { differenceInMonths, differenceInDays, format } from 'date-fns';

export function formatDuration(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  
  if (hours > 0) {
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
  }
  return `${mins}m`;
}

export function mlToOz(ml: number): number {
  return Math.round((ml / 29.5735) * 10) / 10;
}

export function ozToMl(oz: number): number {
  return Math.round(oz * 29.5735);
}

export function getAgeBand(dobISO: string): string {
  const months = differenceInMonths(new Date(), new Date(dobISO));
  
  if (months < 3) return '0-2m';
  if (months < 5) return '3-4m';
  if (months < 8) return '5-7m';
  if (months < 11) return '8-10m';
  return '11-15m';
}

export function getAgeDisplay(dobISO: string): string {
  const months = differenceInMonths(new Date(), new Date(dobISO));
  const days = differenceInDays(new Date(), new Date(dobISO));
  
  if (days < 60) {
    return `${days} day${days === 1 ? '' : 's'}`;
  }
  
  if (months < 24) {
    return `${months} month${months === 1 ? '' : 's'}`;
  }
  
  const years = Math.floor(months / 12);
  const remainingMonths = months % 12;
  
  if (remainingMonths === 0) {
    return `${years} year${years === 1 ? '' : 's'}`;
  }
  
  return `${years}y ${remainingMonths}m`;
}

export function getDayISO(date: Date): string {
  return format(date, 'yyyy-MM-dd');
}

export function parseLocalDate(input: string): Date | null {
  const match = input.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (match) {
    const [, month, day, year] = match;
    const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
    if (!isNaN(date.getTime())) {
      return date;
    }
  }
  return null;
}

export function detectTimeZone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}
