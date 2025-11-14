import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useEventLogger } from '@/hooks/useEventLogger';
import { EventType, Baby } from '@/lib/types';
import { toast } from 'sonner';
import { Milk, Moon, Baby as BabyIcon, Clock, Play, Pause, Square } from 'lucide-react';

interface EventDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  type: EventType;
  baby: Baby | null;
  onEventLogged?: () => void;
}

export function EventDialog({ open, onOpenChange, type, baby, onEventLogged }: EventDialogProps) {
  const { createEvent, isLoading } = useEventLogger();
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [startTime, setStartTime] = useState<Date>(new Date());
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  
  // Feed specific
  const [feedType, setFeedType] = useState<'bottle' | 'breast' | 'solids'>('bottle');
  const [breastSide, setBreastSide] = useState<'left' | 'right' | 'both'>('left');
  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<'ml' | 'oz'>('ml');
  
  // Diaper specific
  const [diaperType, setDiaperType] = useState<'wet' | 'dirty' | 'both'>('wet');
  
  // Common
  const [note, setNote] = useState('');

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTimerRunning) {
      interval = setInterval(() => {
        setElapsedSeconds(Math.floor((new Date().getTime() - startTime.getTime()) / 1000));
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning, startTime]);

  const resetForm = () => {
    setIsTimerRunning(false);
    setStartTime(new Date());
    setElapsedSeconds(0);
    setFeedType('bottle');
    setBreastSide('left');
    setAmount('');
    setUnit('ml');
    setDiaperType('wet');
    setNote('');
  };

  const handleStartTimer = () => {
    setStartTime(new Date());
    setElapsedSeconds(0);
    setIsTimerRunning(true);
  };

  const handlePauseTimer = () => {
    setIsTimerRunning(false);
  };

  const handleSave = async () => {
    if (!baby) {
      toast.error('No baby selected');
      return;
    }

    try {
      const eventData: any = {
        baby_id: baby.id,
        family_id: baby.family_id,
        type,
        start_time: isTimerRunning || elapsedSeconds > 0 ? startTime.toISOString() : new Date().toISOString(),
        note: note || null,
      };

      if (type === 'feed') {
        eventData.subtype = feedType === 'breast' ? breastSide : feedType;
        if (amount) {
          eventData.amount = parseFloat(amount);
          eventData.unit = unit;
        }
        if (isTimerRunning || elapsedSeconds > 0) {
          eventData.end_time = new Date().toISOString();
        }
      } else if (type === 'sleep' || type === 'tummy_time') {
        if (isTimerRunning || elapsedSeconds > 0) {
          eventData.end_time = new Date().toISOString();
        }
      } else if (type === 'diaper') {
        eventData.subtype = diaperType;
      }

      await createEvent(eventData);
      toast.success(`${type === 'feed' ? 'Feed' : type === 'sleep' ? 'Sleep' : type === 'diaper' ? 'Diaper' : 'Tummy time'} logged`);
      resetForm();
      onOpenChange(false);
      onEventLogged?.();
    } catch (error) {
      console.error('Error logging event:', error);
      toast.error('Failed to log event');
    }
  };

  const formatTime = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return h > 0 ? `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}` : `${m}:${s.toString().padStart(2, '0')}`;
  };

  const getIcon = () => {
    switch (type) {
      case 'feed': return Milk;
      case 'sleep': return Moon;
      case 'diaper': return BabyIcon;
      case 'tummy_time': return Clock;
      default: return BabyIcon;
    }
  };

  const Icon = getIcon();
  const title = type === 'feed' ? 'Log Feed' : type === 'sleep' ? 'Log Sleep' : type === 'diaper' ? 'Log Diaper' : 'Log Tummy Time';

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Icon className="h-5 w-5" />
            {title}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Timer for sleep, tummy_time, and breast feeding */}
          {(type === 'sleep' || type === 'tummy_time' || (type === 'feed' && feedType === 'breast')) && (
            <div className="bg-surface rounded-lg p-4 text-center space-y-4">
              <div className="text-4xl font-mono font-bold">{formatTime(elapsedSeconds)}</div>
              <div className="flex gap-2 justify-center">
                {!isTimerRunning && elapsedSeconds === 0 && (
                  <Button onClick={handleStartTimer} size="lg">
                    <Play className="h-4 w-4 mr-2" /> Start
                  </Button>
                )}
                {isTimerRunning && (
                  <Button onClick={handlePauseTimer} variant="secondary" size="lg">
                    <Pause className="h-4 w-4 mr-2" /> Pause
                  </Button>
                )}
                {elapsedSeconds > 0 && (
                  <Button onClick={() => { setElapsedSeconds(0); setIsTimerRunning(false); }} variant="outline">
                    <Square className="h-4 w-4 mr-2" /> Reset
                  </Button>
                )}
              </div>
            </div>
          )}

          {/* Feed specific fields */}
          {type === 'feed' && (
            <>
              <div className="space-y-2">
                <Label>Feed Type</Label>
                <Select value={feedType} onValueChange={(v: any) => setFeedType(v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="bottle">Bottle</SelectItem>
                    <SelectItem value="breast">Breast</SelectItem>
                    <SelectItem value="solids">Solids</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {feedType === 'breast' && (
                <div className="space-y-2">
                  <Label>Side</Label>
                  <Select value={breastSide} onValueChange={(v: any) => setBreastSide(v)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="left">Left</SelectItem>
                      <SelectItem value="right">Right</SelectItem>
                      <SelectItem value="both">Both</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}

              {feedType !== 'breast' && (
                <div className="grid grid-cols-3 gap-2">
                  <div className="col-span-2 space-y-2">
                    <Label>Amount</Label>
                    <Input
                      type="number"
                      placeholder="0"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Unit</Label>
                    <Select value={unit} onValueChange={(v: any) => setUnit(v)}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="ml">ml</SelectItem>
                        <SelectItem value="oz">oz</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              )}
            </>
          )}

          {/* Diaper specific fields */}
          {type === 'diaper' && (
            <div className="space-y-2">
              <Label>Type</Label>
              <Select value={diaperType} onValueChange={(v: any) => setDiaperType(v)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="wet">Wet</SelectItem>
                  <SelectItem value="dirty">Dirty</SelectItem>
                  <SelectItem value="both">Both</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Note field for all */}
          <div className="space-y-2">
            <Label>Notes (optional)</Label>
            <Textarea
              placeholder="Add any notes..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={2}
            />
          </div>

          <div className="flex gap-2 pt-2">
            <Button variant="outline" onClick={() => onOpenChange(false)} className="flex-1">
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isLoading} className="flex-1">
              {isLoading ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
