import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Sparkles, Check } from 'lucide-react';
import { trialService } from '@/services/trialService';
import { triggerConfetti } from '@/lib/confetti';
import { toast } from 'sonner';

interface TrialStartModalProps {
  babyBirthdate: string;
  onStarted?: () => void;
}

const PREMIUM_FEATURES = [
  'AI-powered nap predictions',
  'Cry pattern analysis',
  'Smart feeding reminders',
  'Personalized insights',
  'Weekly summary reports',
];

export function TrialStartModal({ babyBirthdate, onStarted }: TrialStartModalProps) {
  const [open, setOpen] = useState(false);
  const [starting, setStarting] = useState(false);

  useEffect(() => {
    checkAndShow();
  }, [babyBirthdate]);

  const checkAndShow = async () => {
    const shouldShow = await trialService.shouldShowTrialStartModal(babyBirthdate);
    setOpen(shouldShow);
  };

  const handleStartTrial = async () => {
    setStarting(true);
    try {
      await trialService.startTrial();
      await trialService.markTrialModalShown();
      triggerConfetti();
      toast.success('Your 14-day free trial has started! 🎉');
      setOpen(false);
      onStarted?.();
    } catch (error) {
      toast.error('Failed to start trial');
    } finally {
      setStarting(false);
    }
  };

  const handleMaybeLater = async () => {
    await trialService.markTrialModalShown();
    setOpen(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <div className="flex justify-center mb-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
              <Sparkles className="h-8 w-8 text-primary-foreground" />
            </div>
          </div>
          <DialogTitle className="text-center text-xl">
            Your baby is 2 months old! 🎉
          </DialogTitle>
          <DialogDescription className="text-center text-base pt-2">
            Unlock premium AI features with a 14-day free trial
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3 py-4">
          {PREMIUM_FEATURES.map((feature) => (
            <div key={feature} className="flex items-center gap-3">
              <div className="w-5 h-5 rounded-full bg-success/20 flex items-center justify-center shrink-0">
                <Check className="h-3 w-3 text-success" />
              </div>
              <span className="text-sm">{feature}</span>
            </div>
          ))}
        </div>

        <DialogFooter className="flex-col gap-2">
          <Button 
            onClick={handleStartTrial}
            disabled={starting}
            size="lg"
            className="w-full"
          >
            {starting ? 'Starting...' : 'Start 14-Day Free Trial'}
          </Button>
          <Button 
            onClick={handleMaybeLater}
            variant="ghost"
            size="sm"
            className="w-full"
          >
            Maybe Later
          </Button>
          <p className="text-xs text-center text-muted-foreground">
            No credit card required • Cancel anytime
          </p>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
