import { beforeEach, describe, expect, test, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useNavigate } from 'react-router-dom';
import { useOnboarding } from '@/hooks/useOnboarding';
import { familyService } from '@/services/familyService';
import { babyService } from '@/services/babyService';
import { guestModeService } from '@/services/guestModeService';
import { useAuth } from '@/hooks/useAuth';

const mockNavigate = vi.fn();
const mockSetActiveBabyId = vi.fn();
const mockSetGuestMode = vi.fn();

vi.mock('react-router-dom', async importOriginal => {
  const mod = await importOriginal<typeof import('react-router-dom')>();
  return {
    ...mod,
    useNavigate: vi.fn(),
  };
});

vi.mock('@/hooks/useAuth', () => ({
  useAuth: vi.fn(),
}));

vi.mock('@/store/appStore', () => ({
  useAppStore: () => ({
    setActiveBabyId: mockSetActiveBabyId,
    setGuestMode: mockSetGuestMode,
  }),
}));

vi.mock('@/services/guestModeService', () => ({
  guestModeService: {
    isGuestMode: vi.fn(),
    getGuestBaby: vi.fn(),
    setGuestBaby: vi.fn(),
  },
}));

vi.mock('@/services/familyService', () => ({
  familyService: {
    getUserFamilies: vi.fn(),
  },
}));

vi.mock('@/services/babyService', () => ({
  babyService: {
    getUserBabies: vi.fn(),
  },
}));

describe('useOnboarding', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(useNavigate).mockReturnValue(mockNavigate);
    vi.mocked(guestModeService.isGuestMode).mockResolvedValue(false);
  });

  test('navigates to /home when unauthenticated', async () => {
    vi.mocked(useAuth).mockReturnValue({ user: null, loading: false } as ReturnType<
      typeof useAuth
    >);

    renderHook(() => useOnboarding());

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/home');
    });
  });

  test('navigates to /onboarding when user has no families', async () => {
    vi.mocked(useAuth).mockReturnValue({
      user: { id: 'user_1' },
      loading: false,
    } as ReturnType<typeof useAuth>);
    vi.mocked(familyService.getUserFamilies).mockResolvedValue([]);

    renderHook(() => useOnboarding());

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/onboarding');
    });
  });

  test('navigates to /home and sets active baby when user has babies', async () => {
    vi.mocked(useAuth).mockReturnValue({
      user: { id: 'user_1' },
      loading: false,
    } as ReturnType<typeof useAuth>);
    vi.mocked(familyService.getUserFamilies).mockResolvedValue([{ id: 'fam_1' }]);
    vi.mocked(babyService.getUserBabies).mockResolvedValue([{ id: 'baby_1' }, { id: 'baby_2' }]);

    localStorage.setItem('activeBabyId', 'baby_2');

    renderHook(() => useOnboarding());

    await waitFor(() => {
      expect(mockSetActiveBabyId).toHaveBeenCalledWith('baby_2');
      expect(mockNavigate).toHaveBeenCalledWith('/home');
    });
  });
});


