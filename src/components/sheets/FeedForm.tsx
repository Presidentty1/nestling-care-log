import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Milk, AlertCircle } from 'lucide-react';
import type { CreateEventData } from '@/services/eventsService';
import { eventsService } from '@/services/eventsService';
import { unitConversion } from '@/services/unitConversion';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from 'sonner';
import { RotateCcw } from 'lucide-react';
import { sanitizeEventNote, sanitizeAmount } from '@/lib/sanitization';

interface FeedFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function FeedForm({
  babyId,
  editingEventId,
  onValidChange,
  onSubmit,
  prefillData,
}: FeedFormProps) {
  const [feedType, setFeedType] = useState<'breast' | 'bottle'>(
    prefillData?.subtype === 'bottle' ? 'bottle' : 'breast'
  );
  const [side, setSide] = useState<'left' | 'right' | 'both'>(prefillData?.side || 'left');
  const [amount, setAmount] = useState<string>(prefillData?.amount?.toString() || '');
  const [unit, setUnit] = useState<'ml' | 'oz'>(prefillData?.unit || 'oz');
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);

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
    } else if (prefillData) {
      // Use prefillData when creating new event (not editing)
      if (prefillData.subtype) setFeedType(prefillData.subtype === 'bottle' ? 'bottle' : 'breast');
      if (prefillData.side) setSide(prefillData.side);
      if (prefillData.amount !== undefined) {
        setAmount(prefillData.amount.toString());
        if (prefillData.unit) setUnit(prefillData.unit);
      }
      if (prefillData.note) setNote(prefillData.note);
    }
  }, [editingEventId, prefillData]);

  const handleSameAsLast = () => {
    // This will be handled by the parent component via useLastUsedValues hook
    // The form will be pre-filled automatically
    toast.success('Using your last feed settings');
  };

  const handleQuickPreset = (presetAmount: number) => {
    setFeedType('bottle');
    setAmount(presetAmount.toString());
    setUnit('ml');
  };

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

    setError(null);

    // Sanitize inputs
    const sanitizedNote = note ? sanitizeEventNote(note) : undefined;
    let sanitizedAmount: number | undefined;

    if (feedType === 'bottle') {
      const amountNum = parseFloat(amount);
      sanitizedAmount = sanitizeAmount(amountNum);
      if (sanitizedAmount === null) {
        setError('Invalid amount');
        return;
      }
    }

    const data: Partial<CreateEventData> = {
      type: 'feed',
      subtype: feedType,
      note: sanitizedNote,
      start_time: new Date().toISOString(),
    };

    if (feedType === 'breast') {
      data.side = side;
    } else if (feedType === 'bottle' && sanitizedAmount !== undefined) {
      const storageAmount = unitConversion.toStorageVolume(sanitizedAmount, unit);
      data.amount = storageAmount;
      data.unit = unit;
    }

    try {
      onSubmit(data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not save feeding';
      setError(message);
      toast.error('Failed to log feed');
    }
  };

  return (
    <form onSubmit={handleSubmit} className='space-y-6'>
      {error && (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{error}. Check your connection and try again.</AlertDescription>
        </Alert>
      )}

      {/* Quick Actions */}
      {!editingEventId && (
        <div className='space-y-3'>
          <Button type='button' variant='outline' onClick={handleSameAsLast} className='w-full'>
            <RotateCcw className='mr-2 h-4 w-4' />
            Same as last time
          </Button>

          <div className='space-y-2'>
            <Label className='text-sm font-medium'>Quick presets</Label>
            <div className='grid grid-cols-3 gap-2'>
              <Button
                type='button'
                variant='outline'
                size='sm'
                onClick={() => handleQuickPreset(60)}
                className='h-12'
              >
                60 ml
              </Button>
              <Button
                type='button'
                variant='outline'
                size='sm'
                onClick={() => handleQuickPreset(90)}
                className='h-12'
              >
                90 ml
              </Button>
              <Button
                type='button'
                variant='outline'
                size='sm'
                onClick={() => handleQuickPreset(120)}
                className='h-12'
              >
                120 ml
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Feed Type Selection */}
      <div className='space-y-3'>
        <Label className='text-base font-medium'>Feed Type</Label>
        <div className='grid grid-cols-2 gap-3'>
          <Button
            type='button'
            variant={feedType === 'breast' ? 'default' : 'outline'}
            className='h-16 text-base font-semibold'
            onClick={() => setFeedType('breast')}
          >
            <Milk className='mr-2 h-5 w-5' />
            Nursing
          </Button>
          <Button
            type='button'
            variant={feedType === 'bottle' ? 'default' : 'outline'}
            className='h-16 text-base font-semibold'
            onClick={() => setFeedType('bottle')}
          >
            <Milk className='mr-2 h-5 w-5' />
            Bottle
          </Button>
        </div>
      </div>

      {/* Nursing Options */}
      {feedType === 'breast' && (
        <div className='space-y-3'>
          <Label className='text-base font-medium'>Side</Label>
          <div className='grid grid-cols-3 gap-3'>
            {(['left', 'right', 'both'] as const).map(s => (
              <Button
                key={s}
                type='button'
                variant={side === s ? 'default' : 'outline'}
                className='h-14 text-base capitalize'
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
        <div className='space-y-3'>
          <Label htmlFor='amount' className='text-base font-medium'>
            Amount
          </Label>
          <div className='flex gap-3'>
            <Input
              id='amount'
              type='number'
              inputMode='decimal'
              step='0.5'
              min='0'
              placeholder='0'
              value={amount}
              onChange={e => setAmount(e.target.value)}
              className='flex-1 h-14 text-xl text-center font-semibold'
              autoFocus
            />
            <div className='flex gap-2'>
              {(['oz', 'ml'] as const).map(u => (
                <Button
                  key={u}
                  type='button'
                  variant={unit === u ? 'default' : 'outline'}
                  className='h-14 w-16 text-base font-semibold'
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
      <div className='space-y-3'>
        <Label htmlFor='note' className='text-base'>
          Notes (optional)
        </Label>
        <Textarea
          id='note'
          value={note}
          onChange={e => setNote(sanitizeEventNote(e.target.value))}
          placeholder='Any observations...'
          className='min-h-[100px] text-base resize-none'
          maxLength={500}
        />
        {note.length > 0 && (
          <p className='text-xs text-muted-foreground text-right'>{note.length}/500</p>
        )}
      </div>
    </form>
  );
}
