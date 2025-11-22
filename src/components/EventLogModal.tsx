import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { useEventLogger } from '@/hooks/useEventLogger';
import { useActiveTimer } from '@/hooks/useActiveTimer';
import type { BabyEvent, EventType } from '@/lib/types';
import { Milk, Moon, Baby as BabyIcon } from 'lucide-react';
import { toast } from 'sonner';

interface EventLogModalProps {
  isOpen: boolean;
  onClose: () => void;
  babyId: string;
  familyId: string;
  defaultType?: EventType;
  editingEvent?: BabyEvent | null;
}

export function EventLogModal({
  isOpen,
  onClose,
  babyId,
  familyId,
  defaultType = 'feed',
  editingEvent,
}: EventLogModalProps) {
  const [activeTab, setActiveTab] = useState<EventType>(defaultType);
  const [feedType, setFeedType] = useState<'breast' | 'bottle' | 'pumping'>('breast');
  const [breastSide, setBreastSide] = useState<'left' | 'right' | 'both'>('left');
  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<'ml' | 'oz'>('ml');
  const [note, setNote] = useState('');
  const [isTimerMode, setIsTimerMode] = useState(true);
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [diaperType, setDiaperType] = useState<'wet' | 'dirty' | 'both'>('wet');
  const [hasLeak, setHasLeak] = useState(false);

  const { createEvent, updateEvent, isLoading, getActiveTimer } = useEventLogger();
  const [activeEvent, setActiveEvent] = useState<BabyEvent | null>(null);
  const { formattedTime } = useActiveTimer(activeEvent);

  useEffect(() => {
    if (isOpen) {
      setActiveTab(defaultType);
      loadActiveTimer();
    }
  }, [isOpen, defaultType]);

  useEffect(() => {
    if (editingEvent) {
      setActiveTab(editingEvent.type);
      setNote(editingEvent.note || '');
      if (editingEvent.type === 'feed') {
        if (editingEvent.subtype?.startsWith('breast')) {
          setFeedType('breast');
          setBreastSide(editingEvent.subtype.replace('breast_', '') as 'left' | 'right' | 'both');
        } else {
          setFeedType(editingEvent.subtype as 'bottle' | 'pumping');
          setAmount(editingEvent.amount?.toString() || '');
          setUnit(editingEvent.unit as 'ml' | 'oz');
        }
      } else if (editingEvent.type === 'diaper') {
        setDiaperType(editingEvent.subtype as 'wet' | 'dirty' | 'both');
      }
    }
  }, [editingEvent]);

  const loadActiveTimer = async () => {
    const timer = await getActiveTimer(babyId);
    setActiveEvent(timer);
  };

  const handleStartTimer = async () => {
    try {
      const subtype = activeTab === 'feed' ? `breast_${breastSide}` : undefined;
      const event = await createEvent({
        baby_id: babyId,
        family_id: familyId,
        type: activeTab,
        subtype,
        start_time: new Date().toISOString(),
        note: note || undefined,
      });
      setActiveEvent(event);
    } catch (error) {
      console.error('Failed to start timer:', error);
    }
  };

  const handleStopTimer = async () => {
    if (!activeEvent) return;

    try {
      await updateEvent(activeEvent.id, {
        end_time: new Date().toISOString(),
        note: note || undefined,
      });
      setActiveEvent(null);
      onClose();
    } catch (error) {
      console.error('Failed to stop timer:', error);
    }
  };

  const handleSubmit = async () => {
    try {
      if (editingEvent) {
        // Update existing event
        const updates: any = { note: note || undefined };
        
        if (activeTab === 'feed') {
          if (feedType === 'breast') {
            updates.subtype = `breast_${breastSide}`;
          } else {
            updates.subtype = feedType;
            updates.amount = amount ? parseFloat(amount) : undefined;
            updates.unit = unit;
          }
        } else if (activeTab === 'diaper') {
          updates.subtype = diaperType;
        }
        
        await updateEvent(editingEvent.id, updates);
      } else {
        // Create new event
        let subtype: string | undefined;
        let eventAmount: number | undefined;
        let eventUnit: string | undefined;

        if (activeTab === 'feed') {
          if (feedType === 'breast') {
            subtype = `breast_${breastSide}`;
          } else {
            subtype = feedType;
            eventAmount = amount ? parseFloat(amount) : undefined;
            eventUnit = unit;
          }
        } else if (activeTab === 'diaper') {
          subtype = diaperType;
        }

        await createEvent({
          baby_id: babyId,
          family_id: familyId,
          type: activeTab,
          subtype,
          start_time: startTime || new Date().toISOString(),
          end_time: endTime || (activeTab === 'diaper' ? new Date().toISOString() : undefined),
          amount: eventAmount,
          unit: eventUnit,
          note: note || undefined,
        });
      }

      onClose();
      resetForm();
    } catch (error) {
      console.error('Failed to save event:', error);
    }
  };

  const resetForm = () => {
    setFeedType('breast');
    setBreastSide('left');
    setAmount('');
    setNote('');
    setStartTime('');
    setEndTime('');
    setDiaperType('wet');
    setHasLeak(false);
    setActiveEvent(null);
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>{editingEvent ? 'Edit Event' : 'Log Event'}</DialogTitle>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as EventType)}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="feed">
              <Milk className="h-4 w-4 mr-2" />
              Feed
            </TabsTrigger>
            <TabsTrigger value="sleep">
              <Moon className="h-4 w-4 mr-2" />
              Sleep
            </TabsTrigger>
            <TabsTrigger value="diaper">
              <BabyIcon className="h-4 w-4 mr-2" />
              Diaper
            </TabsTrigger>
          </TabsList>

          <TabsContent value="feed" className="space-y-4">
            <div>
              <Label>Feed Type</Label>
              <div className="flex gap-2 mt-2">
                <Button
                  type="button"
                  variant={feedType === 'breast' ? 'default' : 'outline'}
                  onClick={() => setFeedType('breast')}
                  className="flex-1"
                >
                  Breast
                </Button>
                <Button
                  type="button"
                  variant={feedType === 'bottle' ? 'default' : 'outline'}
                  onClick={() => setFeedType('bottle')}
                  className="flex-1"
                >
                  Bottle
                </Button>
                <Button
                  type="button"
                  variant={feedType === 'pumping' ? 'default' : 'outline'}
                  onClick={() => setFeedType('pumping')}
                  className="flex-1"
                >
                  Pumping
                </Button>
              </div>
            </div>

            {feedType === 'breast' && (
              <>
                <div>
                  <Label>Side</Label>
                  <div className="flex gap-2 mt-2">
                    {(['left', 'right', 'both'] as const).map((side) => (
                      <Button
                        key={side}
                        type="button"
                        variant={breastSide === side ? 'default' : 'outline'}
                        onClick={() => setBreastSide(side)}
                        className="flex-1 capitalize"
                      >
                        {side}
                      </Button>
                    ))}
                  </div>
                </div>

                {activeEvent ? (
                  <div className="text-center p-4 bg-muted rounded-lg">
                    <div className="text-3xl font-mono">{formattedTime}</div>
                    <Button onClick={handleStopTimer} className="mt-4" disabled={isLoading}>
                      Stop
                    </Button>
                  </div>
                ) : (
                  <Button onClick={handleStartTimer} className="w-full" disabled={isLoading}>
                    Start Timer
                  </Button>
                )}
              </>
            )}

            {(feedType === 'bottle' || feedType === 'pumping') && (
              <div className="flex gap-2">
                <div className="flex-1">
                  <Label>Amount</Label>
                  <Input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="120"
                  />
                </div>
                <div>
                  <Label>Unit</Label>
                  <div className="flex gap-1 mt-2">
                    <Button
                      type="button"
                      variant={unit === 'ml' ? 'default' : 'outline'}
                      onClick={() => setUnit('ml')}
                      size="sm"
                    >
                      ml
                    </Button>
                    <Button
                      type="button"
                      variant={unit === 'oz' ? 'default' : 'outline'}
                      onClick={() => setUnit('oz')}
                      size="sm"
                    >
                      oz
                    </Button>
                  </div>
                </div>
              </div>
            )}
          </TabsContent>

          <TabsContent value="sleep" className="space-y-4">
            {activeEvent && activeEvent.type === 'sleep' ? (
              <div className="text-center p-4 bg-muted rounded-lg">
                <div className="text-3xl font-mono">{formattedTime}</div>
                <Button onClick={handleStopTimer} className="mt-4" disabled={isLoading}>
                  Wake Up
                </Button>
              </div>
            ) : (
              <>
                <div className="flex gap-2 mb-4">
                  <Button
                    type="button"
                    variant={isTimerMode ? 'default' : 'outline'}
                    onClick={() => setIsTimerMode(true)}
                    className="flex-1"
                  >
                    Timer
                  </Button>
                  <Button
                    type="button"
                    variant={!isTimerMode ? 'default' : 'outline'}
                    onClick={() => setIsTimerMode(false)}
                    className="flex-1"
                  >
                    Manual
                  </Button>
                </div>

                {isTimerMode ? (
                  <Button onClick={handleStartTimer} className="w-full" disabled={isLoading}>
                    Start Sleep Timer
                  </Button>
                ) : (
                  <>
                    <div>
                      <Label>Start Time</Label>
                      <Input
                        type="datetime-local"
                        value={startTime}
                        onChange={(e) => setStartTime(e.target.value)}
                      />
                    </div>
                    <div>
                      <Label>End Time</Label>
                      <Input
                        type="datetime-local"
                        value={endTime}
                        onChange={(e) => setEndTime(e.target.value)}
                      />
                    </div>
                  </>
                )}
              </>
            )}
          </TabsContent>

          <TabsContent value="diaper" className="space-y-4">
            <div>
              <Label>Type</Label>
              <div className="flex gap-2 mt-2">
                {(['wet', 'dirty', 'both'] as const).map((type) => (
                  <Button
                    key={type}
                    type="button"
                    variant={diaperType === type ? 'default' : 'outline'}
                    onClick={() => setDiaperType(type)}
                    className="flex-1 capitalize"
                  >
                    {type}
                  </Button>
                ))}
              </div>
            </div>
          </TabsContent>
        </Tabs>

        <div>
          <Label>Notes (optional)</Label>
          <Textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Add any notes..."
            rows={3}
          />
        </div>

        {!activeEvent && (
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isLoading} className="flex-1">
              {editingEvent ? 'Update' : 'Save'}
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
