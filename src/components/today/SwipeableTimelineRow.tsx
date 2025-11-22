import { useState } from 'react';
import { useDrag } from '@use-gesture/react';
import { Trash2 } from 'lucide-react';
import { TimelineRow } from './TimelineRow';
import type { EventRecord } from '@/services/eventsService';
import { hapticFeedback } from '@/lib/haptics';

interface SwipeableTimelineRowProps {
  event: EventRecord;
  onEdit: () => void;
  onDelete: () => void;
}

export function SwipeableTimelineRow({ event, onEdit, onDelete }: SwipeableTimelineRowProps) {
  const [dragX, setDragX] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);
  const SWIPE_THRESHOLD = -80; // 80px swipe left to reveal delete
  
  const bind = useDrag(
    ({ movement: [mx], last, velocity: [vx] }) => {
      // Only allow swipe left (negative x)
      const finalX = mx < 0 ? Math.max(mx, SWIPE_THRESHOLD * 1.5) : 0;
      
      if (last) {
        // Swipe completed
        if (mx < SWIPE_THRESHOLD || (vx < -0.5 && mx < -20)) {
          // Swipe far enough or fast enough - show delete
          setDragX(SWIPE_THRESHOLD);
          hapticFeedback.light();
        } else {
          // Snap back
          setDragX(0);
        }
      } else {
        // During drag
        setDragX(finalX);
      }
    },
    {
      axis: 'x',
      bounds: { left: SWIPE_THRESHOLD * 1.5, right: 0 },
      rubberband: true,
    }
  );
  
  const handleDelete = () => {
    setIsDeleting(true);
    hapticFeedback.medium();
    
    // Animate out then delete
    setDragX(-400);
    setTimeout(() => onDelete(), 300);
  };
  
  return (
    <div className="relative overflow-hidden">
      {/* Delete button background */}
      <div className="absolute inset-y-0 right-0 flex items-center justify-end pr-4 bg-destructive">
        <button
          onClick={handleDelete}
          className="flex items-center gap-2 px-4 py-2 text-destructive-foreground font-medium"
          disabled={isDeleting}
        >
          <Trash2 className="h-5 w-5" />
          <span>Delete</span>
        </button>
      </div>
      
      {/* Swipeable timeline row */}
      <div
        {...bind()}
        style={{ 
          transform: `translateX(${dragX}px)`,
          transition: isDeleting ? 'transform 300ms ease-out' : 'none',
          touchAction: 'pan-y',
        }}
        className="relative bg-background"
      >
        <TimelineRow event={event} onEdit={onEdit} onDelete={onDelete} />
      </div>
    </div>
  );
}
