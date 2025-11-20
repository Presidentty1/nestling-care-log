import { EventRecord } from '@/services/eventsService';
import { SwipeableTimelineRow } from './SwipeableTimelineRow';
import { EmptyState } from '@/components/common/EmptyState';
import { Calendar } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { VirtualizedTimelineList } from './VirtualizedTimelineList';

interface TimelineListProps {
  events: EventRecord[];
  onEdit: (event: EventRecord) => void;
  onDelete: (eventId: string) => void;
  useVirtualization?: boolean; // Enable virtual scrolling for large lists
}

export function TimelineList({ events, onEdit, onDelete, useVirtualization = true }: TimelineListProps) {
  // Use virtualized list for large datasets (50+ events)
  if (useVirtualization && events.length >= 50) {
    return (
      <VirtualizedTimelineList
        events={events}
        onEdit={onEdit}
        onDelete={onDelete}
      />
    );
  }
  if (events.length === 0) {
    return (
      <EmptyState
        icon={Calendar}
        title="Your day is off to a quiet start ✨"
        description="Some days you'll log everything, some days just one feed. Both are okay. Tap the + button when you're ready to add your first event."
      />
    );
  }

  // Sort events by effective time (end_time if present, else start_time), most recent first
  const sortedEvents = [...events].sort((a, b) => {
    const timeA = new Date(a.end_time || a.start_time).getTime();
    const timeB = new Date(b.end_time || b.start_time).getTime();
    if (timeB !== timeA) return timeB - timeA;
    // Tie-breaker: created_at if available
    const ca = a.created_at ? new Date(a.created_at).getTime() : 0;
    const cb = b.created_at ? new Date(b.created_at).getTime() : 0;
    return cb - ca;
  });

  return (
    <div className="space-y-2">
      <AnimatePresence mode="popLayout">
        {sortedEvents.map((event, i) => (
          <motion.div
            key={event.id}
            initial={{ opacity: 0, x: 100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -100 }}
            transition={{ 
              duration: 0.3, 
              delay: i * 0.05,
              ease: "easeOut" 
            }}
          >
            <SwipeableTimelineRow
              event={event}
              onEdit={() => onEdit(event)}
              onDelete={() => onDelete(event.id)}
            />
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
