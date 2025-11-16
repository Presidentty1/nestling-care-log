import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { TimerDisplay } from '@/components/timer/TimerDisplay';
import { TimerControls } from '@/components/timer/TimerControls';
import { useTimerState } from '@/hooks/useTimerState';
import { dataService } from '@/services/dataService';
import { addMinutes } from 'date-fns';

interface SleepFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: any) => void;
}

export function SleepForm({ babyId, editingEventId, onValidChange, onSubmit }: SleepFormProps) {
  const [sleepType, setSleepType] = useState<'nap' | 'night'>('nap');
  const [mode, setMode] = useState<'timer' | 'manual'>('timer');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [notes, setNotes] = useState('');
  
  const timer = useTimerState(babyId);
  
  useEffect(() => {
    let valid = false;
    
    if (mode === 'timer') {
      valid = timer.elapsedSeconds > 0;
    } else {
      valid = startTime !== '' && endTime !== '';
    }
    
    onValidChange(valid);
  }, [mode, timer.elapsedSeconds, startTime, endTime, onValidChange]);
  
  useEffect(() => {
    if (editingEventId) {
      dataService.getEvent(editingEventId).then(event => {
        if (!event) return;
        setNotes(event.notes || '');
        if (event.subtype) setSleepType(event.subtype as any);
        if (event.startTime) {
          setStartTime(new Date(event.startTime).toISOString().slice(0, 16));
        }
        if (event.endTime) {
          setEndTime(new Date(event.endTime).toISOString().slice(0, 16));
        }
      });
    }
  }, [editingEventId]);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    let eventData: any = {
      type: 'sleep',
      subtype: sleepType,
      notes,
    };
    
    if (mode === 'timer' && timer.state.startTime) {
      eventData.startTime = timer.state.startTime;
      eventData.endTime = new Date().toISOString();
    } else {
      eventData.startTime = new Date(startTime).toISOString();
      eventData.endTime = new Date(endTime).toISOString();
    }
    
    await onSubmit(eventData);
    await timer.reset();
  };
  
  return (
    <form id="event-form" onSubmit={handleSubmit} className="space-y-6">
      <div>
        <Label>Sleep Type</Label>
        <RadioGroup value={sleepType} onValueChange={(v) => setSleepType(v as any)}>
          <div className="flex gap-4 mt-2">
            <div className="flex items-center">
              <RadioGroupItem value="nap" id="nap" />
              <Label htmlFor="nap" className="ml-2 cursor-pointer">Nap</Label>
            </div>
            <div className="flex items-center">
              <RadioGroupItem value="night" id="night" />
              <Label htmlFor="night" className="ml-2 cursor-pointer">Night</Label>
            </div>
          </div>
        </RadioGroup>
      </div>
      
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
        
        <TabsContent value="manual" className="space-y-4">
          <div>
            <Label htmlFor="start-time">Start Time</Label>
            <Input
              id="start-time"
              type="datetime-local"
              value={startTime}
              onChange={(e) => setStartTime(e.target.value)}
              className="mt-1"
            />
          </div>
          
          <div>
            <Label htmlFor="end-time">End Time</Label>
            <Input
              id="end-time"
              type="datetime-local"
              value={endTime}
              onChange={(e) => setEndTime(e.target.value)}
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
