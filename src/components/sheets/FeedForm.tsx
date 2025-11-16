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
import { ozToMl } from '@/utils/units';
import { Milk, Baby } from 'lucide-react';
import { EventRecord } from '@/types/events';

interface FeedFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: any) => void;
}

export function FeedForm({ babyId, editingEventId, onValidChange, onSubmit }: FeedFormProps) {
  const [feedType, setFeedType] = useState<'breast' | 'bottle' | 'pumping'>('breast');
  const [side, setSide] = useState<'left' | 'right' | 'both'>('left');
  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<'ml' | 'oz'>('ml');
  const [bottleType, setBottleType] = useState<'breastmilk' | 'formula'>('formula');
  const [notes, setNotes] = useState('');
  const [mode, setMode] = useState<'timer' | 'manual'>('timer');
  const [manualDuration, setManualDuration] = useState('');
  
  const timer = useTimerState(babyId);
  
  useEffect(() => {
    let valid = false;
    
    if (feedType === 'breast') {
      valid = timer.elapsedSeconds > 0 || parseInt(manualDuration) > 0;
    } else {
      valid = amount !== '' && parseFloat(amount) > 0;
    }
    
    onValidChange(valid);
  }, [feedType, amount, timer.elapsedSeconds, manualDuration, onValidChange]);
  
  useEffect(() => {
    if (editingEventId) {
      dataService.getEvent(editingEventId).then(event => {
        if (!event) return;
        setNotes(event.notes || '');
        if (event.subtype) {
          if (event.subtype.startsWith('breast')) {
            setFeedType('breast');
            const parts = event.subtype.split('_');
            if (parts[1]) setSide(parts[1] as any);
          } else {
            setFeedType(event.subtype as any);
          }
        }
        if (event.amount) {
          setAmount(event.amount.toString());
          setUnit(event.unit || 'ml');
        }
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
      type: 'feed',
      subtype: feedType === 'breast' ? `breast_${side}` : feedType,
      startTime: now,
      endTime: now,
      notes,
    };
    
    if (feedType === 'breast') {
      if (timer.elapsedSeconds > 0) {
        eventData.durationMin = Math.ceil(timer.elapsedSeconds / 60);
      } else if (manualDuration) {
        eventData.durationMin = parseInt(manualDuration);
      }
      eventData.side = side;
    } else {
      const amountNum = parseFloat(amount);
      eventData.amount = unit === 'oz' ? ozToMl(amountNum) : amountNum;
      eventData.unit = unit;
      
      if (feedType === 'bottle') {
        eventData.subtype = `bottle_${bottleType}`;
      } else if (feedType === 'pumping') {
        eventData.side = side;
      }
    }
    
    await onSubmit(eventData);
    await timer.reset();
  };
  
  return (
    <form id="event-form" onSubmit={handleSubmit} className="space-y-6">
      <Tabs value={feedType} onValueChange={(v) => setFeedType(v as any)}>
        <TabsList className="grid grid-cols-3 w-full">
          <TabsTrigger value="breast" className="gap-2">
            <Baby className="h-4 w-4" />
            <span className="hidden sm:inline">Breastfeeding</span>
            <span className="sm:hidden">Breast</span>
          </TabsTrigger>
          <TabsTrigger value="bottle" className="gap-2">
            <Milk className="h-4 w-4" />
            Bottle
          </TabsTrigger>
          <TabsTrigger value="pumping" className="gap-2">
            <Milk className="h-4 w-4" />
            <span className="hidden sm:inline">Pumping</span>
            <span className="sm:hidden">Pump</span>
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="breast" className="space-y-4 mt-4">
          <div>
            <Label>Side</Label>
            <RadioGroup value={side} onValueChange={(v) => setSide(v as any)}>
              <div className="flex gap-4 mt-2">
                <div className="flex items-center">
                  <RadioGroupItem value="left" id="left" />
                  <Label htmlFor="left" className="ml-2 cursor-pointer">Left</Label>
                </div>
                <div className="flex items-center">
                  <RadioGroupItem value="right" id="right" />
                  <Label htmlFor="right" className="ml-2 cursor-pointer">Right</Label>
                </div>
                <div className="flex items-center">
                  <RadioGroupItem value="both" id="both" />
                  <Label htmlFor="both" className="ml-2 cursor-pointer">Both</Label>
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
            
            <TabsContent value="manual">
              <div>
                <Label htmlFor="duration">Duration (minutes)</Label>
                <Input
                  id="duration"
                  type="number"
                  min="1"
                  value={manualDuration}
                  onChange={(e) => setManualDuration(e.target.value)}
                  placeholder="15"
                  className="mt-1"
                />
              </div>
            </TabsContent>
          </Tabs>
        </TabsContent>
        
        <TabsContent value="bottle" className="space-y-4 mt-4">
          <div className="flex gap-3">
            <div className="flex-1">
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                type="number"
                step="0.1"
                min="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="120"
                className="mt-1"
              />
            </div>
            <div className="w-24">
              <Label>Unit</Label>
              <Tabs value={unit} onValueChange={(v) => setUnit(v as any)} className="mt-1">
                <TabsList className="grid grid-cols-2">
                  <TabsTrigger value="ml">ml</TabsTrigger>
                  <TabsTrigger value="oz">oz</TabsTrigger>
                </TabsList>
              </Tabs>
            </div>
          </div>
          
          <div>
            <Label>Type</Label>
            <RadioGroup value={bottleType} onValueChange={(v) => setBottleType(v as any)}>
              <div className="flex gap-4 mt-2">
                <div className="flex items-center">
                  <RadioGroupItem value="breastmilk" id="breastmilk" />
                  <Label htmlFor="breastmilk" className="ml-2 cursor-pointer">Breastmilk</Label>
                </div>
                <div className="flex items-center">
                  <RadioGroupItem value="formula" id="formula" />
                  <Label htmlFor="formula" className="ml-2 cursor-pointer">Formula</Label>
                </div>
              </div>
            </RadioGroup>
          </div>
        </TabsContent>
        
        <TabsContent value="pumping" className="space-y-4 mt-4">
          <div className="flex gap-3">
            <div className="flex-1">
              <Label htmlFor="pump-amount">Amount</Label>
              <Input
                id="pump-amount"
                type="number"
                step="0.1"
                min="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="90"
                className="mt-1"
              />
            </div>
            <div className="w-24">
              <Label>Unit</Label>
              <Tabs value={unit} onValueChange={(v) => setUnit(v as any)} className="mt-1">
                <TabsList className="grid grid-cols-2">
                  <TabsTrigger value="ml">ml</TabsTrigger>
                  <TabsTrigger value="oz">oz</TabsTrigger>
                </TabsList>
              </Tabs>
            </div>
          </div>
          
          <div>
            <Label>Side</Label>
            <RadioGroup value={side} onValueChange={(v) => setSide(v as any)}>
              <div className="flex gap-4 mt-2">
                <div className="flex items-center">
                  <RadioGroupItem value="left" id="pump-left" />
                  <Label htmlFor="pump-left" className="ml-2 cursor-pointer">Left</Label>
                </div>
                <div className="flex items-center">
                  <RadioGroupItem value="right" id="pump-right" />
                  <Label htmlFor="pump-right" className="ml-2 cursor-pointer">Right</Label>
                </div>
                <div className="flex items-center">
                  <RadioGroupItem value="both" id="pump-both" />
                  <Label htmlFor="pump-both" className="ml-2 cursor-pointer">Both</Label>
                </div>
              </div>
            </RadioGroup>
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
