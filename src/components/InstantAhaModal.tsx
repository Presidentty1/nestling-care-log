import { Dialog, DialogContent } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Brain, Sparkles, Moon, TrendingUp, ArrowRight } from 'lucide-react';

interface InstantAhaModalProps {
  isOpen: boolean;
  onClose: () => void;
  babyAgeInWeeks: number;
  eventType: string;
}

export function InstantAhaModal({
  isOpen,
  onClose,
  babyAgeInWeeks,
  eventType,
}: InstantAhaModalProps) {
  // Rule-based predictions to show immediate value
  const getPrediction = () => {
    if (eventType === 'feed') {
      if (babyAgeInWeeks < 4) {
        return {
          title: 'Next feeding window',
          prediction: '2-3 hours from now',
          explanation: 'Newborns typically feed every 2-3 hours',
          confidence: 'Based on age-appropriate patterns',
        };
      } else if (babyAgeInWeeks < 12) {
        return {
          title: 'Next feeding window',
          prediction: '3-4 hours from now',
          explanation: 'Your baby is developing longer feeding intervals',
          confidence: 'Based on age-appropriate patterns',
        };
      } else {
        return {
          title: 'Next feeding window',
          prediction: '4-5 hours from now',
          explanation: 'Older babies can go longer between feeds',
          confidence: 'Based on age-appropriate patterns',
        };
      }
    } else if (eventType === 'sleep') {
      if (babyAgeInWeeks < 8) {
        return {
          title: 'Next nap window',
          prediction: '1-1.5 hours from now',
          explanation: 'Newborns need frequent naps with short wake windows',
          confidence: 'Based on age-appropriate wake windows',
        };
      } else if (babyAgeInWeeks < 16) {
        return {
          title: 'Next nap window',
          prediction: '1.5-2 hours from now',
          explanation: 'Your baby can stay awake a bit longer now',
          confidence: 'Based on age-appropriate wake windows',
        };
      } else {
        return {
          title: 'Next nap window',
          prediction: '2-3 hours from now',
          explanation: 'Older babies have longer wake windows',
          confidence: 'Based on age-appropriate wake windows',
        };
      }
    }

    return {
      title: 'Pattern tracking started',
      prediction: 'Log a few more events',
      explanation: "We'll start showing personalized predictions",
      confidence: 'After 3-5 logs',
    };
  };

  const prediction = getPrediction();

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className='max-w-md'>
        <div className='text-center py-6 animate-fade-in'>
          {/* AI Icon */}
          <div className='w-20 h-20 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-6 animate-scale-in relative'>
            <div className='w-16 h-16 rounded-full bg-primary flex items-center justify-center'>
              <Brain className='h-10 w-10 text-primary-foreground' />
            </div>
            <div className='absolute -top-1 -right-1 w-8 h-8 rounded-full bg-secondary flex items-center justify-center'>
              <Sparkles className='h-5 w-5 text-secondary-foreground' />
            </div>
          </div>

          {/* Title */}
          <h2 className='text-2xl font-bold mb-3'>AI is already working for you! 🎉</h2>

          {/* Subtitle */}
          <p className='text-base text-muted-foreground mb-6'>
            Based on your baby's age, here's what we predict:
          </p>

          {/* Prediction Card */}
          <Card className='border-2 border-primary/30 bg-gradient-to-br from-primary/5 to-primary/10 mb-6'>
            <CardContent className='p-6'>
              <div className='flex items-start gap-4'>
                <div className='w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center shrink-0'>
                  <Moon className='h-6 w-6 text-primary' />
                </div>
                <div className='flex-1 text-left'>
                  <h3 className='font-semibold text-lg mb-2'>{prediction.title}</h3>
                  <p className='text-2xl font-bold text-primary mb-2'>{prediction.prediction}</p>
                  <p className='text-sm text-muted-foreground mb-1'>{prediction.explanation}</p>
                  <p className='text-xs text-muted-foreground italic'>{prediction.confidence}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Value Proposition */}
          <div className='bg-secondary/5 rounded-xl p-4 mb-6 text-left space-y-3'>
            <div className='flex items-start gap-3'>
              <TrendingUp className='h-5 w-5 text-secondary shrink-0 mt-0.5' />
              <div>
                <p className='text-sm font-medium mb-1'>Getting smarter with every log</p>
                <p className='text-xs text-muted-foreground'>
                  After 3-5 logs, we'll learn your baby's unique patterns and give personalized
                  predictions.
                </p>
              </div>
            </div>
            <div className='flex items-start gap-3'>
              <Sparkles className='h-5 w-5 text-primary shrink-0 mt-0.5' />
              <div>
                <p className='text-sm font-medium mb-1'>No more guessing</p>
                <p className='text-xs text-muted-foreground'>
                  Plan your day around naps, feeds, and sleep with confidence.
                </p>
              </div>
            </div>
          </div>

          {/* CTA */}
          <Button size='lg' onClick={onClose} className='w-full group'>
            Continue Tracking
            <ArrowRight className='ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform' />
          </Button>

          <p className='text-xs text-muted-foreground mt-4'>
            Keep logging to unlock more accurate predictions
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}
