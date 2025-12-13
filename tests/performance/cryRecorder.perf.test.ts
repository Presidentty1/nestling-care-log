/**
 * Performance regression tests for CryRecorder component
 *
 * Tests performance baselines to prevent regression of:
 * - AUDIT-5: Timer frequency performance
 * - AUDIT-8: Component cleanup performance
 *
 * @see CODEBASE_AUDIT_REPORT.md#5-cryrecorder-timer-frequency-web
 * @see CODEBASE_AUDIT_REPORT.md#8-missing-cleanup-in-cryrecorder-web
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { CryRecorder } from '@/components/CryRecorder';
import { usePro } from '@/hooks/usePro';
import { trialService } from '@/services/trialService';

// Mock dependencies
vi.mock('@/hooks/usePro');
vi.mock('@/services/trialService');
vi.mock('@/services/eventsService');
vi.mock('@/services/cryAnalysisService');
vi.mock('sonner');

describe('CryRecorder Performance Regression Tests', () => {
  const mockBabyId = 'test-baby-id';

  beforeEach(() => {
    vi.mocked(usePro).mockReturnValue({ isPro: false });
    vi.mocked(trialService.getFreeCryInsightsUsed).mockResolvedValue(0);
    vi.mocked(trialService.hasFreeCryInsightsLeft).mockResolvedValue(true);

    Object.defineProperty(navigator, 'mediaDevices', {
      value: {
        getUserMedia: vi.fn().mockResolvedValue({
          getTracks: vi.fn().mockReturnValue([{ stop: vi.fn() }]),
        }),
      },
      writable: true,
    });

    global.MediaRecorder = vi.fn().mockImplementation(() => ({
      start: vi.fn(),
      stop: vi.fn(),
      ondataavailable: null,
      onstop: null,
      state: 'inactive',
    }));

    global.URL.createObjectURL = vi.fn();
    global.URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  describe('Timer Performance Baselines', () => {
    it('should maintain timer interval performance during recording', async () => {
      vi.useFakeTimers();
      const setIntervalSpy = vi.spyOn(global, 'setInterval');
      const startTime = performance.now();

      render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      await waitFor(() => {
        expect(setIntervalSpy).toHaveBeenCalled();
      });

      const endTime = performance.now();
      const setupTime = endTime - startTime;

      expect(setupTime).toBeLessThan(100);

      setIntervalSpy.mockRestore();
    });
  });

  describe('Component Cleanup Performance', () => {
    it('should clean up timers quickly on unmount', async () => {
      vi.useFakeTimers();
      const clearIntervalSpy = vi.spyOn(global, 'clearInterval');

      const { unmount } = render(
        <CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />
      );

      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      await waitFor(() => {
        expect(screen.getByText(/recording/i)).toBeInTheDocument();
      });

      const startTime = performance.now();
      unmount();
      const endTime = performance.now();
      const cleanupTime = endTime - startTime;

      expect(cleanupTime).toBeLessThan(10);
      expect(clearIntervalSpy).toHaveBeenCalled();

      clearIntervalSpy.mockRestore();
    });

    it('should handle rapid mount/unmount cycles efficiently', () => {
      const performanceMarks: number[] = [];

      for (let i = 0; i < 10; i++) {
        const startTime = performance.now();

        const { unmount } = render(
          <CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />
        );
        unmount();

        const endTime = performance.now();
        performanceMarks.push(endTime - startTime);
      }

      const averageTime =
        performanceMarks.reduce((a, b) => a + b, 0) / performanceMarks.length;

      expect(averageTime).toBeLessThan(5);

      const firstTime = performanceMarks[0];
      const lastTime = performanceMarks[performanceMarks.length - 1];
      expect(lastTime).toBeLessThan(firstTime * 2);
    });
  });

  describe('Performance Baselines', () => {
    it('should establish component initialization baseline', () => {
      const startTime = performance.now();

      render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      const endTime = performance.now();
      const initTime = endTime - startTime;

      expect(initTime).toBeLessThan(50);
    });

    it('should establish cleanup baseline', () => {
      const { unmount } = render(
        <CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />
      );

      const startTime = performance.now();
      unmount();
      const endTime = performance.now();
      const cleanupTime = endTime - startTime;

      expect(cleanupTime).toBeLessThan(5);
    });
  });
});
