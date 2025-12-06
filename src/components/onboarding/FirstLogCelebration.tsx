import { Dialog, DialogContent } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Check, Sparkles } from 'lucide-react';
import { MESSAGING } from '@/lib/messaging';
import { useEffect } from 'react';

interface FirstLogCelebrationProps {
  isOpen: boolean;
  onClose: () => void;
}

export function FirstLogCelebration({ isOpen, onClose }: FirstLogCelebrationProps) {
  // Trigger confetti effect when modal opens
  useEffect(() => {
    if (isOpen) {
      // Simple confetti simulation with DOM manipulation
      const createConfetti = () => {
        const confettiCount = 50;
        const colors = ['#2E7D6A', '#6A7DFF', '#0BA5EC', '#8B5CF6', '#FB923C'];
        
        for (let i = 0; i < confettiCount; i++) {
          const confetti = document.createElement('div');
          confetti.style.position = 'fixed';
          confetti.style.width = '10px';
          confetti.style.height = '10px';
          confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
          confetti.style.left = Math.random() * 100 + '%';
          confetti.style.top = '-10px';
          confetti.style.borderRadius = Math.random() > 0.5 ? '50%' : '0';
          confetti.style.opacity = '1';
          confetti.style.pointerEvents = 'none';
          confetti.style.zIndex = '9999';
          confetti.style.transition = 'all 3s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
          
          document.body.appendChild(confetti);
          
          // Animate
          setTimeout(() => {
            confetti.style.top = '100vh';
            confetti.style.left = (parseInt(confetti.style.left) + (Math.random() * 40 - 20)) + '%';
            confetti.style.opacity = '0';
          }, 10);
          
          // Remove after animation
          setTimeout(() => {
            confetti.remove();
          }, 3000);
        }
      };
      
      createConfetti();
    }
  }, [isOpen]);

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <div className="text-center py-6 animate-fade-in">
          {/* Success Icon */}
          <div className="w-20 h-20 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-6 animate-scale-in">
            <div className="w-16 h-16 rounded-full bg-primary flex items-center justify-center">
              <Check className="h-10 w-10 text-primary-foreground" />
            </div>
          </div>
          
          {/* Title */}
          <h2 className="text-2xl font-bold mb-3">
            {MESSAGING.firstTime.firstLog.title}
          </h2>
          
          {/* Subtitle */}
          <p className="text-base text-muted-foreground mb-6">
            {MESSAGING.firstTime.firstLog.subtitle}
          </p>
          
          {/* Next Steps - More motivating */}
          <div className="bg-primary/5 rounded-xl p-4 mb-6 text-left space-y-3">
            <div className="flex items-start gap-3">
              <Sparkles className="h-5 w-5 text-primary shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium mb-1">What happens next?</p>
                <p className="text-xs text-muted-foreground">
                  Log 2-3 more events and we'll start showing you personalized patterns and predictions.
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <Check className="h-5 w-5 text-primary shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium mb-1">You're already ahead</p>
                <p className="text-xs text-muted-foreground">
                  Most parents forget to track. You're building a valuable record for your baby.
                </p>
              </div>
            </div>
          </div>
          
          {/* CTA */}
          <Button
            size="lg"
            onClick={onClose}
            className="w-full"
          >
            Continue
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

