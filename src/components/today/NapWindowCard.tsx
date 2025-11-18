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

  return (
    <Card variant="emphasis">
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
            <Moon className="h-5 w-5 text-primary" />
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
