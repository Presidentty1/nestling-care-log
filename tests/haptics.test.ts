import { describe, it, expect, vi, beforeEach } from 'vitest';
import { hapticFeedback } from '@/lib/haptics';

// Mock Capacitor Haptics
vi.mock('@capacitor/haptics', () => ({
  Haptics: {
    impact: vi.fn().mockResolvedValue(undefined),
    selectionStart: vi.fn().mockResolvedValue(undefined),
    selectionChanged: vi.fn().mockResolvedValue(undefined),
    selectionEnd: vi.fn().mockResolvedValue(undefined),
  },
  ImpactStyle: {
    Light: 'LIGHT',
    Medium: 'MEDIUM',
    Heavy: 'HEAVY',
  },
}));

describe('hapticFeedback', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('light', () => {
    it('triggers light haptic feedback', async () => {
      const { Haptics, ImpactStyle } = await import('@capacitor/haptics');

      await hapticFeedback.light();

      expect(Haptics.impact).toHaveBeenCalledWith({ style: ImpactStyle.Light });
    });

    it('handles errors gracefully', async () => {
      const { Haptics } = await import('@capacitor/haptics');
      vi.mocked(Haptics.impact).mockRejectedValueOnce(new Error('Not available'));

      // Should not throw
      await expect(hapticFeedback.light()).resolves.toBeUndefined();
    });
  });

  describe('medium', () => {
    it('triggers medium haptic feedback', async () => {
      const { Haptics, ImpactStyle } = await import('@capacitor/haptics');

      await hapticFeedback.medium();

      expect(Haptics.impact).toHaveBeenCalledWith({ style: ImpactStyle.Medium });
    });
  });

  describe('heavy', () => {
    it('triggers heavy haptic feedback', async () => {
      const { Haptics, ImpactStyle } = await import('@capacitor/haptics');

      await hapticFeedback.heavy();

      expect(Haptics.impact).toHaveBeenCalledWith({ style: ImpactStyle.Heavy });
    });
  });

  describe('selection', () => {
    it('triggers selection haptic sequence', async () => {
      const { Haptics } = await import('@capacitor/haptics');

      await hapticFeedback.selection();

      expect(Haptics.selectionStart).toHaveBeenCalled();
      expect(Haptics.selectionChanged).toHaveBeenCalled();
      expect(Haptics.selectionEnd).toHaveBeenCalled();
    });

    it('handles errors in selection sequence gracefully', async () => {
      const { Haptics } = await import('@capacitor/haptics');
      vi.mocked(Haptics.selectionStart).mockRejectedValueOnce(new Error('Not available'));

      // Should not throw
      await expect(hapticFeedback.selection()).resolves.toBeUndefined();
    });
  });
});
