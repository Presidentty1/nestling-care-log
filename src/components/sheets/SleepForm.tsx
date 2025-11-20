import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Play, Square, Moon, AlertCircle } from 'lucide-react';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from 'sonner';

interface SleepFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function SleepForm({ babyId, editingEventId, onValidChange, onSubmit, prefillData }: SleepFormProps) {
  const [subtype, setSubtype] = useState<'nap' | 'night'>(prefillData?.subtype || 'nap');
  const [isRunning, setIsRunning] = useState(false);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [endTime, setEndTime] = useState<Date | null>(null);
  const [note, setNote] = useState('');
  const [elapsed, setElapsed] = useState(0);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSubtype((event.subtype as 'nap' | 'night') || 'nap');
          setNote(event.note || '');
          if (event.start_time) {
            const start = new Date(event.start_time);
            setStartTime(start);
          }
          if (event.end_time) {
            const end = new Date(event.end_time);
            setEndTime(end);
          }
        }
      });
    } else if (prefillData) {
      // Use prefillData when creating new event (not editing)
      if (prefillData.subtype) setSubtype(prefillData.subtype);
      if (prefillData.note) setNote(prefillData.note);
      if (prefillData.start_time) {
        setStartTime(new Date(prefillData.start_time));
      }
      if (prefillData.end_time) {
        setEndTime(new Date(prefillData.end_time));
      }
    }
  }, [editingEventId, prefillData]);

  useEffect(() => {
    let interval: number;
    if (isRunning && startTime) {
      interval = window.setInterval(() => {
        setElapsed(Math.floor((Date.now() - startTime.getTime()) / 1000));
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRunning, startTime]);

  const validate = () => {
    const valid = startTime !== null && endTime !== null;
    onValidChange(valid);
    return valid;
  };

  useEffect(() => {
    validate();
  }, [startTime, endTime]);

  const handleStart = () => {
    const now = new Date();
    setStartTime(now);
    setIsRunning(true);
  };

  const handleStop = () => {
    const now = new Date();
    setEndTime(now);
    setIsRunning(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setError(null);
    const start = startTime!;
    const end = endTime!;

    const durationSec = Math.floor((end.getTime() - start.getTime()) / 1000);
    const durationMin = Math.floor(durationSec / 60);

    try {
      onSubmit({
        type: 'sleep',
        subtype,
        start_time: start.toISOString(),
        end_time: end.toISOString(),
        duration_sec: durationSec,
        duration_min: durationMin,
        note: note || undefined,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not save sleep log';
      setError(message);
      toast.error('Failed to log sleep');
    }
  };

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            {error}. Please try saving again.
          </AlertDescription>
        </Alert>
      )}

      {/* Quick Actions */}
      {!editingEventId && (
        <div className="space-y-3">
          {!startTime ? (
            <Button
              type="button"
              onClick={handleStart}
              className="w-full h-16 text-lg font-semibold"
              variant="default"
            >
              <Play className="mr-3 h-6 w-6" />
              Start nap now
            </Button>
          ) : !endTime ? (
            <Button
              type="button"
              onClick={handleStop}
              className="w-full h-16 text-lg font-semibold"
              variant="destructive"
            >
              <Square className="mr-3 h-6 w-6" />
              End nap now
            </Button>
          ) : null}
        </div>
      )}

      {/* Type Selection */}
      <div className="space-y-2">
        <Label className="text-base font-medium">Sleep Type</Label>
        <div className="grid grid-cols-2 gap-3">
          <Button
            type="button"
            variant={subtype === 'nap' ? 'default' : 'outline'}
            className="h-14 text-base"
            onClick={() => setSubtype('nap')}
          >
            <Moon className="mr-2 h-5 w-5" />
            Nap
          </Button>
          <Button
            type="button"
            variant={subtype === 'night' ? 'default' : 'outline'}
            className="h-14 text-base"
            onClick={() => setSubtype('night')}
          >
            <Moon className="mr-2 h-5 w-5" />
            Night Sleep
          </Button>
        </div>
      </div>

      {/* Timer Controls */}
      <div className="space-y-4">
        {!startTime && (
          <Button 
            type="button" 
            onClick={handleStart} 
            className="w-full h-20 text-lg font-semibold"
            size="lg"
          >
            <Play className="mr-3 h-6 w-6" />
            Start Sleep
          </Button>
        )}
        
        {isRunning && (
          <div className="space-y-4">
            <div className="text-center p-8 bg-muted/50 rounded-lg">
              <div className="text-5xl font-mono font-bold text-primary mb-2">{formatTime(elapsed)}</div>
              <div className="text-sm text-muted-foreground">Sleep in progress</div>
            </div>
            <Button 
              type="button" 
              onClick={handleStop} 
              className="w-full h-20 text-lg font-semibold"
              variant="secondary"
              size="lg"
            >
              <Square className="mr-3 h-6 w-6" />
              Stop Sleep
            </Button>
          </div>
        )}
        
        {!isRunning && startTime && endTime && (
          <div className="text-center p-6 bg-muted/50 rounded-lg">
            <div className="text-2xl font-semibold text-primary mb-1">
              {Math.floor((endTime.getTime() - startTime.getTime()) / 60000)} min
            </div>
            <div className="text-sm text-muted-foreground">Sleep duration</div>
          </div>
        )}
      </div>

      {/* Optional Notes */}
      <div className="space-y-2">
        <Label htmlFor="note" className="text-base">Notes (optional)</Label>
        <Textarea
          id="note"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="Sleep quality, environment, etc."
          className="min-h-[80px] text-base resize-none"
          maxLength={500}
        />
        {note.length > 0 && (
          <p className="text-xs text-muted-foreground text-right">{note.length}/500</p>
        )}
      </div>
    </form>
  );
}
