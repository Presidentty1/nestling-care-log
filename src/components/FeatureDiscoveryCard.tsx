import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { X, ArrowRight } from 'lucide-react';
import { MESSAGING, getFeatureIntroMessage } from '@/lib/messaging';
import { useNavigate } from 'react-router-dom';

interface FeatureDiscoveryCardProps {
  featureKey: keyof typeof MESSAGING.features;
  onDismiss: () => void;
  onTryIt?: () => void;
}

export function FeatureDiscoveryCard({
  featureKey,
  onDismiss,
  onTryIt,
}: FeatureDiscoveryCardProps) {
  const navigate = useNavigate();
  const feature = getFeatureIntroMessage(featureKey);

  const handleTryIt = () => {
    if (onTryIt) {
      onTryIt();
    } else {
      // Default navigation based on feature key
      const routes: Record<string, string> = {
        predictions: '/predictions',
        history: '/history',
        analytics: '/analytics',
        aiAssistant: '/ai-assistant',
        cryInsights: '/cry-insights',
        insights: '/patterns',
      };
      const route = routes[featureKey];
      if (route) {
        navigate(route);
      }
    }
  };

  return (
    <Card className='border-2 border-primary/30 bg-gradient-to-br from-primary/5 to-primary/10 animate-fade-in'>
      <CardContent className='p-4'>
        <div className='flex items-start gap-3'>
          <div className='flex-1 min-w-0'>
            <div className='flex items-start justify-between gap-2 mb-2'>
              <h4 className='font-semibold text-base'>✨ New: {feature.title}</h4>
              <Button
                variant='ghost'
                size='sm'
                onClick={onDismiss}
                className='h-6 w-6 p-0 shrink-0 -mr-1 -mt-1'
              >
                <X className='h-4 w-4' />
              </Button>
            </div>
            <p className='text-sm text-muted-foreground mb-3 leading-relaxed'>
              {feature.description}
            </p>
            <div className='flex gap-2'>
              <Button size='sm' onClick={handleTryIt} className='flex items-center gap-1'>
                {MESSAGING.cta.tryIt}
                <ArrowRight className='h-4 w-4' />
              </Button>
              <Button size='sm' variant='ghost' onClick={onDismiss}>
                Maybe Later
              </Button>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

