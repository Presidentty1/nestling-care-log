import { BabyEvent } from '@/lib/types';
import { TimelineRow } from './TimelineRow';
import { EmptyState } from '@/components/common/EmptyState';
import { Calendar } from 'lucide-react';

interface TimelineListProps {
  events: BabyEvent[];
  onEdit: (event: BabyEvent) => void;
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

  // Sort events by start time, most recent first
  const sortedEvents = [...events].sort((a, b) => 
    new Date(b.start_time).getTime() - new Date(a.start_time).getTime()
  );

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
