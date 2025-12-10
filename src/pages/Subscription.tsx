import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Check, Crown, X, Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { subscriptionService } from '@/services/subscriptionService';
import { PRICING, FEATURES } from '@/config/subscription';
import { FeatureComparisonTable } from '@/components/FeatureComparisonTable';
import { toast } from 'sonner';

export default function Subscription() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubscribe = async () => {
    if (!user) {
      toast.error('Please sign in to subscribe');
      return;
    }

    setIsLoading(true);
    try {
      const priceId = selectedPlan === 'monthly' ? PRICING.monthly.priceId : PRICING.yearly.priceId;
      const result = await subscriptionService.createCheckoutSession(priceId, user.id);

      if (result?.url) {
        // Redirect to Stripe Checkout
        window.location.href = result.url;
      } else {
        toast.error('Failed to create checkout session');
      }
    } catch (error) {
      console.error('Subscription error:', error);
      toast.error('Failed to start subscription process');
    } finally {
      setIsLoading(false);
    }
  };

  const selectedPricing = selectedPlan === 'monthly' ? PRICING.monthly : PRICING.yearly;
  const savings = selectedPlan === 'yearly' ?
    `Save ${(PRICING.monthly.amount * 12 - PRICING.yearly.amount).toFixed(0)} vs monthly` : '';

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold mb-4">Upgrade to Nuzzle Premium</h1>
            <p className="text-lg text-muted-foreground">
              Unlock AI-powered features to make parenting easier and get more sleep
            </p>
          </div>

          {/* Plan Selection */}
          <div className="grid md:grid-cols-2 gap-6 mb-8">
            {/* Monthly Plan */}
            <Card
              className={`cursor-pointer transition-all ${
                selectedPlan === 'monthly' ? 'ring-2 ring-primary' : ''
              }`}
              onClick={() => setSelectedPlan('monthly')}
            >
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <span>Monthly</span>
                  {selectedPlan === 'monthly' && <Badge>Selected</Badge>}
                </CardTitle>
                <CardDescription>Pay month-to-month</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold mb-2">
                  ${PRICING.monthly.amount}
                  <span className="text-lg font-normal text-muted-foreground">/month</span>
                </div>
                <ul className="space-y-2 text-sm">
                  <li className="flex items-center gap-2">
                    <Check className="h-4 w-4 text-success" />
                    7-day free trial
                  </li>
                  <li className="flex items-center gap-2">
                    <Check className="h-4 w-4 text-success" />
                    Cancel anytime
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* Yearly Plan */}
            <Card
              className={`cursor-pointer transition-all ${
                selectedPlan === 'yearly' ? 'ring-2 ring-primary' : ''
              }`}
              onClick={() => setSelectedPlan('yearly')}
            >
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center gap-2">
                      <Crown className="h-5 w-5 text-primary" />
                      <span>Yearly</span>
                    </CardTitle>
                    <CardDescription>Best value - save 30%</CardDescription>
                  </div>
                  {selectedPlan === 'yearly' && <Badge className="bg-primary">Selected</Badge>}
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold mb-2">
                  ${PRICING.yearly.amount}
                  <span className="text-lg font-normal text-muted-foreground">/year</span>
                </div>
                <div className="text-sm text-success font-medium mb-4">
                  Save ${(PRICING.monthly.amount * 12 - PRICING.yearly.amount).toFixed(0)} vs monthly
                </div>
                <ul className="space-y-2 text-sm">
                  <li className="flex items-center gap-2">
                    <Check className="h-4 w-4 text-success" />
                    7-day free trial
                  </li>
                  <li className="flex items-center gap-2">
                    <Check className="h-4 w-4 text-success" />
                    Cancel anytime
                  </li>
                  <li className="flex items-center gap-2">
                    <Check className="h-4 w-4 text-success" />
                    Priority support
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>

          {/* Feature Comparison */}
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-center mb-6">What's Included</h2>
            <FeatureComparisonTable onUpgrade={handleSubscribe} />
          </div>

          {/* CTA */}
          <Card className="bg-gradient-to-br from-primary/5 to-primary/10 border-primary/20">
            <CardContent className="pt-6">
              <div className="text-center">
                <h3 className="text-xl font-semibold mb-2">
                  Start Your {PRICING.trialDays}-Day Free Trial
                </h3>
                <p className="text-muted-foreground mb-6">
                  No credit card required • Cancel anytime • Upgrade when ready
                </p>

                <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                  <Button
                    size="lg"
                    onClick={handleSubscribe}
                    disabled={isLoading}
                    className="min-w-[200px]"
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        Starting Trial...
                      </>
                    ) : (
                      <>
                        <Crown className="h-4 w-4 mr-2" />
                        Start Free Trial
                      </>
                    )}
                  </Button>

                  <Button
                    variant="outline"
                    size="lg"
                    onClick={() => navigate('/settings')}
                  >
                    Maybe Later
                  </Button>
                </div>

                <p className="text-xs text-muted-foreground mt-4">
                  By subscribing, you agree to our Terms of Service and Privacy Policy.
                  Your payment information is processed securely by Stripe.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

