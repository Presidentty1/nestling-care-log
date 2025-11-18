import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Milk } from 'lucide-react';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { unitConversion } from '@/services/unitConversion';

interface FeedFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function FeedForm({ babyId, editingEventId, onValidChange, onSubmit, prefillData }: FeedFormProps) {
  const [feedType, setFeedType] = useState<'breast' | 'bottle'>(prefillData?.subtype === 'bottle' ? 'bottle' : 'breast');
  const [side, setSide] = useState<'left' | 'right' | 'both'>(prefillData?.side || 'left');
  const [amount, setAmount] = useState<string>(prefillData?.amount?.toString() || '');
  const [unit, setUnit] = useState<'ml' | 'oz'>(prefillData?.unit || 'oz');
  const [note, setNote] = useState('');

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setFeedType((event.subtype as 'breast' | 'bottle') || 'breast');
          if (event.side) setSide(event.side as 'left' | 'right' | 'both');
          if (event.amount !== undefined) {
            const displayUnit = event.unit || 'oz';
            setUnit(displayUnit);
            const displayAmount = unitConversion.fromStorageVolume(event.amount, displayUnit);
            setAmount(displayAmount.toString());
          }
          setNote(event.note || '');
        }
      });
    }
  }, [editingEventId]);

  const validate = () => {
    if (feedType === 'breast') {
      onValidChange(true);
      return true;
    }
    if (feedType === 'bottle') {
      const amountNum = parseFloat(amount);
      const valid = !isNaN(amountNum) && amountNum > 0;
      onValidChange(valid);
      return valid;
    }
    onValidChange(false);
    return false;
  };

  useEffect(() => {
    validate();
  }, [feedType, side, amount, unit]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    const data: Partial<CreateEventData> = {
      type: 'feed',
      subtype: feedType,
      note: note || undefined,
      start_time: new Date().toISOString(),
    };

    if (feedType === 'breast') {
      data.side = side;
    } else if (feedType === 'bottle') {
      const amountNum = parseFloat(amount);
      const storageAmount = unitConversion.toStorageVolume(amountNum, unit);
      data.amount = storageAmount;
      data.unit = unit;
    }

    onSubmit(data);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Feed Type Selection */}
      <div className="space-y-3">
        <Label className="text-base font-medium">Feed Type</Label>
        <div className="grid grid-cols-2 gap-3">
          <Button
            type="button"
            variant={feedType === 'breast' ? 'default' : 'outline'}
            className="h-16 text-base font-semibold"
            onClick={() => setFeedType('breast')}
          >
            <Milk className="mr-2 h-5 w-5" />
            Nursing
          </Button>
          <Button
            type="button"
            variant={feedType === 'bottle' ? 'default' : 'outline'}
            className="h-16 text-base font-semibold"
            onClick={() => setFeedType('bottle')}
          >
            <Milk className="mr-2 h-5 w-5" />
            Bottle
          </Button>
        </div>
      </div>

      {/* Nursing Options */}
      {feedType === 'breast' && (
        <div className="space-y-3">
          <Label className="text-base font-medium">Side</Label>
          <div className="grid grid-cols-3 gap-3">
            {(['left', 'right', 'both'] as const).map((s) => (
              <Button
                key={s}
                type="button"
                variant={side === s ? 'default' : 'outline'}
                className="h-14 text-base capitalize"
                onClick={() => setSide(s)}
              >
                {s}
              </Button>
            ))}
          </div>
        </div>
      )}

      {/* Bottle Amount */}
      {feedType === 'bottle' && (
        <div className="space-y-3">
          <Label htmlFor="amount" className="text-base font-medium">Amount</Label>
          <div className="flex gap-3">
            <Input
              id="amount"
              type="number"
              step="0.5"
              placeholder="0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="flex-1 h-14 text-xl text-center font-semibold"
              autoFocus
            />
            <div className="flex gap-2">
              {(['oz', 'ml'] as const).map((u) => (
                <Button
                  key={u}
                  type="button"
                  variant={unit === u ? 'default' : 'outline'}
                  className="h-14 w-16 text-base font-semibold"
                  onClick={() => setUnit(u)}
                >
                  {u}
                </Button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Optional Notes */}
      <div className="space-y-3">
        <Label htmlFor="note" className="text-base">Notes (optional)</Label>
        <Textarea
          id="note"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="Any observations..."
          className="min-h-[100px] text-base resize-none"
        />
      </div>
    </form>
  );
}
