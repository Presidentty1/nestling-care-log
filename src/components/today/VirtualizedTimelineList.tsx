import { useRef, useMemo, useState, useEffect, useCallback } from 'react';
import type { EventRecord } from '@/services/eventsService';
import { SwipeableTimelineRow } from './SwipeableTimelineRow';
import { EmptyState } from '@/components/common/EmptyState';
import { Calendar } from 'lucide-react';
import { usePerformance } from '@/hooks/usePerformance';

interface VirtualizedTimelineListProps {
  events: EventRecord[];
  onEdit: (event: EventRecord) => void;
  onDelete: (eventId: string) => void;
  itemHeight?: number; // Estimated height per item in pixels
  overscan?: number; // Number of items to render outside visible area
}

const DEFAULT_ITEM_HEIGHT = 80; // Approximate height of a timeline row
const DEFAULT_OVERSCAN = 5;

/**
 * Virtualized timeline list for performance with large event lists.
 * Only renders visible items plus a buffer (overscan) above and below.
 */
export function VirtualizedTimelineList({
  events,
  onEdit,
  onDelete,
  itemHeight = DEFAULT_ITEM_HEIGHT,
  overscan = DEFAULT_OVERSCAN,
}: VirtualizedTimelineListProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [containerHeight, setContainerHeight] = useState(0);
  const scrollRafId = useRef<number>();

  // Performance monitoring
  usePerformance('VirtualizedTimelineList', events.length > 100);

  // Sort events by effective time (end_time if present, else start_time), most recent first
  const sortedEvents = useMemo(() => {
    return [...events].sort((a, b) => {
      const timeA = new Date(a.end_time || a.start_time).getTime();
      const timeB = new Date(b.end_time || b.start_time).getTime();
      if (timeB !== timeA) return timeB - timeA;
      const ca = a.created_at ? new Date(a.created_at).getTime() : 0;
      const cb = b.created_at ? new Date(b.created_at).getTime() : 0;
      return cb - ca;
    });
  }, [events]);

  // Calculate visible range
  const { startIndex, endIndex, totalHeight } = useMemo(() => {
    if (sortedEvents.length === 0 || containerHeight === 0) {
      return { startIndex: 0, endIndex: 0, totalHeight: 0 };
    }

    const visibleStart = Math.floor(scrollTop / itemHeight);
    const visibleEnd = Math.ceil((scrollTop + containerHeight) / itemHeight);
    
    const startIndex = Math.max(0, visibleStart - overscan);
    const endIndex = Math.min(sortedEvents.length, visibleEnd + overscan);
    
    const totalHeight = sortedEvents.length * itemHeight;

    return { startIndex, endIndex, totalHeight };
  }, [scrollTop, containerHeight, itemHeight, overscan, sortedEvents.length]);

  // Handle scroll with performance optimization
  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    // Cancel previous RAF to throttle updates
    if (scrollRafId.current) {
      cancelAnimationFrame(scrollRafId.current);
    }

    // Use RAF for smooth updates
    scrollRafId.current = requestAnimationFrame(() => {
      setScrollTop(e.currentTarget.scrollTop);
    });
  }, []);

  // Cleanup RAF on unmount
  useEffect(() => {
    return () => {
      if (scrollRafId.current) {
        cancelAnimationFrame(scrollRafId.current);
      }
    };
  }, []);

  // Measure container height
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        setContainerHeight(entry.contentRect.height);
      }
    });

    resizeObserver.observe(container);

    // Initial measurement
    setContainerHeight(container.clientHeight);

    return () => {
      resizeObserver.disconnect();
    };
  }, []);

  // Visible items
  const visibleItems = useMemo(() => {
    return sortedEvents.slice(startIndex, endIndex);
  }, [sortedEvents, startIndex, endIndex]);

  if (sortedEvents.length === 0) {
    return (
      <EmptyState
        icon={Calendar}
        title="Your day is off to a quiet start ✨"
        description="Tap the + button below to log your first event. Every baby's day is unique!"
      />
    );
  }

  // For small lists (< 20 items), use regular rendering
  if (sortedEvents.length < 20) {
    return (
      <div className="space-y-2">
        {sortedEvents.map((event) => (
          <SwipeableTimelineRow
            key={event.id}
            event={event}
            onEdit={() => onEdit(event)}
            onDelete={() => onDelete(event.id)}
          />
        ))}
      </div>
    );
  }

  // Virtualized rendering for large lists
  return (
    <div
      ref={containerRef}
      className="h-full overflow-y-auto"
      onScroll={handleScroll}
      style={{ scrollBehavior: 'smooth' }}
    >
      <div style={{ height: totalHeight, position: 'relative' }}>
        <div
          style={{
            transform: `translateY(${startIndex * itemHeight}px)`,
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
          }}
        >
          <div className="space-y-2">
            {visibleItems.map((event) => (
              <div key={event.id} style={{ height: itemHeight }}>
                <SwipeableTimelineRow
                  event={event}
                  onEdit={() => onEdit(event)}
                  onDelete={() => onDelete(event.id)}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}


