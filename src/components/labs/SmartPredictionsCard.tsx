import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Clock, TrendingUp, Brain, AlertCircle } from 'lucide-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/hooks/useAuth';
import { useAppStore } from '@/store/appStore';
import { eventsService } from '@/services/eventsService';
import { napPredictorService } from '@/services/napPredictorService';
import { toast } from 'sonner';

interface PredictionStatus {
  isEnabled: boolean;
  learningProgress: number; // 0-1
  daysOfData: number;
  nextNapPrediction?: {
    time: Date;
    confidence: number;
  };
  nextFeedPrediction?: {
    time: Date;
    confidence: number;
  };
}

export function SmartPredictionsCard() {
  const { user } = useAuth();
  const { activeBabyId } = useAppStore();
  const queryClient = useQueryClient();

  const [isEnabled, setIsEnabled] = useState(false);

  // Load current settings
  useEffect(() => {
    const saved = localStorage.getItem('smartPredictionsEnabled');
    setIsEnabled(saved === 'true');
  }, []);

  // Get prediction status
  const { data: status, isLoading } = useQuery({
    queryKey: ['smart-predictions-status', activeBabyId],
    queryFn: async (): Promise<PredictionStatus> => {
      if (!activeBabyId) {
        return {
          isEnabled,
          learningProgress: 0,
          daysOfData: 0
        };
      }

      // Get events from the last 7 days
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const events = await eventsService.getEventsByRange(
        activeBabyId,
        sevenDaysAgo.toISOString(),
        new Date().toISOString()
      );

      // Calculate learning progress (need at least 3 days of data)
      const uniqueDays = new Set(
        events.map(event => new Date(event.start_time).toDateString())
      ).size;

      const learningProgress = Math.min(uniqueDays / 5, 1); // Need 5 days for full learning

      // Get current predictions
      const predictions = await napPredictorService.getPredictions(activeBabyId);

      return {
        isEnabled,
        learningProgress,
        daysOfData: uniqueDays,
        nextNapPrediction: predictions?.nextNap ? {
          time: predictions.nextNap.predictedTime,
          confidence: predictions.nextNap.confidence
        } : undefined,
        nextFeedPrediction: predictions?.nextFeed ? {
          time: predictions.nextFeed.predictedTime,
          confidence: predictions.nextFeed.confidence
        } : undefined
      };
    },
    enabled: !!activeBabyId,
    refetchInterval: isEnabled ? 5 * 60 * 1000 : false, // Refetch every 5 minutes when enabled
  });

  // Toggle mutation
  const toggleMutation = useMutation({
    mutationFn: async (enabled: boolean) => {
      localStorage.setItem('smartPredictionsEnabled', enabled.toString());
      setIsEnabled(enabled);

      if (enabled && activeBabyId) {
        // Generate initial predictions
        await napPredictorService.generatePredictions(activeBabyId);
        queryClient.invalidateQueries({ queryKey: ['smart-predictions-status'] });
      }
    },
    onSuccess: () => {
      toast.success(isEnabled ? 'Smart Predictions disabled' : 'Smart Predictions enabled');
    },
    onError: () => {
      toast.error('Failed to update Smart Predictions setting');
    }
  });

  const handleToggle = (enabled: boolean) => {
    toggleMutation.mutate(enabled);
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Label htmlFor="smart-predictions" className="font-medium">
            Enable Smart Predictions
          </Label>
          <div className="h-6 w-11 bg-muted rounded-full animate-pulse" />
        </div>
        <div className="text-sm text-muted-foreground">
          Loading prediction status...
        </div>
      </div>
    );
  }

  const currentStatus = status || {
    isEnabled,
    learningProgress: 0,
    daysOfData: 0
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Label htmlFor="smart-predictions" className="font-medium">
          Enable Smart Predictions
        </Label>
        <Switch
          id="smart-predictions"
          checked={currentStatus.isEnabled}
          onCheckedChange={handleToggle}
          disabled={toggleMutation.isPending}
        />
      </div>

      {!currentStatus.isEnabled ? (
        <div className="bg-muted/50 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-muted-foreground mt-0.5" />
            <div className="space-y-2">
              <p className="text-sm font-medium">Smart Predictions are disabled</p>
              <p className="text-sm text-muted-foreground">
                Enable to see personalized nap and feed time predictions based on your baby's patterns.
              </p>
            </div>
          </div>
        </div>
      ) : currentStatus.learningProgress < 1 ? (
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Brain className="h-4 w-4 text-primary" />
            <span className="text-sm font-medium">Learning your baby's patterns...</span>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Progress</span>
              <span>{Math.round(currentStatus.learningProgress * 100)}%</span>
            </div>
            <div className="w-full bg-muted rounded-full h-2">
              <div
                className="bg-primary h-2 rounded-full transition-all duration-500"
                style={{ width: `${currentStatus.learningProgress * 100}%` }}
              />
            </div>
            <p className="text-xs text-muted-foreground">
              {currentStatus.daysOfData} day{currentStatus.daysOfData !== 1 ? 's' : ''} of data logged.
              Need 5+ days for accurate predictions.
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <TrendingUp className="h-4 w-4 text-success" />
            <span className="text-sm font-medium text-success">Active - Learning from your data</span>
          </div>

          {(currentStatus.nextNapPrediction || currentStatus.nextFeedPrediction) && (
            <div className="space-y-3">
              {currentStatus.nextNapPrediction && (
                <Card className="border-primary/20">
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-primary" />
                        <span className="text-sm font-medium">Next Nap</span>
                      </div>
                      <Badge variant="outline" className="text-xs">
                        {Math.round(currentStatus.nextNapPrediction.confidence * 100)}% confident
                      </Badge>
                    </div>
                    <p className="text-lg font-bold mt-1">
                      {currentStatus.nextNapPrediction.time.toLocaleTimeString([], {
                        hour: 'numeric',
                        minute: '2-digit'
                      })}
                    </p>
                  </CardContent>
                </Card>
              )}

              {currentStatus.nextFeedPrediction && (
                <Card className="border-primary/20">
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-primary" />
                        <span className="text-sm font-medium">Next Feed</span>
                      </div>
                      <Badge variant="outline" className="text-xs">
                        {Math.round(currentStatus.nextFeedPrediction.confidence * 100)}% confident
                      </Badge>
                    </div>
                    <p className="text-lg font-bold mt-1">
                      {currentStatus.nextFeedPrediction.time.toLocaleTimeString([], {
                        hour: 'numeric',
                        minute: '2-digit'
                      })}
                    </p>
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          <div className="text-xs text-muted-foreground">
            Based on {currentStatus.daysOfData} days of your baby's data.
            Predictions update automatically as you log more events.
          </div>
        </div>
      )}
    </div>
  );
}

