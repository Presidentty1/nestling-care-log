import { memo } from 'react';
import type { EventRecord } from '@/services/eventsService';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, ActivitySquare, MoreVertical } from 'lucide-react';
import { format } from 'date-fns';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

interface TimelineRowProps {
  event: EventRecord;
  onEdit: () => void;
  onDelete: () => void;
}

export const TimelineRow = memo(({ event, onEdit, onDelete }: TimelineRowProps) => {
  const getIcon = () => {
    switch (event.type) {
      case 'feed':
        return <Milk className="h-6 w-6 text-event-feed" strokeWidth={2} />;
      case 'sleep':
        return <Moon className="h-6 w-6 text-event-sleep" strokeWidth={2} />;
      case 'diaper':
        return <Baby className="h-6 w-6 text-event-diaper" strokeWidth={2} />;
      case 'tummy_time':
        return <ActivitySquare className="h-6 w-6 text-event-tummy" strokeWidth={2} />;
      default:
        return null;
    }
  };

  const getTitle = () => {
    let title = event.type.charAt(0).toUpperCase() + event.type.slice(1).replace('_', ' ');
    
    if (event.subtype) {
      const subtype = event.subtype.split('_')[0];
      title += ` · ${subtype.charAt(0).toUpperCase() + subtype.slice(1)}`;
    }
    
    if (event.amount && event.unit) {
      title += ` · ${event.amount} ${event.unit}`;
    } else if (event.type === 'feed' && event.subtype?.startsWith('breast')) {
      const duration = event.duration_sec || 
        (event.end_time ? Math.round((new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 1000) : 0);
      if (duration > 0) {
        if (duration < 60) {
          title += ` · ${duration}s`;
        } else if (duration < 3600) {
          const mins = Math.floor(duration / 60);
          const secs = duration % 60;
          title += secs > 0 ? ` · ${mins}m ${secs}s` : ` · ${mins}m`;
        } else {
          const hours = Math.floor(duration / 3600);
          const mins = Math.floor((duration % 3600) / 60);
          title += mins > 0 ? ` · ${hours}h ${mins}m` : ` · ${hours}h`;
        }
      }
    }
    
    return title;
  };

  const getTimeDisplay = () => {
    const startTime = format(new Date(event.start_time), 'h:mm a');
    
    if (event.end_time && event.type === 'sleep') {
      const endTime = format(new Date(event.end_time), 'h:mm a');
      const duration = event.duration_sec || 
        Math.round((new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 1000);
      
      let durationStr = '';
      if (duration < 60) {
        durationStr = `${duration}s`;
      } else if (duration < 3600) {
        const mins = Math.floor(duration / 60);
        const secs = duration % 60;
        durationStr = secs > 0 ? `${mins}m ${secs}s` : `${mins}m`;
      } else {
        const hours = Math.floor(duration / 3600);
        const mins = Math.floor((duration % 3600) / 60);
        durationStr = mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
      }
      
      return `${startTime} - ${endTime} (${durationStr})`;
    }
    
    return startTime;
  };

  return (
    <div
      className="w-full min-h-[64px] flex items-center gap-4 px-4 py-3 rounded-md hover:bg-accent/50 active:scale-[0.99] transition-all duration-100 cursor-pointer"
      style={{ minHeight: '44px' }}
    >
      <div 
        className="flex-shrink-0 flex items-center gap-4 flex-1 min-w-0"
        onClick={onEdit}
      >
        <div className="flex-shrink-0">
          {getIcon()}
        </div>

        <div className="flex-1 min-w-0 space-y-1">
          <div className="text-[17px] leading-[24px] font-medium truncate">
            {getTitle()}
          </div>
          {event.note && (
            <Badge variant="secondary" className="text-[13px] leading-[18px] font-normal">
              {event.note}
            </Badge>
          )}
          <div className="text-[14px] leading-[20px] text-text-subtle">
            {getTimeDisplay()}
          </div>
        </div>
      </div>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="h-10 w-10 p-0 flex-shrink-0"
            onClick={(e) => e.stopPropagation()}
            aria-label="Event options"
          >
            <MoreVertical className="h-5 w-5" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem onClick={(e) => {
            e.stopPropagation();
            onEdit();
          }}>
            Edit
          </DropdownMenuItem>
          <DropdownMenuItem 
            className="text-destructive"
            onClick={(e) => {
              e.stopPropagation();
              onDelete();
            }}
          >
            Delete
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}, (prevProps, nextProps) => {
  return prevProps.event.id === nextProps.event.id &&
         prevProps.event.updated_at === nextProps.event.updated_at;
});
