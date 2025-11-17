import { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Mic, Square, Loader2, AlertCircle } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';

interface CryRecorderProps {
  babyId: string;
  onAnalysisComplete: (result: any) => void;
}

export function CryRecorder({ babyId, onAnalysisComplete }: CryRecorderProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [audioBlob, setAudioBlob] = useState<Blob | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const timerRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      stopRecording();
    };
  }, []);

  const startRecording = async () => {
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
      const maxDuration = 20000;
      
      timerRef.current = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const newProgress = Math.min((elapsed / maxDuration) * 100, 100);
        setProgress(newProgress);

        if (elapsed >= maxDuration) {
          stopRecording();
        }
      }, 100);
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
      // Convert blob to base64
      const reader = new FileReader();
      reader.readAsDataURL(blob);
      
      reader.onloadend = async () => {
        const base64Audio = reader.result as string;
        
        try {
          const { data, error } = await supabase.functions.invoke('analyze-cry-pattern', {
            body: {
              babyId,
              audioData: base64Audio,
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
