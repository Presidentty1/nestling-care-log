// React imports
import { useState, useEffect } from 'react';

// External libraries
import { Play, Square } from 'lucide-react';

// UI components
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

// Types
import type { CreateEventData } from '@/services/eventsService';

// Services
import { eventsService } from '@/services/eventsService';

// Utilities
import { sanitizeEventNote, sanitizeDuration } from '@/lib/sanitization';

interface TummyTimeFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function TummyTimeForm({
  babyId,
  editingEventId,
  onValidChange,
  onSubmit,
  prefillData,
}: TummyTimeFormProps) {
  const [mode, setMode] = useState<'timer' | 'manual'>('timer');
  const [isRunning, setIsRunning] = useState(false);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [endTime, setEndTime] = useState<Date | null>(null);
  const [manualDuration, setManualDuration] = useState('');
  const [note, setNote] = useState('');
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setNote(event.note || '');
          if (event.duration_min) {
            setManualDuration(event.duration_min.toString());
            setMode('manual');
          }
          if (event.start_time) {
            setStartTime(new Date(event.start_time));
          }
          if (event.end_time) {
            setEndTime(new Date(event.end_time));
          }
        }
      });
    } else if (prefillData) {
      // Use prefillData when creating new event (not editing)
      if (prefillData.note) setNote(prefillData.note);
      if (prefillData.duration_min) {
        setManualDuration(prefillData.duration_min.toString());
        setMode('manual');
      }
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
    if (mode === 'timer') {
      const valid = startTime !== null && endTime !== null;
      onValidChange(valid);
      return valid;
    } else {
      const duration = parseInt(manualDuration, 10);
      const valid = !isNaN(duration) && duration > 0;
      onValidChange(valid);
      return valid;
    }
  };

  useEffect(() => {
    validate();
  }, [mode, startTime, endTime, manualDuration]);

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

    let start: Date;
    let end: Date;
    let durationMin: number;

    let durationSec: number;

    if (mode === 'timer') {
      start = startTime!;
      end = endTime!;
      durationSec = Math.floor((end.getTime() - start.getTime()) / 1000);
      durationMin = Math.floor(durationSec / 60);
    } else {
      durationMin = parseInt(manualDuration, 10);
      durationSec = durationMin * 60;
      start = new Date();
      end = new Date(start.getTime() + durationSec * 1000);
    }

    const sanitizedNote = note ? sanitizeEventNote(note) : undefined;
    const sanitizedDuration = sanitizeDuration(durationSec);

    onSubmit({
      type: 'tummy_time',
      start_time: start.toISOString(),
      end_time: end.toISOString(),
      duration_sec: sanitizedDuration || durationSec,
      duration_min: durationMin,
      note: sanitizedNote,
    });
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <form onSubmit={handleSubmit} className='space-y-4'>
      <Tabs value={mode} onValueChange={v => setMode(v as 'timer' | 'manual')}>
        <TabsList className='grid w-full grid-cols-2'>
          <TabsTrigger value='timer'>Timer</TabsTrigger>
          <TabsTrigger value='manual'>Manual</TabsTrigger>
        </TabsList>

        <TabsContent value='timer' className='space-y-4'>
          {!startTime && (
            <Button type='button' onClick={handleStart} className='w-full' variant='default'>
              <Play className='mr-2 h-4 w-4' />
              Start Timer
            </Button>
          )}
          {isRunning && (
            <div className='space-y-3'>
              <div className='text-center text-3xl font-mono'>{formatTime(elapsed)}</div>
              <Button type='button' onClick={handleStop} className='w-full' variant='secondary'>
                <Square className='mr-2 h-4 w-4' />
                Stop
              </Button>
            </div>
          )}
          {!isRunning && startTime && endTime && (
            <div className='text-center text-sm text-muted-foreground'>
              Duration: {Math.floor((endTime.getTime() - startTime.getTime()) / 60000)} min
            </div>
          )}
        </TabsContent>

        <TabsContent value='manual' className='space-y-4'>
          <div>
            <Label htmlFor='duration'>Duration (minutes)</Label>
            <Input
              id='duration'
              type='number'
              min='1'
              value={manualDuration}
              onChange={e => setManualDuration(e.target.value)}
              placeholder='e.g., 5'
            />
          </div>
        </TabsContent>
      </Tabs>

      <div>
        <Label htmlFor='note'>Notes (optional)</Label>
        <Textarea
          id='note'
          value={note}
          onChange={e => setNote(sanitizeEventNote(e.target.value))}
          placeholder='Any observations...'
        />
      </div>
    </form>
  );
}
