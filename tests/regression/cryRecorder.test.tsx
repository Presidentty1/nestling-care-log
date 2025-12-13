/**
 * Regression tests for CryRecorder component
 *
 * AUDIT-5: Timer frequency should be >= 250ms (not 100ms)
 * AUDIT-8: Cleanup on unmount (timer cleared, MediaRecorder stopped)
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

describe('CryRecorder Regression Tests', () => {
  const mockBabyId = 'test-baby-id';

  beforeEach(() => {
    // Mock hooks and services
    vi.mocked(usePro).mockReturnValue({ isPro: false });
    vi.mocked(trialService.getFreeCryInsightsUsed).mockResolvedValue(0);
    vi.mocked(trialService.hasFreeCryInsightsLeft).mockResolvedValue(true);

    // Mock navigator.mediaDevices
    Object.defineProperty(navigator, 'mediaDevices', {
      value: {
        getUserMedia: vi.fn().mockResolvedValue({
          getTracks: vi.fn().mockReturnValue([{ stop: vi.fn() }]),
        }),
      },
      writable: true,
    });

    // Mock MediaRecorder
    global.MediaRecorder = vi.fn().mockImplementation(() => ({
      start: vi.fn(),
      stop: vi.fn(),
      ondataavailable: null,
      onstop: null,
      state: 'inactive',
    }));

    // Mock URL.createObjectURL and revokeObjectURL
    global.URL.createObjectURL = vi.fn();
    global.URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  describe('AUDIT-5: Timer Frequency Performance', () => {
    it('should use timer interval of at least 250ms (not 100ms)', async () => {
      vi.useFakeTimers();
      const setIntervalSpy = vi.spyOn(global, 'setInterval');

      render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      // Click record button
      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      // Wait for recording to start
      await waitFor(() => {
        expect(setIntervalSpy).toHaveBeenCalled();
      });

      // Check that setInterval was called with 250ms interval (not 100ms)
      const [callback, interval] = setIntervalSpy.mock.calls[0];
      expect(interval).toBe(250);
      expect(interval).toBeGreaterThanOrEqual(250); // Ensure it's not 100ms

      setIntervalSpy.mockRestore();
    });

    it('should not use excessive timer frequency (< 100ms)', async () => {
      vi.useFakeTimers();
      const setIntervalSpy = vi.spyOn(global, 'setInterval');

      render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      // Click record button
      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      // Wait for recording to start
      await waitFor(() => {
        expect(setIntervalSpy).toHaveBeenCalled();
      });

      // Ensure interval is not too frequent (should be >= 250ms)
      const [callback, interval] = setIntervalSpy.mock.calls[0];
      expect(interval).toBeGreaterThanOrEqual(250);

      setIntervalSpy.mockRestore();
    });
  });

  describe('AUDIT-8: Component Cleanup on Unmount', () => {
    it('should clear timer when component unmounts during recording', async () => {
      vi.useFakeTimers();
      const clearIntervalSpy = vi.spyOn(global, 'clearInterval');

      const { unmount } = render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      // Start recording
      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      // Wait for recording to start
      await waitFor(() => {
        expect(screen.getByText(/recording/i)).toBeInTheDocument();
      });

      // Unmount component while recording
      unmount();

      // Should have cleared the timer
      expect(clearIntervalSpy).toHaveBeenCalled();

      clearIntervalSpy.mockRestore();
    });

    it('should stop MediaRecorder when component unmounts during recording', async () => {
      const mockMediaRecorder = {
        start: vi.fn(),
        stop: vi.fn(),
        ondataavailable: null,
        onstop: null,
        state: 'recording',
      };

      global.MediaRecorder = vi.fn().mockImplementation(() => mockMediaRecorder);

      const { unmount } = render(<CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />);

      // Start recording
      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      // Wait for recording to start
      await waitFor(() => {
        expect(mockMediaRecorder.start).toHaveBeenCalled();
      });

      // Unmount component while recording
      unmount();

      // Should have stopped the MediaRecorder
      expect(mockMediaRecorder.stop).toHaveBeenCalled();
    });

    it('should prevent memory leaks with isMountedRef pattern', async () => {
      const mockOnAnalysisComplete = vi.fn();

      const { unmount } = render(
        <CryRecorder babyId={mockBabyId} onAnalysisComplete={mockOnAnalysisComplete} />
      );

      // Start recording
      const recordButton = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton);

      // Unmount immediately (before analysis completes)
      unmount();

      // Wait a bit to ensure async operations would have completed
      await new Promise(resolve => setTimeout(resolve, 100));

      // onAnalysisComplete should not be called (prevented by isMountedRef)
      expect(mockOnAnalysisComplete).not.toHaveBeenCalled();
    });
  });

  describe('Timer and Cleanup Integration', () => {
    it('should handle rapid mount/unmount cycles without issues', async () => {
      vi.useFakeTimers();
      const clearIntervalSpy = vi.spyOn(global, 'clearInterval');

      // Mount and start recording
      const { unmount: unmount1 } = render(
        <CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />
      );
      const recordButton1 = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton1);

      // Immediately unmount
      unmount1();

      // Mount again and start recording
      const { unmount: unmount2 } = render(
        <CryRecorder babyId={mockBabyId} onAnalysisComplete={vi.fn()} />
      );
      const recordButton2 = screen.getByRole('button', { name: /record/i });
      fireEvent.click(recordButton2);

      // Unmount again
      unmount2();

      // Should have cleared timers for both instances
      expect(clearIntervalSpy).toHaveBeenCalledTimes(2);

      clearIntervalSpy.mockRestore();
    });
  });
});
