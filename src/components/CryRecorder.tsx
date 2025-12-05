import { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Mic, Square, Loader2, AlertCircle, Lock } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { usePro } from '@/hooks/usePro';
import { trialService } from '@/services/trialService';

interface CryRecorderProps {
  babyId: string;
  onAnalysisComplete: (result: any) => void;
}

export function CryRecorder({ babyId, onAnalysisComplete }: CryRecorderProps) {
  const { isPro } = usePro();
  const [isRecording, setIsRecording] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [audioBlob, setAudioBlob] = useState<Blob | null>(null);
  const [freeUsesLeft, setFreeUsesLeft] = useState<number | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const timerRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    if (!isPro) {
      trialService.getFreeCryInsightsUsed().then(used => {
        setFreeUsesLeft(3 - used);
      });
    }
  }, [isPro]);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      stopRecording();
    };
  }, []);

  const startRecording = async () => {
    // Check Pro status and free usage
    if (!isPro) {
      const hasFreeLeft = await trialService.hasFreeCryInsightsLeft();
      if (!hasFreeLeft) {
        toast.error('Free Cry Insights used up. Upgrade to Pro for unlimited access.');
        return;
      }
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
      mediaRecorderRef.current = mediaRecorder;
      chunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          chunksRef.current.push(e.data);
        }
      };

      mediaRecorder.onstop = async () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
        setAudioBlob(blob);
        stream.getTracks().forEach(track => track.stop());
        await analyzeCry(blob);
      };

      mediaRecorder.start(100);
      setIsRecording(true);
      setProgress(0);

      // Progress timer (20 seconds max)
      const startTime = Date.now();
      const MAX_RECORDING_DURATION_MS = 20000;
      const PROGRESS_UPDATE_INTERVAL_MS = 250; // Reduced from 100ms for better performance
      
      timerRef.current = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const newProgress = Math.min((elapsed / MAX_RECORDING_DURATION_MS) * 100, 100);
        setProgress(newProgress);

        if (elapsed >= MAX_RECORDING_DURATION_MS) {
          stopRecording();
        }
      }, PROGRESS_UPDATE_INTERVAL_MS);
    } catch (error) {
      console.error('Microphone access error:', error);
      toast.error('Could not access microphone. Please check permissions.');
    }
  };

  const stopRecording = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
    
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
    }
    
    setIsRecording(false);
  };

  const analyzeCry = async (blob: Blob) => {
    setIsAnalyzing(true);

    try {
      // Fetch recent events for context (same pattern as CryTimer)
      const { data: recentEvents } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', babyId)
        .gte('start_time', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
        .order('start_time', { ascending: false });

      const now = new Date();
      const timeOfDay = now.getHours();

      // Calculate time since last feed
      const lastFeed = recentEvents?.find((e: any) => e.type === 'feed');
      const timeSinceLastFeed = lastFeed
        ? Math.floor((Date.now() - new Date(lastFeed.start_time).getTime()) / (1000 * 60))
        : 999;

      // Calculate last sleep duration
      const lastSleep = recentEvents?.find((e: any) => e.type === 'sleep' && e.end_time);
      const lastSleepDuration = lastSleep && lastSleep.end_time
        ? Math.floor((new Date(lastSleep.end_time).getTime() - new Date(lastSleep.start_time).getTime()) / (1000 * 60))
        : 0;

      // Convert blob to base64
      const reader = new FileReader();
      reader.readAsDataURL(blob);

      reader.onloadend = async () => {
        const base64Audio = reader.result as string;

        try {
          const { data, error } = await supabase.functions.invoke('analyze-cry-pattern', {
            body: {
              babyId,
              recentEvents: recentEvents?.slice(0, 5) || [],
              timeOfDay,
              timeSinceLastFeed,
              lastSleepDuration,
              audioData: base64Audio, // Keep for future audio processing
            },
          });

          if (error) {
            if (error.message?.includes('not found')) {
              toast.error('AI analysis temporarily unavailable. Your logs are safe.');
            } else {
              throw error;
            }
            return;
          }

          // Increment free usage counter for non-Pro users
          if (!isPro) {
            await trialService.incrementFreeCryInsights();
            setFreeUsesLeft(prev => prev ? prev - 1 : null);
          }

          onAnalysisComplete(data);
          toast.success('Analysis complete!');
        } catch (error) {
          console.error('Analysis error:', error);
          if (error instanceof Error && error.message?.includes('network')) {
            toast.error('Network error. Please check your connection.');
          } else {
            toast.error('Failed to analyze cry. Please try again.');
          }
        } finally {
          setIsAnalyzing(false);
        }
      };
    } catch (error) {
      console.error('FileReader error:', error);
      toast.error('Failed to process audio. Please try again.');
      setIsAnalyzing(false);
    }
  };

  return (
    <Card className="p-6 space-y-4">
      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          Record 10-20 seconds of your baby crying for AI analysis
        </AlertDescription>
      </Alert>

      {!isPro && freeUsesLeft !== null && (
        <Alert className={freeUsesLeft > 0 ? "border-primary/20 bg-primary/5" : "border-destructive/20 bg-destructive/5"}>
          {freeUsesLeft > 0 ? (
            <Mic className="h-4 w-4 text-primary" />
          ) : (
            <Lock className="h-4 w-4 text-destructive" />
          )}
          <AlertDescription className={freeUsesLeft > 0 ? "text-primary" : "text-destructive"}>
            {freeUsesLeft > 0
              ? `${freeUsesLeft} free Cry Insight${freeUsesLeft !== 1 ? 's' : ''} remaining`
              : 'Free Cry Insights used up. Upgrade to Pro for unlimited access.'
            }
          </AlertDescription>
        </Alert>
      )}

      <div className="flex flex-col items-center gap-4">
        {isRecording && (
          <div className="w-full space-y-2">
            <Progress value={progress} className="h-2" />
            <p className="text-sm text-center text-muted-foreground">
              Recording... {Math.floor((progress / 100) * 20)}s
            </p>
          </div>
        )}

        <Button
          onClick={isRecording ? stopRecording : startRecording}
          disabled={isAnalyzing}
          size="lg"
          variant={isRecording ? 'destructive' : 'default'}
          className="w-40 h-40 rounded-full"
        >
          {isAnalyzing ? (
            <Loader2 className="h-12 w-12 animate-spin" />
          ) : isRecording ? (
            <Square className="h-12 w-12" />
          ) : (
            <Mic className="h-12 w-12" />
          )}
        </Button>

        <p className="text-sm text-center text-muted-foreground">
          {isAnalyzing ? 'Analyzing cry pattern...' : isRecording ? 'Tap to stop recording' : 'Tap to start recording'}
        </p>
      </div>
    </Card>
  );
}
