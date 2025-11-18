import { EventRecord } from '@/services/eventsService';
import { SwipeableTimelineRow } from './SwipeableTimelineRow';
import { EmptyState } from '@/components/common/EmptyState';
import { Calendar } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface TimelineListProps {
  events: EventRecord[];
  onEdit: (event: EventRecord) => void;
  onDelete: (eventId: string) => void;
}

export function TimelineList({ events, onEdit, onDelete }: TimelineListProps) {
  if (events.length === 0) {
    return (
      <EmptyState
        icon={Calendar}
        title="Your day is off to a quiet start ✨"
        description="Tap the + button below to log your first event. Every baby's day is unique!"
      />
    );
  }

  // Sort events by start_time descending (most recent first)
  const sortedEvents = [...events].sort((a, b) => {
    const timeA = new Date(a.start_time).getTime();
    const timeB = new Date(b.start_time).getTime();
    return timeB - timeA;
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
