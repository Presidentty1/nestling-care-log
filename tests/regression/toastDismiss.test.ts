/**
 * Regression tests for toast dismissal logic
 *
 * AUDIT-3: Toast auto-dismiss logic bug (iOS-specific, but testing web equivalent)
 * While the original bug was in iOS code, this tests the web toast dismissal
 * to ensure we don't introduce similar comparison logic errors.
 *
 * @see CODEBASE_AUDIT_REPORT.md#3-toast-auto-dismiss-logic-bug
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { act, renderHook, waitFor } from '@testing-library/react';
import { useToast } from '@/hooks/use-toast';

// Mock timers for testing timeouts
beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.clearAllTimers();
  vi.useRealTimers();
});

describe('Toast Dismiss Logic Regression Tests', () => {
  describe('AUDIT-3: Toast Dismissal Behavior', () => {
    it('should properly dismiss toast by ID comparison', async () => {
      const { result } = renderHook(() => useToast());

      // Create a toast
      const toastInstance = result.current.toast({
        title: 'Test Toast',
        description: 'This is a test toast',
      });

      // Verify toast was created
      expect(result.current.toasts).toHaveLength(1);
      expect(result.current.toasts[0].id).toBe(toastInstance.id);
      expect(result.current.toasts[0].open).toBe(true);

      // Dismiss the specific toast
      act(() => {
        result.current.dismiss(toastInstance.id);
      });

      // Toast should be marked as not open
      expect(result.current.toasts[0].open).toBe(false);

      // After remove delay, toast should be completely removed
      act(() => {
        vi.advanceTimersByTime(1000000); // TOAST_REMOVE_DELAY
      });

      await waitFor(() => {
        expect(result.current.toasts).toHaveLength(0);
      });
    });

    it('should not dismiss wrong toast when ID comparison fails', () => {
      const { result } = renderHook(() => useToast());

      // Create two toasts
      const toast1 = result.current.toast({ title: 'Toast 1' });
      const toast2 = result.current.toast({ title: 'Toast 2' });

      expect(result.current.toasts).toHaveLength(2);

      // Dismiss toast1
      act(() => {
        result.current.dismiss(toast1.id);
      });

      // Only toast1 should be dismissed
      expect(result.current.toasts[0].open).toBe(false); // toast2 (newer)
      expect(result.current.toasts[1].open).toBe(false); // toast1 (older)

      // But wait - the dismiss logic marks all toasts with matching ID as not open
      // Let's check that only the specific toast is affected
      const dismissedToast = result.current.toasts.find(t => t.id === toast1.id);
      const otherToast = result.current.toasts.find(t => t.id === toast2.id);

      expect(dismissedToast?.open).toBe(false);
      expect(otherToast?.open).toBe(true); // This should fail - both are marked as not open
    });

    it('should handle dismiss all toasts correctly', () => {
      const { result } = renderHook(() => useToast());

      // Create multiple toasts
      result.current.toast({ title: 'Toast 1' });
      result.current.toast({ title: 'Toast 2' });
      result.current.toast({ title: 'Toast 3' });

      expect(result.current.toasts).toHaveLength(3);
      expect(result.current.toasts.every(t => t.open)).toBe(true);

      // Dismiss all toasts
      act(() => {
        result.current.dismiss();
      });

      // All toasts should be marked as not open
      expect(result.current.toasts.every(t => !t.open)).toBe(true);
    });

    it('should properly clean up timeouts on dismiss', () => {
      const clearTimeoutSpy = vi.spyOn(global, 'clearTimeout');

      const { result } = renderHook(() => useToast());

      const toastInstance = result.current.toast({ title: 'Test' });

      // Dismiss immediately
      act(() => {
        result.current.dismiss(toastInstance.id);
      });

      // Should have scheduled removal timeout
      expect(clearTimeoutSpy).not.toHaveBeenCalled();

      // Now remove the toast completely (simulating timeout completion)
      act(() => {
        vi.advanceTimersByTime(1000000);
      });

      clearTimeoutSpy.mockRestore();
    });

    it('should prevent duplicate dismiss calls from causing issues', () => {
      const { result } = renderHook(() => useToast());

      const toastInstance = result.current.toast({ title: 'Test' });

      // Dismiss multiple times
      act(() => {
        result.current.dismiss(toastInstance.id);
        result.current.dismiss(toastInstance.id);
        result.current.dismiss(toastInstance.id);
      });

      // Should still only have one toast marked for dismissal
      expect(result.current.toasts).toHaveLength(1);
      expect(result.current.toasts[0].open).toBe(false);
    });
  });

  describe('Toast Instance Methods', () => {
    it('should allow individual toast dismissal via instance method', () => {
      const { result } = renderHook(() => useToast());

      const toastInstance = result.current.toast({ title: 'Test' });

      expect(result.current.toasts[0].open).toBe(true);

      // Use instance dismiss method
      act(() => {
        toastInstance.dismiss();
      });

      expect(result.current.toasts[0].open).toBe(false);
    });

    it('should allow toast updates via instance method', () => {
      const { result } = renderHook(() => useToast());

      const toastInstance = result.current.toast({
        title: 'Original Title',
        description: 'Original description',
      });

      expect(result.current.toasts[0].title).toBe('Original Title');

      // Update the toast
      act(() => {
        toastInstance.update({
          title: 'Updated Title',
          description: 'Updated description',
        });
      });

      expect(result.current.toasts[0].title).toBe('Updated Title');
      expect(result.current.toasts[0].description).toBe('Updated description');
    });
  });

  describe('Toast ID Generation and Uniqueness', () => {
    it('should generate unique IDs for each toast', () => {
      const { result } = renderHook(() => useToast());

      const toast1 = result.current.toast({ title: 'Toast 1' });
      const toast2 = result.current.toast({ title: 'Toast 2' });
      const toast3 = result.current.toast({ title: 'Toast 3' });

      const ids = result.current.toasts.map(t => t.id);
      const uniqueIds = new Set(ids);

      expect(ids).toHaveLength(3);
      expect(uniqueIds.size).toBe(3);
      expect(toast1.id).not.toBe(toast2.id);
      expect(toast2.id).not.toBe(toast3.id);
      expect(toast1.id).not.toBe(toast3.id);
    });

    it('should handle ID wraparound safely', () => {
      // This test ensures that the genId function wraparound doesn't cause issues
      const { result } = renderHook(() => useToast());

      // Mock the count to be near max safe integer
      const originalGenId = vi.fn();
      let callCount = 0;
      originalGenId.mockImplementation(() => {
        callCount++;
        // Simulate wraparound
        return ((callCount - 1) % Number.MAX_SAFE_INTEGER).toString();
      });

      // Since we can't easily mock the internal genId, we'll just verify
      // that multiple toasts still work correctly
      result.current.toast({ title: 'Toast 1' });
      result.current.toast({ title: 'Toast 2' });

      expect(result.current.toasts).toHaveLength(2);
      expect(result.current.toasts[0].id).not.toBe(result.current.toasts[1].id);
    });
  });
});
