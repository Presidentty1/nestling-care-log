import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  Crown,
  Calendar,
  CreditCard,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Loader2,
} from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { subscriptionService } from '@/services/subscriptionService';
import { format } from 'date-fns';
import { toast } from 'sonner';

export default function SubscriptionManagement() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [subscriptionStatus, setSubscriptionStatus] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);

  useEffect(() => {
    if (user) {
      loadSubscriptionStatus();
    }
  }, [user]);

  const loadSubscriptionStatus = async () => {
    if (!user) return;

    try {
      const status = await subscriptionService.getSubscriptionStatus(user.id);
      setSubscriptionStatus(status);
    } catch (error) {
      console.error('Failed to load subscription status:', error);
      toast.error('Failed to load subscription details');
    } finally {
      setIsLoading(false);
    }
  };

  const handleManageBilling = async () => {
    if (!user) return;

    setIsUpdating(true);
    try {
      const result = await subscriptionService.createPortalSession(user.id);
      if (result?.url) {
        window.location.href = result.url;
      } else {
        toast.error('Failed to open billing portal');
      }
    } catch (error) {
      console.error('Billing portal error:', error);
      toast.error('Failed to open billing management');
    } finally {
      setIsUpdating(false);
    }
  };

  const handleCancelSubscription = async () => {
    if (!user) return;

    if (
      !confirm(
        'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.'
      )
    ) {
      return;
    }

    setIsUpdating(true);
    try {
      const success = await subscriptionService.cancelSubscription(user.id);
      if (success) {
        toast.success(
          'Subscription cancelled. You will keep premium access until the end of your billing period.'
        );
        await loadSubscriptionStatus();
      } else {
        toast.error('Failed to cancel subscription');
      }
    } catch (error) {
      console.error('Cancel subscription error:', error);
      toast.error('Failed to cancel subscription');
    } finally {
      setIsUpdating(false);
    }
  };

  const handleReactivateSubscription = async () => {
    if (!user) return;

    setIsUpdating(true);
    try {
      const success = await subscriptionService.reactivateSubscription(user.id);
      if (success) {
        toast.success('Subscription reactivated successfully');
        await loadSubscriptionStatus();
      } else {
        toast.error('Failed to reactivate subscription');
      }
    } catch (error) {
      console.error('Reactivate subscription error:', error);
      toast.error('Failed to reactivate subscription');
    } finally {
      setIsUpdating(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'trialing':
        return <Badge variant='secondary'>Free Trial</Badge>;
      case 'active':
        return <Badge className='bg-success'>Active</Badge>;
      case 'past_due':
        return <Badge variant='destructive'>Past Due</Badge>;
      case 'canceled':
        return <Badge variant='outline'>Canceled</Badge>;
      default:
        return <Badge variant='outline'>{status}</Badge>;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'trialing':
      case 'active':
        return <CheckCircle className='h-5 w-5 text-success' />;
      case 'past_due':
        return <AlertTriangle className='h-5 w-5 text-warning' />;
      case 'canceled':
        return <XCircle className='h-5 w-5 text-muted-foreground' />;
      default:
        return <CreditCard className='h-5 w-5 text-muted-foreground' />;
    }
  };

  if (isLoading) {
    return (
      <div className='min-h-screen bg-background flex items-center justify-center'>
        <Loader2 className='h-8 w-8 animate-spin' />
      </div>
    );
  }

  const isPremium = subscriptionStatus?.tier === 'premium';
  const isCanceled = subscriptionStatus?.cancelAtPeriodEnd;

  return (
    <div className='min-h-screen bg-background'>
      <div className='container mx-auto px-4 py-8'>
        <div className='max-w-2xl mx-auto'>
          {/* Header */}
          <div className='flex items-center gap-3 mb-8'>
            <Crown className='h-8 w-8 text-primary' />
            <div>
              <h1 className='text-3xl font-bold'>Subscription</h1>
              <p className='text-muted-foreground'>Manage your Nuzzle Premium subscription</p>
            </div>
          </div>

          {/* Current Plan */}
          <Card className='mb-6'>
            <CardHeader>
              <div className='flex items-center justify-between'>
                <div>
                  <CardTitle className='flex items-center gap-2'>
                    {isPremium ? 'Nuzzle Premium' : 'Free Plan'}
                    {subscriptionStatus && getStatusBadge(subscriptionStatus.status)}
                  </CardTitle>
                  <CardDescription>
                    {isPremium
                      ? 'You have access to all premium features'
                      : 'Upgrade to unlock AI-powered features'}
                  </CardDescription>
                </div>
                {subscriptionStatus && getStatusIcon(subscriptionStatus.status)}
              </div>
            </CardHeader>

            {isPremium && subscriptionStatus && (
              <CardContent>
                <div className='space-y-4'>
                  <div className='flex items-center justify-between text-sm'>
                    <span className='text-muted-foreground'>Current period ends</span>
                    <span className='font-medium'>
                      {subscriptionStatus.currentPeriodEnd
                        ? format(new Date(subscriptionStatus.currentPeriodEnd), 'MMM d, yyyy')
                        : 'Unknown'}
                    </span>
                  </div>

                  {subscriptionStatus.trialEnd && (
                    <div className='flex items-center justify-between text-sm'>
                      <span className='text-muted-foreground'>Trial ends</span>
                      <span className='font-medium'>
                        {format(new Date(subscriptionStatus.trialEnd), 'MMM d, yyyy')}
                      </span>
                    </div>
                  )}

                  {isCanceled && (
                    <Alert>
                      <AlertTriangle className='h-4 w-4' />
                      <AlertDescription>
                        Your subscription will end on{' '}
                        {subscriptionStatus.currentPeriodEnd
                          ? format(new Date(subscriptionStatus.currentPeriodEnd), 'MMM d, yyyy')
                          : 'the end of your current period'}
                        . You can reactivate at any time before then.
                      </AlertDescription>
                    </Alert>
                  )}
                </div>
              </CardContent>
            )}
          </Card>

          {/* Actions */}
          <div className='space-y-4'>
            {isPremium ? (
              <>
                <Button
                  onClick={handleManageBilling}
                  disabled={isUpdating}
                  className='w-full'
                  size='lg'
                >
                  {isUpdating ? (
                    <>
                      <Loader2 className='h-4 w-4 mr-2 animate-spin' />
                      Loading...
                    </>
                  ) : (
                    <>
                      <CreditCard className='h-4 w-4 mr-2' />
                      Manage Billing & Payment
                    </>
                  )}
                </Button>

                {isCanceled ? (
                  <Button
                    variant='outline'
                    onClick={handleReactivateSubscription}
                    disabled={isUpdating}
                    className='w-full'
                  >
                    {isUpdating ? (
                      <>
                        <Loader2 className='h-4 w-4 mr-2 animate-spin' />
                        Reactivating...
                      </>
                    ) : (
                      'Reactivate Subscription'
                    )}
                  </Button>
                ) : (
                  <Button
                    variant='outline'
                    onClick={handleCancelSubscription}
                    disabled={isUpdating}
                    className='w-full'
                  >
                    {isUpdating ? (
                      <>
                        <Loader2 className='h-4 w-4 mr-2 animate-spin' />
                        Cancelling...
                      </>
                    ) : (
                      'Cancel Subscription'
                    )}
                  </Button>
                )}
              </>
            ) : (
              <Button onClick={() => navigate('/subscription')} className='w-full' size='lg'>
                <Crown className='h-4 w-4 mr-2' />
                Upgrade to Premium
              </Button>
            )}

            <Button variant='ghost' onClick={() => navigate('/settings')} className='w-full'>
              Back to Settings
            </Button>
          </div>

          {/* Help */}
          <div className='mt-8 text-center'>
            <p className='text-sm text-muted-foreground'>
              Need help? Contact us at{' '}
              <a href='mailto:support@nuzzle.app' className='text-primary hover:underline'>
                support@nuzzle.app
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
