import { Check, X, Lock } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

interface Feature {
  name: string;
  free: boolean;
  premium: boolean;
}

const FEATURES: Feature[] = [
  { name: 'Unlimited event logging', free: true, premium: true },
  { name: 'Timeline & history view', free: true, premium: true },
  { name: 'Multi-device sync', free: true, premium: true },
  { name: 'Basic analytics', free: true, premium: true },
  { name: 'AI Nap Predictor', free: false, premium: true },
  { name: 'AI Cry Analysis', free: false, premium: true },
  { name: 'Smart reminders', free: false, premium: true },
  { name: 'AI Assistant chat', free: false, premium: true },
  { name: 'Weekly insights reports', free: false, premium: true },
  { name: 'Growth tracking', free: false, premium: true },
];

interface FeatureComparisonTableProps {
  onUpgrade?: () => void;
}

export function FeatureComparisonTable({ onUpgrade }: FeatureComparisonTableProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Compare Plans</CardTitle>
        <CardDescription>Choose the plan that works best for you</CardDescription>
      </CardHeader>
      <CardContent>
        <div className='grid grid-cols-3 gap-4'>
          {/* Header */}
          <div className='font-semibold text-sm'>Feature</div>
          <div className='text-center'>
            <Badge variant='outline'>Free</Badge>
          </div>
          <div className='text-center'>
            <Badge className='bg-gradient-to-r from-primary to-primary/80'>Premium</Badge>
          </div>

          {/* Features */}
          {FEATURES.map(feature => (
            <>
              <div className='text-sm py-2 border-t'>{feature.name}</div>
              <div className='flex justify-center items-center py-2 border-t'>
                {feature.free ? (
                  <Check className='h-5 w-5 text-success' />
                ) : (
                  <X className='h-5 w-5 text-muted-foreground' />
                )}
              </div>
              <div className='flex justify-center items-center py-2 border-t'>
                {feature.premium ? (
                  <Check className='h-5 w-5 text-success' />
                ) : (
                  <X className='h-5 w-5 text-muted-foreground' />
                )}
              </div>
            </>
          ))}
        </div>

        {onUpgrade && (
          <div className='mt-6 pt-6 border-t'>
            <Button onClick={onUpgrade} className='w-full' size='lg'>
              <Lock className='h-4 w-4 mr-2' />
              Upgrade to Premium
            </Button>
            <p className='text-xs text-center text-muted-foreground mt-2'>
              14-day free trial • Cancel anytime
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
