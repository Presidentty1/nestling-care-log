import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Crown, X, Check } from 'lucide-react';
import { PRICING } from '@/config/subscription';

interface PaywallModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  feature?: string;
  title?: string;
  description?: string;
}

export function PaywallModal({
  open,
  onOpenChange,
  feature = 'this feature',
  title = 'Premium Feature',
  description = 'Upgrade to Nuzzle Premium to unlock this feature and many more AI-powered tools.'
}: PaywallModalProps) {
  const navigate = useNavigate();
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly');

  const handleUpgrade = () => {
    onOpenChange(false);
    navigate('/subscription');
  };

  const selectedPricing = selectedPlan === 'monthly' ? PRICING.monthly : PRICING.yearly;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Crown className="h-5 w-5 text-primary" />
              <DialogTitle>{title}</DialogTitle>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onOpenChange(false)}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
          <DialogDescription>
            {description}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Feature Preview */}
          <div className="bg-muted/50 rounded-lg p-4">
            <p className="text-sm font-medium mb-2">You're trying to access:</p>
            <p className="text-sm text-muted-foreground">{feature}</p>
          </div>

          {/* Plan Selection */}
          <div className="space-y-3">
            <p className="text-sm font-medium">Choose your plan:</p>

            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => setSelectedPlan('monthly')}
                className={`p-3 rounded-lg border text-left transition-all ${
                  selectedPlan === 'monthly'
                    ? 'border-primary bg-primary/5'
                    : 'border-border hover:border-primary/50'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium">Monthly</span>
                  {selectedPlan === 'monthly' && (
                    <Badge variant="secondary" className="text-xs">Selected</Badge>
                  )}
                </div>
                <div className="text-lg font-bold">${PRICING.monthly.amount}</div>
                <div className="text-xs text-muted-foreground">per month</div>
              </button>

              <button
                onClick={() => setSelectedPlan('yearly')}
                className={`p-3 rounded-lg border text-left transition-all ${
                  selectedPlan === 'yearly'
                    ? 'border-primary bg-primary/5'
                    : 'border-border hover:border-primary/50'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium">Yearly</span>
                  {selectedPlan === 'yearly' && (
                    <Badge className="bg-primary text-xs">Best Value</Badge>
                  )}
                </div>
                <div className="text-lg font-bold">${PRICING.yearly.amount}</div>
                <div className="text-xs text-muted-foreground">per year</div>
                <div className="text-xs text-success font-medium">
                  Save ${(PRICING.monthly.amount * 12 - PRICING.yearly.amount).toFixed(0)}
                </div>
              </button>
            </div>
          </div>

          {/* Key Benefits */}
          <div className="space-y-2">
            <p className="text-sm font-medium">Premium includes:</p>
            <div className="space-y-1">
              <div className="flex items-center gap-2 text-sm">
                <Check className="h-3 w-3 text-success" />
                <span>AI Nap Predictions</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Check className="h-3 w-3 text-success" />
                <span>Unlimited Cry Analysis</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Check className="h-3 w-3 text-success" />
                <span>24/7 AI Assistant</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Check className="h-3 w-3 text-success" />
                <span>Weekly Insights</span>
              </div>
            </div>
          </div>

          {/* CTA */}
          <div className="flex gap-3">
            <Button
              onClick={handleUpgrade}
              className="flex-1"
            >
              <Crown className="h-4 w-4 mr-2" />
              Start {PRICING.trialDays}-Day Free Trial
            </Button>
            <Button
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Maybe Later
            </Button>
          </div>

          <p className="text-xs text-center text-muted-foreground">
            Cancel anytime • No credit card required for trial
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}

