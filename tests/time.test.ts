import { describe, it, expect } from 'vitest';
import { ozToMl, mlToOz } from '@/utils/units';
import { formatDuration } from '@/services/time';

describe('Unit Conversions', () => {
  it('should convert oz to ml correctly', () => {
    expect(ozToMl(1)).toBeCloseTo(29.5735, 2);
    expect(ozToMl(4)).toBeCloseTo(118.294, 2);
    expect(ozToMl(8)).toBeCloseTo(236.588, 2);
  });

  it('should convert ml to oz correctly', () => {
    expect(mlToOz(29.5735)).toBeCloseTo(1, 2);
    expect(mlToOz(118.294)).toBeCloseTo(4, 2);
    expect(mlToOz(236.588)).toBeCloseTo(8, 2);
  });

  it('should handle zero and negative values', () => {
    expect(ozToMl(0)).toBe(0);
    expect(mlToOz(0)).toBe(0);
  });
});

describe('Time Utilities', () => {
  it('should format duration correctly', () => {
    expect(formatDuration(0)).toBe('0m');
    expect(formatDuration(30)).toBe('30m');
    expect(formatDuration(60)).toBe('1h 0m');
    expect(formatDuration(90)).toBe('1h 30m');
    expect(formatDuration(125)).toBe('2h 5m');
  });

  it('should handle duration across midnight', () => {
    const start = new Date('2024-01-01T23:30:00Z');
    const end = new Date('2024-01-02T00:30:00Z');
    const durationMin = (end.getTime() - start.getTime()) / 60000;
    expect(durationMin).toBe(60);
  });
});
