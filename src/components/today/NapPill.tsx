import { useState } from 'react';
import { Moon, Clock, ThumbsUp, ThumbsDown, Minus } from 'lucide-react';
import { format, isBefore, isAfter } from 'date-fns';
import { NapPrediction } from '@/types/events';
import { Button } from '@/components/ui/button';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { dataService } from '@/services/dataService';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';

interface NapPillProps {
  prediction: NapPrediction;
  babyId: string;
  onFeedbackSubmitted?: () => void;
  className?: string;
}

export function NapPill({ prediction, babyId, onFeedbackSubmitted, className }: NapPillProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const now = new Date();
  const windowStart = new Date(prediction.nextWindowStartISO);
  const windowEnd = new Date(prediction.nextWindowEndISO);
  
  const isInWindow = isAfter(now, windowStart) && isBefore(now, windowEnd);
  const isPast = isAfter(now, windowEnd);

  // Don't show if window is past
  if (isPast) return null;

  const handleFeedback = async (rating: 'too_early' | 'just_right' | 'too_late') => {
    setIsSubmitting(true);
    try {
      await dataService.addNapFeedback({
        babyId,
        predictionStartISO: prediction.nextWindowStartISO,
        predictionEndISO: prediction.nextWindowEndISO,
        rating,
      });
      
      toast.success('Thanks for your feedback!');
      setIsOpen(false);
      onFeedbackSubmitted?.();
    } catch (error) {
      console.error('Failed to submit feedback:', error);
      toast.error('Could not save feedback. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Popover open={isOpen} onOpenChange={setIsOpen}>
      <PopoverTrigger asChild>
        <button
          className={cn(
            'flex items-center gap-2 px-4 py-2 rounded-full transition-all',
            'hover:scale-105 active:scale-95',
            isInWindow 
              ? 'bg-primary text-primary-foreground shadow-lg animate-pulse' 
              : 'bg-muted hover:bg-muted/80',
            className
          )}
          aria-label="Nap window prediction"
        >
          <Moon className="h-4 w-4" />
          <span className="text-sm font-medium">
            Next nap window {format(windowStart, 'h:mm')}–{format(windowEnd, 'h:mm a')}
          </span>
          {isInWindow && (
            <span className="ml-1 px-2 py-0.5 text-xs bg-primary-foreground text-primary rounded-full">
              Now
            </span>
          )}
        </button>
      </PopoverTrigger>
      <PopoverContent className="w-80" align="start">
        <div className="space-y-4">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Clock className="h-4 w-4 text-muted-foreground" />
              <span className="font-medium">
                {format(windowStart, 'h:mm a')} - {format(windowEnd, 'h:mm a')}
              </span>
            </div>
            <p className="text-sm text-muted-foreground">
              {prediction.reason}
            </p>
            <p className="text-xs text-muted-foreground mt-2">
              {Math.round(prediction.confidence * 100)}% confidence
            </p>
          </div>

          <div className="space-y-2">
            <p className="text-sm font-medium">Was this prediction helpful?</p>
            <div className="grid grid-cols-3 gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleFeedback('too_early')}
                disabled={isSubmitting}
                className="flex flex-col h-auto py-2"
              >
                <ThumbsDown className="h-4 w-4 mb-1" />
                <span className="text-xs">Too Early</span>
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleFeedback('just_right')}
                disabled={isSubmitting}
                className="flex flex-col h-auto py-2"
              >
                <ThumbsUp className="h-4 w-4 mb-1" />
                <span className="text-xs">Just Right</span>
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleFeedback('too_late')}
                disabled={isSubmitting}
                className="flex flex-col h-auto py-2"
              >
                <Minus className="h-4 w-4 mb-1" />
                <span className="text-xs">Too Late</span>
              </Button>
            </div>
            <p className="text-xs text-muted-foreground mt-2">
              Your feedback helps improve predictions for your baby's unique sleep patterns.
            </p>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
