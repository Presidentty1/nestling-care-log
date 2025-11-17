import { BabyEvent } from '@/lib/types';
import { Card, CardContent } from '@/components/ui/card';
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
  event: BabyEvent;
  onEdit: () => void;
  onDelete: () => void;
}

export function TimelineRow({ event, onEdit, onDelete }: TimelineRowProps) {
  const getIcon = () => {
    switch (event.type) {
      case 'feed':
        return <Milk className="h-5 w-5 text-blue-500" />;
      case 'sleep':
        return <Moon className="h-5 w-5 text-purple-500" />;
      case 'diaper':
        return <Baby className="h-5 w-5 text-green-500" />;
      case 'tummy_time':
        return <ActivitySquare className="h-5 w-5 text-orange-500" />;
      default:
        return null;
    }
  };

  const getTitle = () => {
    let title = event.type.charAt(0).toUpperCase() + event.type.slice(1);
    
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
    <Card className="hover:bg-accent/50 transition-colors cursor-pointer" onClick={onEdit}>
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 flex-1 min-w-0">
            <div className="flex-shrink-0">{getIcon()}</div>
            <div className="flex-1 min-w-0">
              <div className="font-medium truncate">{getTitle()}</div>
              <div className="text-sm text-muted-foreground">{getTimeDisplay()}</div>
              {event.note && (
                <Badge variant="outline" className="mt-1 text-xs">
                  {event.note.length > 30 ? `${event.note.slice(0, 30)}...` : event.note}
                </Badge>
              )}
            </div>
          </div>
          
          <DropdownMenu>
            <DropdownMenuTrigger asChild onClick={(e) => e.stopPropagation()}>
              <Button 
                variant="ghost" 
                size="icon" 
                className="flex-shrink-0"
                aria-label="Event options"
              >
                <MoreVertical className="h-4 w-4" />
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
      </CardContent>
    </Card>
  );
}
