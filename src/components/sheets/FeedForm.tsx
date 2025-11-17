import { useState, useEffect } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Play, Square } from 'lucide-react';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { unitConversion } from '@/services/unitConversion';
import { hapticFeedback } from '@/lib/haptics';

interface FeedFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
}

export function FeedForm({ babyId, editingEventId, onValidChange, onSubmit }: FeedFormProps) {
  const [segment, setSegment] = useState<'breast' | 'bottle' | 'pumping'>('breast');
  const [side, setSide] = useState<'left' | 'right' | 'both'>('left');
  const [bottleType, setBottleType] = useState<'formula' | 'breast_milk' | 'mixed'>('formula');
  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<'ml' | 'oz'>('ml');
  const [pumpingMode, setPumpingMode] = useState<'timer' | 'manual'>('manual');
  const [note, setNote] = useState('');
  const [isRunning, setIsRunning] = useState(false);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [endTime, setEndTime] = useState<Date | null>(null);
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSegment((event.subtype as 'breast' | 'bottle' | 'pumping') || 'breast');
          setSide((event.side as 'left' | 'right' | 'both') || 'left');
          setBottleType((event as any).bottle_type || 'formula');
          setNote(event.note || '');
          if (event.amount) {
            const displayUnit = event.unit || 'ml';
            setUnit(displayUnit);
            const displayAmount = unitConversion.fromStorageVolume(event.amount, displayUnit);
            setAmount(displayAmount.toString());
          }
          if (event.duration_sec && !event.amount) {
            setPumpingMode('timer');
          }
          if (event.start_time) {
            setStartTime(new Date(event.start_time));
          }
          if (event.end_time) {
            setEndTime(new Date(event.end_time));
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
    if (segment === 'breast') {
      const valid = startTime !== null && endTime !== null;
      onValidChange(valid);
      return valid;
    } else if (segment === 'bottle') {
      const amountNum = parseFloat(amount);
      const valid = !isNaN(amountNum) && amountNum > 0;
      onValidChange(valid);
      return valid;
    } else if (segment === 'pumping') {
      if (pumpingMode === 'timer') {
        const valid = startTime !== null && endTime !== null;
        onValidChange(valid);
        return valid;
      } else {
        const amountNum = parseFloat(amount);
        const valid = !isNaN(amountNum) && amountNum > 0;
        onValidChange(valid);
        return valid;
      }
    }
    return false;
  };

  useEffect(() => {
    validate();
  }, [segment, side, amount, unit, startTime, endTime, pumpingMode, bottleType]);

  const handleStart = () => {
    hapticFeedback.medium();
    const now = new Date();
    setStartTime(now);
    setIsRunning(true);
  };

  const handleStop = () => {
    hapticFeedback.medium();
    const now = new Date();
    setEndTime(now);
    setIsRunning(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    const data: Partial<CreateEventData> = {
      type: 'feed',
      subtype: segment,
      note: note || undefined,
    };

    if (segment === 'breast') {
      data.side = side;
      data.start_time = startTime!.toISOString();
      data.end_time = endTime!.toISOString();
      const durationSec = Math.floor((endTime!.getTime() - startTime!.getTime()) / 1000);
      data.duration_sec = durationSec;
      data.duration_min = Math.floor(durationSec / 60);
    } else {
      // bottle or pumping
      const amountNum = parseFloat(amount);
      const amountMl = unitConversion.toStorageVolume(amountNum, unit);
      data.amount = amountMl;
      data.unit = unit;
      data.start_time = new Date().toISOString();
      
      if (segment === 'pumping') {
        data.side = side;
        if (startTime && endTime) {
          data.end_time = endTime.toISOString();
          data.duration_min = Math.floor((endTime.getTime() - startTime.getTime()) / 60000);
        }
      }
    }

    onSubmit(data);
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Tabs value={segment} onValueChange={(v) => setSegment(v as 'breast' | 'bottle' | 'pumping')}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="breast">Breast</TabsTrigger>
          <TabsTrigger value="bottle">Bottle</TabsTrigger>
          <TabsTrigger value="pumping">Pumping</TabsTrigger>
        </TabsList>

        <TabsContent value="breast" className="space-y-4">
          <div>
            <Label>Side</Label>
            <RadioGroup value={side} onValueChange={(v) => setSide(v as 'left' | 'right' | 'both')}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="left" id="left" />
                <Label htmlFor="left" className="font-normal">Left</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="right" id="right" />
                <Label htmlFor="right" className="font-normal">Right</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="both" id="both-side" />
                <Label htmlFor="both-side" className="font-normal">Both</Label>
              </div>
            </RadioGroup>
          </div>

          {!startTime && (
            <Button type="button" onClick={handleStart} className="w-full" variant="default">
              <Play className="mr-2 h-4 w-4" />
              Start Timer
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

        <TabsContent value="bottle" className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                type="number"
                step="0.1"
                min="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="90"
              />
            </div>
            <div>
              <Label htmlFor="unit">Unit</Label>
              <Select value={unit} onValueChange={(v) => setUnit(v as 'ml' | 'oz')}>
                <SelectTrigger id="unit">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ml">ml</SelectItem>
                  <SelectItem value="oz">oz</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="pumping" className="space-y-4">
          <div>
            <Label>Side</Label>
            <RadioGroup value={side} onValueChange={(v) => setSide(v as 'left' | 'right' | 'both')}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="left" id="pump-left" />
                <Label htmlFor="pump-left" className="font-normal">Left</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="right" id="pump-right" />
                <Label htmlFor="pump-right" className="font-normal">Right</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="both" id="pump-both" />
                <Label htmlFor="pump-both" className="font-normal">Both</Label>
              </div>
            </RadioGroup>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="pump-amount">Amount</Label>
              <Input
                id="pump-amount"
                type="number"
                step="0.1"
                min="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="90"
              />
            </div>
            <div>
              <Label htmlFor="pump-unit">Unit</Label>
              <Select value={unit} onValueChange={(v) => setUnit(v as 'ml' | 'oz')}>
                <SelectTrigger id="pump-unit">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ml">ml</SelectItem>
                  <SelectItem value="oz">oz</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {!startTime && (
            <Button type="button" onClick={handleStart} className="w-full" variant="outline">
              <Play className="mr-2 h-4 w-4" />
              Start Timer (optional)
            </Button>
          )}
          {isRunning && (
            <div className="space-y-3">
              <div className="text-center text-2xl font-mono">{formatTime(elapsed)}</div>
              <Button type="button" onClick={handleStop} className="w-full" variant="secondary">
                <Square className="mr-2 h-4 w-4" />
                Stop
              </Button>
            </div>
          )}
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
