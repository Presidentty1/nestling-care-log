import { useState, useEffect } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { Baby } from '@/lib/types';
import { authService } from '@/services/authService';
import { familyService } from '@/services/familyService';
import { eventsService } from '@/services/eventsService';
import { cryLogsService } from '@/services/cryLogsService';
import { cryAnalysisService } from '@/services/cryAnalysisService';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { Play, Square, Loader2 } from 'lucide-react';
import { validateCryLog } from '@/services/validation';

interface CryTimerProps {
  baby: Baby;
}

export function CryTimer({ baby }: CryTimerProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [isTracking, setIsTracking] = useState(false);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [note, setNote] = useState('');
  const [analysis, setAnalysis] = useState<any>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTracking && startTime) {
      interval = setInterval(() => {
        setElapsedSeconds(Math.floor((Date.now() - startTime.getTime()) / 1000));
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isTracking, startTime]);

  const analyzeCryMutation = useMutation({
    mutationFn: async () => {
      const user = await authService.getUser();
      if (!user) throw new Error('Not authenticated');

      const familyMember = await familyService.getUserFamilyMembership(user.id);
      if (!familyMember) throw new Error('Family not found');

      // Get recent events for context
      const recentEvents = await eventsService.getEvents({
        babyId: baby.id,
        startTime: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
      });

      const now = new Date();
      const timeOfDay = now.getHours();

      // Calculate time since last feed
      const lastFeed = recentEvents?.find(e => e.type === 'feed');
      const timeSinceLastFeed = lastFeed
        ? Math.floor((Date.now() - new Date(lastFeed.start_time).getTime()) / (1000 * 60))
        : 999;

      // Calculate last sleep duration
      const lastSleep = recentEvents?.find(e => e.type === 'sleep' && e.end_time);
      const lastSleepDuration =
        lastSleep && lastSleep.end_time
          ? Math.floor(
              (new Date(lastSleep.end_time).getTime() - new Date(lastSleep.start_time).getTime()) /
                (1000 * 60)
            )
          : 0;

      return await cryAnalysisService.analyzeCryPattern({
        babyId: baby.id,
        recentEvents: recentEvents?.slice(0, 5) || [],
        timeOfDay,
        timeSinceLastFeed,
        lastSleepDuration,
      });
    },
    onSuccess: data => {
      setAnalysis(data);
      setIsAnalyzing(false);
    },
    onError: error => {
      console.error('Analysis error:', error);
      toast({
        title: 'Analysis Failed',
        description: 'Could not analyze cry pattern. Please try again.',
        variant: 'destructive',
      });
      setIsAnalyzing(false);
    },
  });

  const saveCryLogMutation = useMutation({
    mutationFn: async (resolvedBy: string) => {
      const user = await authService.getUser();
      if (!user) throw new Error('Not authenticated');

      const familyMember = await familyService.getUserFamilyMembership(user.id);
      if (!familyMember) throw new Error('Family not found');

      const cryLogData = {
        baby_id: baby.id,
        family_id: familyMember.family_id,
        start_time: startTime!.toISOString(),
        end_time: new Date().toISOString(),
        cry_type: analysis?.possibleCauses?.[0]?.cause || 'unknown',
        confidence: analysis?.possibleCauses?.[0]?.confidence || 0,
        resolved_by: resolvedBy,
        note: note || null,
        context: analysis,
      };

      const validationResult = validateCryLog(cryLogData);
      if (!validationResult.success) {
        throw new Error(validationResult.error.issues[0].message);
      }

      await cryLogsService.createCryLog(baby.id, validationResult.data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cry-logs'] });
      toast({ title: 'Cry log saved successfully' });
      resetTimer();
    },
    onError: error => {
      console.error('Save error:', error);
      toast({
        title: 'Failed to save',
        description: 'Could not save cry log. Please try again.',
        variant: 'destructive',
      });
    },
  });

  const startTracking = () => {
    setStartTime(new Date());
    setIsTracking(true);
    setElapsedSeconds(0);
    setAnalysis(null);
  };

  const stopTracking = () => {
    setIsTracking(false);
    setIsAnalyzing(true);
    analyzeCryMutation.mutate();
  };

  const resetTimer = () => {
    setIsTracking(false);
    setStartTime(null);
    setElapsedSeconds(0);
    setNote('');
    setAnalysis(null);
    setIsAnalyzing(false);
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className='space-y-4'>
      <Card className='p-6'>
        <div className='text-center space-y-4'>
          <div className='text-5xl font-bold font-mono'>{formatTime(elapsedSeconds)}</div>

          {!isTracking && !startTime && (
            <Button onClick={startTracking} size='lg' className='w-full'>
              <Play className='mr-2 h-5 w-5' />
              Start Cry Timer
            </Button>
          )}

          {isTracking && (
            <Button onClick={stopTracking} size='lg' variant='destructive' className='w-full'>
              <Square className='mr-2 h-5 w-5' />
              Stop & Analyze
            </Button>
          )}
        </div>
      </Card>

      {isAnalyzing && (
        <Card className='p-6 text-center'>
          <Loader2 className='h-8 w-8 animate-spin mx-auto mb-2' />
          <p className='text-muted-foreground'>Analyzing cry pattern...</p>
        </Card>
      )}

      {analysis && !isTracking && (
        <Card className='p-6 space-y-4'>
          <h3 className='font-semibold text-lg'>Analysis Results</h3>

          <div>
            <Label className='text-sm font-medium'>Possible Causes</Label>
            <div className='space-y-2 mt-2'>
              {analysis.possibleCauses?.map((cause: any, idx: number) => (
                <div key={idx} className='flex justify-between items-center p-2 bg-muted rounded'>
                  <span className='capitalize'>{cause.cause}</span>
                  <span className='text-sm text-muted-foreground'>{cause.confidence}%</span>
                </div>
              ))}
            </div>
          </div>

          <div>
            <Label className='text-sm font-medium'>Suggestions</Label>
            <ul className='list-disc list-inside space-y-1 mt-2 text-sm'>
              {analysis.suggestions?.map((suggestion: string, idx: number) => (
                <li key={idx}>{suggestion}</li>
              ))}
            </ul>
          </div>

          {analysis.reasoning && (
            <div>
              <Label className='text-sm font-medium'>Reasoning</Label>
              <p className='text-sm text-muted-foreground mt-1'>{analysis.reasoning}</p>
            </div>
          )}

          <div>
            <Label htmlFor='note'>Notes (optional)</Label>
            <Textarea
              id='note'
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder='What helped calm the baby?'
              className='mt-1'
            />
          </div>

          <div className='space-y-2'>
            <Label className='text-sm font-medium'>How was it resolved?</Label>
            <div className='grid grid-cols-2 gap-2'>
              <Button onClick={() => saveCryLogMutation.mutate('feeding')} variant='outline'>
                Feeding
              </Button>
              <Button onClick={() => saveCryLogMutation.mutate('sleep')} variant='outline'>
                Sleep
              </Button>
              <Button onClick={() => saveCryLogMutation.mutate('diaper change')} variant='outline'>
                Diaper
              </Button>
              <Button onClick={() => saveCryLogMutation.mutate('comfort')} variant='outline'>
                Comfort
              </Button>
            </div>
          </div>

          <Button onClick={resetTimer} variant='ghost' className='w-full'>
            Cancel
          </Button>
        </Card>
      )}
    </div>
  );
}
