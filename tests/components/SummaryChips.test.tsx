import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { SummaryChips } from '@/components/today/SummaryChips';
import { DailySummary } from '@/types/summary';

describe('SummaryChips', () => {
  const defaultSummary: DailySummary = {
    feedCount: 0,
    totalMl: 0,
    sleepMinutes: 0,
    sleepCount: 0,
    diaperWet: 0,
    diaperDirty: 0,
    diaperTotal: 0,
  };

  it('renders all three summary chips', () => {
    render(<SummaryChips summary={defaultSummary} />);
    
    expect(screen.getByText('Feeds')).toBeInTheDocument();
    expect(screen.getByText('Sleep')).toBeInTheDocument();
    expect(screen.getByText('Diapers')).toBeInTheDocument();
  });

  it('displays feed count correctly', () => {
    const summary: DailySummary = {
      ...defaultSummary,
      feedCount: 5,
      totalMl: 600,
    };
    
    render(<SummaryChips summary={summary} />);
    
    expect(screen.getByText('5')).toBeInTheDocument();
    expect(screen.getByText('600 ml')).toBeInTheDocument();
  });

  it('displays sleep time correctly', () => {
    const summary: DailySummary = {
      ...defaultSummary,
      sleepMinutes: 90,
      sleepCount: 2,
    };
    
    render(<SummaryChips summary={summary} />);
    
    expect(screen.getByText('1h 30m')).toBeInTheDocument();
    expect(screen.getByText('2 naps')).toBeInTheDocument();
  });

  it('displays zero sleep as em dash', () => {
    render(<SummaryChips summary={defaultSummary} />);
    
    expect(screen.getByText('—')).toBeInTheDocument();
  });

  it('displays diaper counts correctly', () => {
    const summary: DailySummary = {
      ...defaultSummary,
      diaperWet: 3,
      diaperDirty: 2,
      diaperTotal: 5,
    };
    
    render(<SummaryChips summary={summary} />);
    
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('handles edge case: zero values', () => {
    render(<SummaryChips summary={defaultSummary} />);
    
    expect(screen.getByText('0')).toBeInTheDocument(); // Feed count
    expect(screen.getByText('—')).toBeInTheDocument(); // Sleep
    expect(screen.getByText('0')).toBeInTheDocument(); // Diaper count
  });
});


