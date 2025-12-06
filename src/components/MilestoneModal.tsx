import { Dialog, DialogContent } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Trophy, TrendingUp, Brain, ArrowRight } from 'lucide-react';
import { triggerConfetti } from '@/lib/animations';
import { useEffect } from 'react';

interface MilestoneModalProps {
  isOpen: boolean;
  onClose: () => void;
  milestone: 3 | 5 | 10;
}

export function MilestoneModal({ isOpen, onClose, milestone }: MilestoneModalProps) {
  useEffect(() => {
    if (isOpen) {
      triggerConfetti({ count: 30 });
    }
  }, [isOpen]);

  const getMilestoneContent = () => {
    if (milestone === 3) {
      return {
        title: 'You're building a habit! 🎉',
        subtitle: '3 logs completed',
        benefits: [
          {
            icon: TrendingUp,
            title: 'Patterns emerging',
            description: 'We can now show you basic feeding and sleep frequency',
          },
        ],
        cta: 'Keep going!',
      };
    } else if (milestone === 5) {
      return {
        title: 'AI is learning your baby! 🧠',
        subtitle: '5 logs completed',
        benefits: [
          {
            icon: Brain,
            title: 'Smart predictions unlocked',
            description: 'AI now understands your baby's unique patterns and can predict nap times',
          },
          {
            icon: TrendingUp,
            title: 'Better insights',
            description: 'You'll start seeing personalized recommendations',
          },
        ],
        cta: 'View predictions',
      };
    } else {
      return {
        title: 'You're a tracking champion! 🏆',
        subtitle: '10 logs completed',
        benefits: [
          {
            icon: Brain,
            title: 'Advanced insights',
            description: 'Unlock detailed analytics and pattern detection',
          },
        ],
        cta: 'View analytics',
      };
    }
  };

  const content = getMilestoneContent();

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <div className="text-center py-6 animate-fade-in">
          {/* Trophy Icon */}
          <div className="w-20 h-20 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-6 animate-scale-in">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
              <Trophy className="h-10 w-10 text-primary-foreground" />
            </div>
          </div>
          
          {/* Title */}
          <h2 className="text-2xl font-bold mb-2">
            {content.title}
          </h2>
          
          {/* Subtitle */}
          <p className="text-base text-muted-foreground mb-6">
            {content.subtitle}
          </p>
          
          {/* Benefits */}
          <div className="space-y-3 mb-6">
            {content.benefits.map((benefit, index) => (
              <Card key={index} className="border-2 border-primary/20 bg-primary/5">
                <CardContent className="p-4">
                  <div className="flex items-start gap-3 text-left">
                    <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
                      <benefit.icon className="h-5 w-5 text-primary" />
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-sm mb-1">{benefit.title}</h3>
                      <p className="text-xs text-muted-foreground">{benefit.description}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
          
          {/* CTA */}
          <Button
            size="lg"
            onClick={onClose}
            className="w-full group"
          >
            {content.cta}
            <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
          </Button>
          
          <p className="text-xs text-muted-foreground mt-4">
            Keep logging to unlock more features
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}
