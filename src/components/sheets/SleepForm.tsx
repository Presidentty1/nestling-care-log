import { useState, useEffect } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Play, Square } from 'lucide-react';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface SleepFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
}

export function SleepForm({ babyId, editingEventId, onValidChange, onSubmit }: SleepFormProps) {
  const [mode, setMode] = useState<'timer' | 'manual'>('timer');
  const [subtype, setSubtype] = useState<'nap' | 'night'>('nap');
  const [isRunning, setIsRunning] = useState(false);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [endTime, setEndTime] = useState<Date | null>(null);
  const [manualStart, setManualStart] = useState('');
  const [manualEnd, setManualEnd] = useState('');
  const [note, setNote] = useState('');
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSubtype((event.subtype as 'nap' | 'night') || 'nap');
          setNote(event.note || '');
          if (event.start_time) {
            const start = new Date(event.start_time);
            setStartTime(start);
            setManualStart(start.toISOString().slice(0, 16));
          }
          if (event.end_time) {
            const end = new Date(event.end_time);
            setEndTime(end);
            setManualEnd(end.toISOString().slice(0, 16));
            setMode('manual');
          }
        }
      });
    }
  }, [editingEventId]);

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
      const valid = manualStart !== '' && manualEnd !== '';
      const startDate = new Date(manualStart);
      const endDate = new Date(manualEnd);
      const isValidRange = endDate > startDate;
      onValidChange(valid && isValidRange);
      return valid && isValidRange;
    }
  };

  useEffect(() => {
    validate();
  }, [mode, startTime, endTime, manualStart, manualEnd]);

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

    if (mode === 'timer') {
      start = startTime!;
      end = endTime!;
    } else {
      start = new Date(manualStart);
      end = new Date(manualEnd);
    }

    const durationMin = Math.floor((end.getTime() - start.getTime()) / 60000);

    onSubmit({
      type: 'sleep',
      subtype,
      start_time: start.toISOString(),
      end_time: end.toISOString(),
      duration_min: durationMin,
      note: note || undefined,
    });
  };

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label>Type</Label>
        <Select value={subtype} onValueChange={(v) => setSubtype(v as 'nap' | 'night')}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="nap">Nap</SelectItem>
            <SelectItem value="night">Night Sleep</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Tabs value={mode} onValueChange={(v) => setMode(v as 'timer' | 'manual')}>
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="timer">Timer</TabsTrigger>
          <TabsTrigger value="manual">Manual</TabsTrigger>
        </TabsList>

        <TabsContent value="timer" className="space-y-4">
          {!startTime && (
            <Button type="button" onClick={handleStart} className="w-full" variant="default">
              <Play className="mr-2 h-4 w-4" />
              Start Sleep Timer
            </Button>
          )}
          {isRunning && (
            <div className="space-y-3">
              <div className="text-center text-3xl font-mono">{formatTime(elapsed)}</div>
              <Button type="button" onClick={handleStop} className="w-full" variant="secondary">
                <Square className="mr-2 h-4 w-4" />
                Stop
              </Button>
            </div>
          )}
          {!isRunning && startTime && endTime && (
            <div className="text-center text-sm text-muted-foreground">
              Duration: {Math.floor((endTime.getTime() - startTime.getTime()) / 60000)} min
            </div>
          )}
        </TabsContent>

        <TabsContent value="manual" className="space-y-4">
          <div>
            <Label htmlFor="manual-start">Start Time</Label>
            <Input
              id="manual-start"
              type="datetime-local"
              value={manualStart}
              onChange={(e) => setManualStart(e.target.value)}
            />
          </div>
          <div>
            <Label htmlFor="manual-end">End Time</Label>
            <Input
              id="manual-end"
              type="datetime-local"
              value={manualEnd}
              onChange={(e) => setManualEnd(e.target.value)}
            />
          </div>
        </TabsContent>
      </Tabs>

      <div>
        <Label htmlFor="note">Notes (optional)</Label>
        <Textarea
          id="note"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="Any observations..."
        />
      </div>
    </form>
  );
}
