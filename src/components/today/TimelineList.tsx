import { EventRecord } from '@/services/eventsService';
import { TimelineRow } from './TimelineRow';
import { EmptyState } from '@/components/common/EmptyState';
import { Calendar } from 'lucide-react';

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
        title="No Events Yet"
        description="Start logging your baby's activities using the quick actions above."
      />
    );
  }

  // Events already sorted from service
  const sortedEvents = events;

  return (
    <div className="space-y-2">
      {sortedEvents.map((event) => (
        <TimelineRow
          key={event.id}
          event={event}
          onEdit={() => onEdit(event)}
          onDelete={() => onDelete(event.id)}
        />
      ))}
    </div>
  );
}
