import { EventRecord } from '@/services/eventsService';
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

export function TimelineRow({ event, onEdit, onDelete }: TimelineRowProps) {
  const getIcon = () => {
    switch (event.type) {
      case 'feed':
        return <Milk className="h-6 w-6 text-primary" strokeWidth={2} />;
      case 'sleep':
        return <Moon className="h-6 w-6 text-primary" strokeWidth={2} />;
      case 'diaper':
        return <Baby className="h-6 w-6 text-primary" strokeWidth={2} />;
      case 'tummy_time':
        return <ActivitySquare className="h-6 w-6 text-primary" strokeWidth={2} />;
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
      const duration = event.end_time 
        ? Math.round((new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 60000)
        : 0;
      if (duration > 0) {
        title += ` · ${duration}m`;
      }
    }
    
    return title;
  };

  const getTimeDisplay = () => {
    const startTime = format(new Date(event.start_time), 'h:mm a');
    
    if (event.end_time && event.type === 'sleep') {
      const endTime = format(new Date(event.end_time), 'h:mm a');
      const duration = Math.round(
        (new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 60000
      );
      return `${startTime} - ${endTime} (${duration}m)`;
    }
    
    return startTime;
  };

  return (
    <button
      onClick={onEdit}
      className="w-full min-h-[64px] flex items-center gap-4 px-4 py-3 rounded-md hover:bg-accent/50 active:scale-[0.99] transition-all duration-100 text-left"
      style={{ minHeight: '44px' }}
    >
      {/* Left: Icon */}
      <div className="flex-shrink-0">
        {getIcon()}
      </div>

      {/* Middle: Title + Meta */}
      <div className="flex-1 min-w-0 space-y-1">
        <div className="text-[17px] leading-[24px] font-medium truncate">
          {getTitle()}
        </div>
        {event.note && (
          <Badge variant="secondary" className="text-[13px] leading-[18px] font-normal">
            {event.note.length > 40 ? `${event.note.slice(0, 40)}...` : event.note}
          </Badge>
        )}
      </div>

      {/* Right: Time + Menu */}
      <div className="flex items-center gap-3 flex-shrink-0">
        <div className="text-secondary text-muted-foreground text-right tabular-nums">
          {getTimeDisplay()}
        </div>
        
        <DropdownMenu>
          <DropdownMenuTrigger asChild onClick={(e) => e.stopPropagation()}>
            <Button 
              variant="ghost" 
              size="icon" 
              className="flex-shrink-0 h-11 w-11"
              aria-label="Event options"
            >
              <MoreVertical className="h-5 w-5" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={(e) => { e.stopPropagation(); onEdit(); }}>
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem 
              onClick={(e) => { e.stopPropagation(); onDelete(); }}
              className="text-destructive"
            >
              Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </button>
  );
}
