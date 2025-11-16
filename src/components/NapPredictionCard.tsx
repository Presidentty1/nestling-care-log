import { Card, CardContent } from '@/components/ui/card';
import { Moon, Clock } from 'lucide-react';
import { format, isBefore, isAfter } from 'date-fns';
import { NapPrediction } from '@/types/events';

interface NapPredictionCardProps {
  prediction: NapPrediction;
}

export function NapPredictionCard({ prediction }: NapPredictionCardProps) {
  const now = new Date();
  const windowStart = new Date(prediction.nextWindowStartISO);
  const windowEnd = new Date(prediction.nextWindowEndISO);
  
  const isInWindow = isAfter(now, windowStart) && isBefore(now, windowEnd);
  const isPast = isAfter(now, windowEnd);
  
  return (
    <Card className={`
      ${isInWindow ? 'bg-primary/10 border-primary' : ''}
      ${isPast ? 'opacity-60' : ''}
    `}>
      <CardContent className="p-4 flex items-start gap-3">
        <div className={`
          p-2 rounded-full 
          ${isInWindow ? 'bg-primary/20' : 'bg-muted'}
        `}>
          <Moon className="h-5 w-5" />
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-medium text-sm">Next Nap Window</h3>
            {isInWindow && (
              <span className="text-xs bg-primary text-primary-foreground px-2 py-0.5 rounded-full">
                Now
              </span>
            )}
          </div>
          <div className="flex items-center gap-1 text-sm text-muted-foreground">
            <Clock className="h-3 w-3" />
            <span>
              {format(windowStart, 'h:mm a')} - {format(windowEnd, 'h:mm a')}
            </span>
          </div>
          <p className="text-xs text-muted-foreground mt-1">
            {Math.round(prediction.confidence * 100)}% confidence
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
