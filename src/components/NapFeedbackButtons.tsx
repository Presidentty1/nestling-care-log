import { Button } from '@/components/ui/button';
import { ThumbsUp, ThumbsDown, Clock } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { analyticsService } from '@/services/analyticsService';
import { toast } from 'sonner';

interface NapFeedbackButtonsProps {
  predictionStart: string;
  predictionEnd: string;
  babyId: string;
  onFeedbackSubmitted?: () => void;
}

export function NapFeedbackButtons({
  predictionStart,
  predictionEnd,
  babyId,
  onFeedbackSubmitted,
}: NapFeedbackButtonsProps) {
  const handleFeedback = async (rating: 'too_early' | 'just_right' | 'too_late') => {
    try {
      // Store feedback as a special event type in dataService
      await dataService.addEvent({
        type: 'nap_feedback' as any,
        babyId,
        familyId: '',
        startTime: new Date().toISOString(),
        notes: JSON.stringify({
          rating,
          predictedStart: predictionStart,
          predictedEnd: predictionEnd,
        }),
      });

      analyticsService.trackFeedbackSubmitted(rating);

      toast.success('Thanks for your feedback!');
      onFeedbackSubmitted?.();
    } catch (error) {
      console.error('Failed to submit feedback:', error);
      toast.error('Failed to submit feedback');
    }
  };

  return (
    <div className='flex items-center gap-2 mt-3'>
      <span className='text-xs text-muted-foreground'>Was this helpful?</span>
      <Button
        variant='ghost'
        size='sm'
        onClick={() => handleFeedback('too_early')}
        className='h-7 px-2'
      >
        <Clock className='h-3 w-3 mr-1' />
        <span className='text-xs'>Too early</span>
      </Button>
      <Button
        variant='ghost'
        size='sm'
        onClick={() => handleFeedback('just_right')}
        className='h-7 px-2'
      >
        <ThumbsUp className='h-3 w-3 mr-1' />
        <span className='text-xs'>Just right</span>
      </Button>
      <Button
        variant='ghost'
        size='sm'
        onClick={() => handleFeedback('too_late')}
        className='h-7 px-2'
      >
        <ThumbsDown className='h-3 w-3 mr-1' />
        <span className='text-xs'>Too late</span>
      </Button>
    </div>
  );
}
