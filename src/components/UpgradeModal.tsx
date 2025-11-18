import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Sparkles, Check } from 'lucide-react';
import { useSubscription } from '@/hooks/useSubscription';

interface UpgradeModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

// TODO: Replace with your actual Stripe Price ID after creating product in Stripe Dashboard
const PRICE_ID = 'price_REPLACE_WITH_YOUR_PRICE_ID';

export function UpgradeModal({ open, onOpenChange }: UpgradeModalProps) {
  const { createCheckoutSession, isCreatingSession } = useSubscription();

  const handleUpgrade = () => {
    createCheckoutSession(PRICE_ID);
  };

  const features = [
    { name: 'AI Nap Predictor', description: 'Smart predictions for optimal sleep times' },
    { name: 'Cry Pattern Analysis', description: 'Understand what baby needs' },
    { name: '24/7 AI Assistant', description: 'Get instant parenting guidance' },
    { name: 'Pattern Insights', description: 'Discover feeding and sleep patterns' },
    { name: 'Smart Reminders', description: 'Never miss important moments' },
    { name: 'Advanced Analytics', description: 'Deep insights into baby\'s rhythms' },
    { name: 'Multi-device Sync', description: 'Always in sync with caregivers' },
    { name: 'Export & Sharing', description: 'Share reports with pediatrician' },
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl flex items-center gap-2">
            <Sparkles className="h-6 w-6 text-primary" />
            Upgrade to Nestling Premium
          </DialogTitle>
          <DialogDescription>
            Unlock AI-powered insights and predictions for your baby
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {/* Pricing */}
          <div className="text-center p-6 bg-gradient-to-br from-primary/10 to-primary/5 rounded-lg">
            <div className="text-4xl font-bold mb-2">$9.99<span className="text-lg font-normal text-muted-foreground">/month</span></div>
            <p className="text-sm text-muted-foreground">14-day free trial • Cancel anytime</p>
          </div>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {features.map((feature) => (
              <div key={feature.name} className="flex gap-3">
                <Check className="h-5 w-5 text-primary flex-shrink-0 mt-0.5" />
                <div>
                  <div className="font-medium">{feature.name}</div>
                  <div className="text-sm text-muted-foreground">{feature.description}</div>
                </div>
              </div>
            ))}
          </div>

          {/* CTA */}
          <Button 
            onClick={handleUpgrade}
            disabled={isCreatingSession}
            className="w-full h-12 text-lg"
          >
            {isCreatingSession ? 'Loading...' : 'Start Free Trial'}
          </Button>

          <p className="text-center text-sm text-muted-foreground">
            No commitment. Full access during trial. Cancel anytime before trial ends.
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}
