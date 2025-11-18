import { format } from 'date-fns';
import { Moon, Clock } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

interface NapWindowCardProps {
  window: {
    start: Date;
    end: Date;
    reason: string;
  };
}

export function NapWindowCard({ window }: NapWindowCardProps) {
  const formatTime = (date: Date) => format(date, 'h:mm a');

  // Determine status based on current time
  const now = new Date();
  const isWithinWindow = now >= window.start && now <= window.end;
  const isApproaching = !isWithinWindow && now < window.start && (window.start.getTime() - now.getTime()) < 30 * 60 * 1000; // Within 30 mins
  const isOverdue = now > window.end;

  // Status-aware styling
  const borderColor = isWithinWindow 
    ? 'border-success/30' 
    : isApproaching 
    ? 'border-warning/30' 
    : isOverdue 
    ? 'border-destructive/20' 
    : 'border-primary/20';
  
  const bgColor = isWithinWindow 
    ? 'bg-success/10' 
    : isApproaching 
    ? 'bg-warning/10' 
    : isOverdue 
    ? 'bg-destructive/5' 
    : 'bg-primary/5';

  return (
    <Card className={`border-2 ${borderColor} ${bgColor} shadow-md transition-colors`}>
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-full bg-event-sleep/10 flex items-center justify-center flex-shrink-0">
            <Moon className="h-5 w-5 text-event-sleep" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="font-semibold text-foreground">Nap Window</h3>
            </div>
            <div className="flex items-center gap-2 text-caption text-muted-foreground mb-2">
              <Clock className="h-4 w-4" />
              <span>{formatTime(window.start)} – {formatTime(window.end)}</span>
            </div>
            <p className="text-caption text-muted-foreground">{window.reason}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
