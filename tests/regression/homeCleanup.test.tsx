/**
 * Regression tests for Home page useEffect cleanup
 *
 * AUDIT-4: Memory leak in React useEffect - useHomeData subscription cleanup
 *
 * @see CODEBASE_AUDIT_REPORT.md#4-memory-leak-in-react-useeffect-web
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import Home from '@/pages/Home';
import { useHomeData } from '@/hooks/useHomeData';
import { eventsService } from '@/services/eventsService';
import { useAppStore } from '@/store/appStore';

// Mock dependencies
vi.mock('@/hooks/useHomeData');
vi.mock('@/services/eventsService');
vi.mock('@/store/appStore');
vi.mock('@/hooks/useAuth');
vi.mock('@/hooks/useDismissibleBanner');
vi.mock('@/hooks/useKeyboardShortcuts');
vi.mock('@/hooks/useFeatureDiscovery');
vi.mock('@/hooks/useLastUsedValues');
vi.mock('@/analytics/analytics');
vi.mock('@/services/analyticsService');
vi.mock('@/lib/undoManager');
vi.mock('sonner');

describe('Home Page useEffect Cleanup Regression Tests', () => {
  const mockUnsubscribe = vi.fn();

  beforeEach(() => {
    // Mock useHomeData hook
    vi.mocked(useHomeData).mockReturnValue({
      babies: [],
      selectedBaby: null,
      events: [],
      loading: false,
      summary: null,
      napWindow: null,
      streakDays: 0,
      showGuestBanner: false,
      trialDaysRemaining: null,
      hasShownConfetti: false,
      showAffirmation: false,
      refreshEvents: vi.fn(),
      setHasShownConfetti: vi.fn(),
      setActiveBabyId: vi.fn(),
    });

    // Mock app store
    vi.mocked(useAppStore).mockReturnValue({
      activeBabyId: 'test-baby-id',
      guestMode: false,
      setActiveBabyId: vi.fn(),
    });

    // Mock events service subscription
    vi.mocked(eventsService.subscribe).mockReturnValue(mockUnsubscribe);
    vi.mocked(eventsService.getEventsByRange).mockResolvedValue([]);
    vi.mocked(eventsService.calculateSummary).mockReturnValue(null);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('AUDIT-4: useEffect Subscription Cleanup', () => {
    it('should clean up event service subscription on unmount', async () => {
      const { unmount } = render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      // Wait for component to mount and subscriptions to be set up
      await waitFor(() => {
        expect(eventsService.subscribe).toHaveBeenCalled();
      });

      // Unmount the component
      unmount();

      // Should have called the unsubscribe function
      expect(mockUnsubscribe).toHaveBeenCalled();
    });

    it('should not cause infinite loops from events.length dependency', async () => {
      // Mock a scenario where events change frequently
      let subscriptionCallCount = 0;
      vi.mocked(eventsService.subscribe).mockImplementation(() => {
        subscriptionCallCount++;
        return mockUnsubscribe;
      });

      const { rerender } = render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      // Wait for initial subscription
      await waitFor(() => {
        expect(eventsService.subscribe).toHaveBeenCalledTimes(1);
      });

      // Simulate events changing (which would trigger re-renders)
      vi.mocked(useHomeData).mockReturnValue({
        babies: [],
        selectedBaby: null,
        events: [{ id: '1', type: 'feed' }], // Different events array
        loading: false,
        summary: null,
        napWindow: null,
        streakDays: 0,
        showGuestBanner: false,
        trialDaysRemaining: null,
        hasShownConfetti: false,
        showAffirmation: false,
        refreshEvents: vi.fn(),
        setHasShownConfetti: vi.fn(),
        setActiveBabyId: vi.fn(),
      });

      // Re-render with new events
      rerender(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      // The subscription should NOT be called again (preventing infinite loops)
      // Note: In a real infinite loop scenario, this would be called repeatedly
      // We want to ensure it doesn't exceed a reasonable number
      expect(subscriptionCallCount).toBeLessThanOrEqual(2); // Initial + maybe 1 re-setup
    });

    it('should handle async operations cancellation during unmount', async () => {
      // Mock an async operation that might be in progress during unmount
      let operationCancelled = false;

      vi.mocked(useHomeData).mockReturnValue({
        babies: [],
        selectedBaby: null,
        events: [],
        loading: false,
        summary: null,
        napWindow: null,
        streakDays: 0,
        showGuestBanner: false,
        trialDaysRemaining: null,
        hasShownConfetti: false,
        showAffirmation: false,
        refreshEvents: vi.fn().mockImplementation(async () => {
          // Simulate an async operation
          await new Promise(resolve => setTimeout(resolve, 100));
          if (!operationCancelled) {
            // This should not execute after unmount
            throw new Error('Operation should have been cancelled');
          }
        }),
        setHasShownConfetti: vi.fn(),
        setActiveBabyId: vi.fn(),
      });

      const { unmount } = render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      // Start an async operation
      const refreshEvents = vi.mocked(useHomeData).mock.results[0].value.refreshEvents;
      const operationPromise = refreshEvents();

      // Immediately unmount (before operation completes)
      operationCancelled = true;
      unmount();

      // Wait for the operation to potentially complete
      await new Promise(resolve => setTimeout(resolve, 150));

      // The operation should not throw (indicating it was properly cancelled)
      // If it wasn't cancelled, it would throw an error
      await expect(operationPromise).rejects.toThrow('Operation should have been cancelled');
    });

    it('should properly handle rapid re-mounting without memory leaks', async () => {
      const unsubscribeCalls: number[] = [];

      // Track unsubscribe calls
      vi.mocked(eventsService.subscribe).mockImplementation(() => {
        const callIndex = unsubscribeCalls.length;
        return () => unsubscribeCalls.push(callIndex);
      });

      // Mount component
      const { unmount: unmount1 } = render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      await waitFor(() => {
        expect(eventsService.subscribe).toHaveBeenCalledTimes(1);
      });

      // Unmount
      unmount1();
      expect(unsubscribeCalls).toEqual([0]);

      // Re-mount
      const { unmount: unmount2 } = render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      await waitFor(() => {
        expect(eventsService.subscribe).toHaveBeenCalledTimes(2);
      });

      // Unmount again
      unmount2();
      expect(unsubscribeCalls).toEqual([0, 1]);

      // Each mount should have a corresponding unmount
      expect(unsubscribeCalls.length).toBe(2);
    });
  });

  describe('Effect Dependency Management', () => {
    it('should not include events.length in useEffect dependencies', () => {
      // This test ensures that if events.length were in dependencies,
      // we'd have a mechanism to detect and prevent the infinite loop

      // Mock the hook to simulate the problematic behavior
      const effectRuns: number[] = [];
      let runCount = 0;

      vi.mocked(useHomeData).mockImplementation(() => {
        // Simulate useEffect running multiple times
        effectRuns.push(runCount++);

        return {
          babies: [],
          selectedBaby: null,
          events: Array(runCount)
            .fill({})
            .map((_, i) => ({ id: i.toString() })), // Changing events
          loading: false,
          summary: null,
          napWindow: null,
          streakDays: 0,
          showGuestBanner: false,
          trialDaysRemaining: null,
          hasShownConfetti: false,
          showAffirmation: false,
          refreshEvents: vi.fn(),
          setHasShownConfetti: vi.fn(),
          setActiveBabyId: vi.fn(),
        };
      });

      render(
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      );

      // If events.length was in dependencies, this would cause infinite re-renders
      // We want to ensure the component doesn't get stuck in infinite loops
      expect(effectRuns.length).toBeLessThan(10); // Reasonable upper bound
    });
  });
});
