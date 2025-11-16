import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { TimerDisplay } from '@/components/timer/TimerDisplay';
import { TimerControls } from '@/components/timer/TimerControls';
import { useTimerState } from '@/hooks/useTimerState';
import { dataService } from '@/services/dataService';

interface TummyTimeFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: any) => void;
}

export function TummyTimeForm({ babyId, editingEventId, onValidChange, onSubmit }: TummyTimeFormProps) {
  const [mode, setMode] = useState<'timer' | 'manual'>('timer');
  const [manualDuration, setManualDuration] = useState('');
  const [notes, setNotes] = useState('');
  
  const timer = useTimerState(babyId);
  
  useEffect(() => {
    let valid = false;
    
    if (mode === 'timer') {
      valid = timer.elapsedSeconds > 0;
    } else {
      valid = parseInt(manualDuration) > 0;
    }
    
    onValidChange(valid);
  }, [mode, timer.elapsedSeconds, manualDuration, onValidChange]);
  
  useEffect(() => {
    if (editingEventId) {
      dataService.getEvent(editingEventId).then(event => {
        if (!event) return;
        setNotes(event.notes || '');
        if (event.durationMin) {
          setManualDuration(event.durationMin.toString());
        }
      });
    }
  }, [editingEventId]);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const now = new Date().toISOString();
    let eventData: any = {
      type: 'tummy',
      startTime: now,
      endTime: now,
      notes,
    };
    
    if (mode === 'timer' && timer.elapsedSeconds > 0) {
      eventData.durationMin = Math.ceil(timer.elapsedSeconds / 60);
    } else if (manualDuration) {
      eventData.durationMin = parseInt(manualDuration);
    }
    
    await onSubmit(eventData);
    await timer.reset();
  };
  
  return (
    <form id="event-form" onSubmit={handleSubmit} className="space-y-6">
      <Tabs value={mode} onValueChange={(v) => setMode(v as any)}>
        <TabsList className="grid grid-cols-2 w-full">
          <TabsTrigger value="timer">Timer</TabsTrigger>
          <TabsTrigger value="manual">Manual</TabsTrigger>
        </TabsList>
        
        <TabsContent value="timer" className="space-y-4">
          <TimerDisplay 
            seconds={timer.elapsedSeconds} 
            isRunning={timer.state.status === 'running'}
          />
          <TimerControls
            status={timer.state.status}
            onStart={() => timer.start(crypto.randomUUID())}
            onPause={timer.pause}
            onResume={timer.resume}
            onStop={timer.stop}
          />
        </TabsContent>
        
        <TabsContent value="manual">
          <div>
            <Label htmlFor="duration">Duration (minutes)</Label>
            <Input
              id="duration"
              type="number"
              min="1"
              value={manualDuration}
              onChange={(e) => setManualDuration(e.target.value)}
              placeholder="10"
              className="mt-1"
            />
          </div>
        </TabsContent>
      </Tabs>
      
      <div>
        <Label htmlFor="notes">Notes (optional)</Label>
        <Textarea
          id="notes"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Any additional details..."
          rows={3}
          className="mt-1"
        />
      </div>
    </form>
  );
}
