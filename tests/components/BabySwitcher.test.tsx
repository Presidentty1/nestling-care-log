import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { BabySwitcher } from '@/components/BabySwitcher';
import type { Baby } from '@/lib/types';

// Mock analytics
vi.mock('@/analytics/analytics', () => ({
  track: vi.fn(),
}));

describe('BabySwitcher', () => {
  const mockBabies: Baby[] = [
    {
      id: '1',
      name: 'Baby One',
      date_of_birth: '2024-01-01',
      family_id: 'family-1',
      timezone: 'UTC',
      primary_feeding_style: 'bottle',
      sex: 'm',
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    },
    {
      id: '2',
      name: 'Baby Two',
      date_of_birth: '2024-03-01',
      family_id: 'family-1',
      timezone: 'UTC',
      primary_feeding_style: 'breast',
      sex: 'f',
      created_at: '2024-03-01T00:00:00Z',
      updated_at: '2024-03-01T00:00:00Z',
    },
  ];

  it('does not render when only one baby', () => {
    const { container } = render(
      <BabySwitcher
        babies={[mockBabies[0]]}
        selectedBabyId="1"
        onSelect={vi.fn()}
        isOpen={true}
        onClose={vi.fn()}
      />
    );
    
    expect(container.firstChild).toBeNull();
  });

  it('renders baby list when multiple babies', () => {
    render(
      <BabySwitcher
        babies={mockBabies}
        selectedBabyId="1"
        onSelect={vi.fn()}
        isOpen={true}
        onClose={vi.fn()}
      />
    );
    
    expect(screen.getByText('Baby One')).toBeInTheDocument();
    expect(screen.getByText('Baby Two')).toBeInTheDocument();
  });

  it('calls onSelect when baby is clicked', () => {
    const onSelect = vi.fn();
    const onClose = vi.fn();
    
    render(
      <BabySwitcher
        babies={mockBabies}
        selectedBabyId="1"
        onSelect={onSelect}
        isOpen={true}
        onClose={onClose}
      />
    );
    
    fireEvent.click(screen.getByText('Baby Two'));
    
    expect(onSelect).toHaveBeenCalledWith('2');
    expect(onClose).toHaveBeenCalled();
  });

  it('shows "Add Baby" button', () => {
    render(
      <BabySwitcher
        babies={mockBabies}
        selectedBabyId="1"
        onSelect={vi.fn()}
        isOpen={true}
        onClose={vi.fn()}
      />
    );
    
    expect(screen.getByText('Add Baby')).toBeInTheDocument();
  });
});


