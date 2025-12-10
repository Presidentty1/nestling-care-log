import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { authService } from '@/services/authService';
import { babyService } from '@/services/babyService';
import { napPredictorService } from '@/services/napPredictorService';
import { BabySelector } from '@/components/BabySelector';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { Clock, TrendingUp, RefreshCw, Baby as BabyIcon } from 'lucide-react';
import { Baby } from '@/lib/types';
import { format, formatDistanceToNow } from 'date-fns';
import { LoadingCard } from '@/components/common/LoadingSpinner';
import { EmptyState } from '@/components/common/EmptyState';
import { ErrorState } from '@/components/common/ErrorState';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';

export default function NapPredictor() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  const {
    data: prediction,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ['nap-prediction', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return null;
      return await napPredictorService.calculateNapWindow(selectedBabyId);
    },
    enabled: !!selectedBabyId,
    retry: 2,
  });

  const refreshMutation = useMutation({
    mutationFn: async () => {
      if (!selectedBabyId) return;
      return await napPredictorService.calculateNapWindow(selectedBabyId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nap-prediction'] });
      toast({ title: 'Prediction updated' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to update prediction',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'text-green-600';
    if (confidence >= 0.6) return 'text-yellow-600';
    return 'text-orange-600';
  };

  const getConfidenceLabel = (confidence: number) => {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  };

  return (
    <div className='min-h-screen bg-background p-4 pb-20'>
      <div className='max-w-2xl mx-auto space-y-6'>
        <div className='flex items-center justify-between'>
          <h1 className='text-3xl font-bold'>Nap Window Predictor</h1>
          <BabySelector
            babies={babies || []}
            selectedBabyId={selectedBabyId}
            onSelect={setSelectedBabyId}
          />
        </div>

        <MedicalDisclaimer variant='sleep' />

        {!selectedBabyId && (
          <EmptyState
            icon={BabyIcon}
            title='Ready to predict naps?'
            description='Select a baby above to see their personalized nap window predictions based on their sleep patterns.'
          />
        )}

        {selectedBabyId && isLoading && <LoadingCard text='Analyzing sleep patterns...' />}

        {selectedBabyId && error && (
          <ErrorState
            title="Can't load predictions right now"
            message="We're having trouble analyzing the nap window. This happens sometimes—give it another try."
            onRetry={() => refetch()}
          />
        )}

        {selectedBabyId && prediction && (
          <div className='space-y-4'>
            <Card className='p-6'>
              <div className='flex items-center justify-between mb-4'>
                <h2 className='text-xl font-semibold flex items-center gap-2'>
                  <Clock className='w-5 h-5' />
                  Next Nap Window
                </h2>
                <Button
                  variant='outline'
                  size='sm'
                  onClick={() => refreshMutation.mutate()}
                  disabled={refreshMutation.isPending}
                >
                  <RefreshCw
                    className={`w-4 h-4 ${refreshMutation.isPending ? 'animate-spin' : ''}`}
                  />
                </Button>
              </div>

              <div className='space-y-4'>
                <div>
                  <p className='text-sm text-muted-foreground'>Last Wake Time</p>
                  <p className='text-lg font-medium'>
                    {format(new Date(prediction.lastWakeTime), 'h:mm a')}
                    <span className='text-sm text-muted-foreground ml-2'>
                      ({formatDistanceToNow(new Date(prediction.lastWakeTime), { addSuffix: true })}
                      )
                    </span>
                  </p>
                </div>

                <div className='border-t pt-4'>
                  <p className='text-sm text-muted-foreground mb-2'>Optimal Nap Window</p>
                  <div className='flex items-center justify-between'>
                    <div>
                      <p className='text-2xl font-bold'>
                        {format(new Date(prediction.napWindowStart), 'h:mm a')}
                      </p>
                      <p className='text-xs text-muted-foreground'>Start</p>
                    </div>
                    <div className='text-center'>
                      <TrendingUp className='w-6 h-6 mx-auto text-muted-foreground' />
                    </div>
                    <div>
                      <p className='text-2xl font-bold'>
                        {format(new Date(prediction.napWindowEnd), 'h:mm a')}
                      </p>
                      <p className='text-xs text-muted-foreground'>End</p>
                    </div>
                  </div>
                </div>

                <div className='border-t pt-4'>
                  <div className='flex items-center justify-between'>
                    <p className='text-sm text-muted-foreground'>Confidence</p>
                    <p className={`font-semibold ${getConfidenceColor(prediction.confidence)}`}>
                      {getConfidenceLabel(prediction.confidence)} (
                      {Math.round(prediction.confidence * 100)}%)
                    </p>
                  </div>
                </div>

                <div className='bg-muted p-4 rounded-lg'>
                  <p className='text-sm'>
                    Based on your baby's age, the recommended wake window is{' '}
                    <strong>
                      {prediction.wakeWindowMin}-{prediction.wakeWindowMax} minutes
                    </strong>
                    . This prediction improves as you log more sleep data.
                  </p>
                </div>
              </div>
            </Card>

            <Card className='p-6'>
              <h3 className='font-semibold mb-4'>Tips for Success</h3>
              <ul className='space-y-2 text-sm text-muted-foreground'>
                <li>• Watch for sleep cues like yawning, rubbing eyes, or fussiness</li>
                <li>• Start your nap routine 10-15 minutes before the window</li>
                <li>• Keep the environment dark, quiet, and comfortable</li>
                <li>• If baby doesn't fall asleep within 20 minutes, try again later</li>
              </ul>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
