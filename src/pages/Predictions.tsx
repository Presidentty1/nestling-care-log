import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type { Baby } from '@/lib/types';
import { babyService } from '@/services/babyService';
import { predictionsService } from '@/services/predictionsService';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BabySelector } from '@/components/BabySelector';
import { MobileNav } from '@/components/MobileNav';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { ArrowLeft, TrendingUp, Loader2, Sparkles } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';
import { format } from 'date-fns';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle, Settings } from 'lucide-react';
import { aiPreferencesService } from '@/services/aiPreferencesService';
import { useAuth } from '@/hooks/useAuth';

export default function Predictions() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);

  const { data: aiEnabled } = useQuery({
    queryKey: ['ai-preferences', user?.id],
    queryFn: async () => {
      if (!user) return false;
      return await aiPreferencesService.canUseAI(user.id);
    },
    enabled: !!user,
  });

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  const { data: predictions } = useQuery({
    queryKey: ['predictions', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return [];
      return await predictionsService.getPredictions(selectedBaby.id, 10);
    },
    enabled: !!selectedBaby,
  });

  const generatePredictionMutation = useMutation({
    mutationFn: async (predictionType: string) => {
      if (!selectedBaby) throw new Error('No baby selected');
      if (aiEnabled === false) {
        throw new Error('AI_DATA_SHARING_DISABLED');
      }
      
      return await predictionsService.generatePrediction(selectedBaby.id, predictionType);
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['predictions', selectedBaby?.id] });
      toast({
        title: 'Prediction Generated',
        description: 'New prediction added successfully',
      });
    },
    onError: (error: any) => {
      console.error('Prediction error:', error);
      
      let errorTitle = 'Prediction Unavailable';
      let errorMessage = 'Please try again later';
      
      // Handle specific error cases
      if (error?.message === 'AI_DATA_SHARING_DISABLED') {
        errorTitle = 'AI Features Disabled';
        errorMessage = 'Enable AI Data Sharing in Settings to use predictions';
      } else if (error?.message === 'FUNCTION_NOT_FOUND' || error?.message?.includes('404') || error?.message?.includes('FunctionsRelayError')) {
        errorTitle = 'Feature Coming Soon';
        errorMessage = 'Smart Predictions are still in development. This feature will be available soon!';
      } else if (error?.message) {
        errorMessage = error.message;
      }
      
      toast({
        title: errorTitle,
        description: errorMessage,
        variant: 'destructive',
      });
    },
  });

  if (babies && babies.length > 0 && !selectedBaby) {
    setSelectedBaby(babies[0]);
  }

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'bg-green-500';
    if (confidence >= 0.6) return 'bg-yellow-500';
    return 'bg-orange-500';
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center gap-4 mb-4">
            <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                Smart Predictions
                <Badge variant="secondary">Suggestion</Badge>
              </h1>
              <p className="text-sm text-muted-foreground">AI-powered suggestions based on your baby's patterns</p>
            </div>
          </div>
          {babies && babies.length > 0 && (
            <BabySelector
              babies={babies}
              selectedBabyId={selectedBaby?.id || null}
              onSelect={(babyId) => {
                const baby = babies.find(b => b.id === babyId);
                if (baby) setSelectedBaby(baby);
              }}
            />
          )}
        </div>
      </div>

      <div className="container mx-auto p-4 space-y-4 max-w-2xl">
        <MedicalDisclaimer variant="predictions" />

        {aiEnabled === false && (
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription className="flex items-center justify-between">
              <span>AI predictions are disabled. Enable in Settings to use this feature.</span>
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={() => navigate('/settings/ai-data-sharing')}
                className="ml-2"
              >
                <Settings className="h-4 w-4 mr-1" />
                Settings
              </Button>
            </AlertDescription>
          </Alert>
        )}

        {aiEnabled !== false && (
          <div className="grid grid-cols-2 gap-3">
            <Button
              onClick={() => generatePredictionMutation.mutate('next_feed')}
              disabled={generatePredictionMutation.isPending || !selectedBaby}
              variant="outline"
              className="h-auto py-4"
            >
              {generatePredictionMutation.isPending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Generating...
                </>
              ) : (
                <>
                  <TrendingUp className="mr-2 h-4 w-4" />
                  Predict Next Feed
                </>
              )}
            </Button>
            <Button
              onClick={() => generatePredictionMutation.mutate('next_nap')}
              disabled={generatePredictionMutation.isPending || !selectedBaby}
              variant="outline"
              className="h-auto py-4"
            >
              {generatePredictionMutation.isPending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Generating...
                </>
              ) : (
                <>
                  <Sparkles className="mr-2 h-4 w-4" />
                  Predict Next Nap
                </>
              )}
            </Button>
          </div>
        )}

        {predictions && predictions.length > 0 ? (
          predictions.map((prediction: any) => (
            <Card key={prediction.id} className="p-4">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <Badge className="mb-2 capitalize">
                    {prediction.prediction_type.replace('_', ' ')}
                  </Badge>
                  <p className="text-sm text-muted-foreground">
                    {format(new Date(prediction.predicted_at), 'PPp')}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${getConfidenceColor(prediction.confidence_score)}`} />
                  <span className="text-xs text-muted-foreground">
                    {Math.round(prediction.confidence_score * 100)}%
                  </span>
                </div>
              </div>

              {prediction.prediction_data && (
                <div className="space-y-2">
                  {prediction.prediction_data.nextFeedTime && (
                    <p className="text-sm">
                      <strong>Predicted time:</strong>{' '}
                      {format(new Date(prediction.prediction_data.nextFeedTime), 'p')}
                    </p>
                  )}
                  {prediction.prediction_data.nextNapTime && (
                    <p className="text-sm">
                      <strong>Predicted nap:</strong>{' '}
                      {format(new Date(prediction.prediction_data.nextNapTime), 'p')}
                    </p>
                  )}
                  {prediction.prediction_data.avgInterval && (
                    <p className="text-sm">
                      <strong>Avg interval:</strong>{' '}
                      {prediction.prediction_data.avgInterval} hours
                    </p>
                  )}
                </div>
              )}

              {prediction.was_accurate !== null && (
                <Badge variant={prediction.was_accurate ? 'default' : 'secondary'} className="mt-2">
                  {prediction.was_accurate ? 'Accurate ✓' : 'Inaccurate'}
                </Badge>
              )}
            </Card>
          ))
        ) : (
          <Card className="p-8 text-center">
            <Sparkles className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">No predictions yet</p>
            <p className="text-sm text-muted-foreground mt-2">
              Generate predictions to see AI-powered insights
            </p>
          </Card>
        )}
      </div>

      <MobileNav />
    </div>
  );
}