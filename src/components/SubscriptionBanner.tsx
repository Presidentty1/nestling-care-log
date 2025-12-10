import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Crown, X, Sparkles } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { subscriptionService } from '@/services/subscriptionService';

export function SubscriptionBanner() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [isVisible, setIsVisible] = useState(true);
  const [trialDaysLeft, setTrialDaysLeft] = useState<number | null>(null);

  // Check trial status when component mounts
  useState(() => {
    if (user) {
      subscriptionService.getTrialDaysRemaining(user.id).then(days => {
        setTrialDaysLeft(days);
      });
    }
  });

  const handleUpgrade = () => {
    navigate('/subscription');
  };

  const handleDismiss = () => {
    setIsVisible(false);
    // Store dismissal in localStorage for 7 days
    localStorage.setItem('subscription_banner_dismissed', Date.now().toString());
  };

  // Don't show if user dismissed it recently (within 7 days)
  const lastDismissed = localStorage.getItem('subscription_banner_dismissed');
  if (lastDismissed) {
    const daysSinceDismissed = (Date.now() - parseInt(lastDismissed)) / (1000 * 60 * 60 * 24);
    if (daysSinceDismissed < 7) {
      return null;
    }
  }

  if (!isVisible) return null;

  const isTrialEnding = trialDaysLeft !== null && trialDaysLeft <= 3;

  return (
    <Card className={`mx-4 mb-4 border-primary/20 ${
      isTrialEnding
        ? 'bg-gradient-to-r from-warning/10 to-warning/5'
        : 'bg-gradient-to-r from-primary/10 to-primary/5'
    }`}>
      <div className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-3 flex-1">
            <div className={`p-2 rounded-full ${
              isTrialEnding ? 'bg-warning/20' : 'bg-primary/20'
            }`}>
              {isTrialEnding ? (
                <Sparkles className="h-4 w-4 text-warning" />
              ) : (
                <Crown className="h-4 w-4 text-primary" />
              )}
            </div>

            <div className="flex-1">
              <h3 className="font-semibold text-sm mb-1">
                {isTrialEnding
                  ? 'Your free trial is ending soon!'
                  : 'Unlock AI-powered parenting tools'
                }
              </h3>

              <p className="text-xs text-muted-foreground mb-3">
                {isTrialEnding
                  ? `Only ${trialDaysLeft} day${trialDaysLeft === 1 ? '' : 's'} left. Upgrade now to keep AI nap predictions and cry analysis.`
                  : 'Get AI nap predictions, unlimited cry analysis, and 24/7 parenting support.'
                }
              </p>

              <Button
                size="sm"
                onClick={handleUpgrade}
                className="mr-2"
              >
                <Crown className="h-3 w-3 mr-1" />
                {isTrialEnding ? 'Upgrade Now' : 'Start Free Trial'}
              </Button>
            </div>
          </div>

          <Button
            variant="ghost"
            size="sm"
            onClick={handleDismiss}
            className="text-muted-foreground hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </Card>
  );
}

