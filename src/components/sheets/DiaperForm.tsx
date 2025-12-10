import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import type { CreateEventData } from '@/services/eventsService';
import { eventsService } from '@/services/eventsService';
import { Droplet, Circle, AlertCircle, Zap } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from 'sonner';
import { sanitizeEventNote } from '@/lib/sanitization';

interface DiaperFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function DiaperForm({
  babyId,
  editingEventId,
  onValidChange,
  onSubmit,
  prefillData,
}: DiaperFormProps) {
  const [subtype, setSubtype] = useState<'wet' | 'dirty' | 'both'>(prefillData?.subtype || 'wet');
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [quickMode, setQuickMode] = useState(false);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSubtype((event.subtype as 'wet' | 'dirty' | 'both') || 'wet');
          setNote(event.note || '');
        }
      });
    } else if (prefillData) {
      // Use prefillData when creating new event (not editing)
      if (prefillData.subtype) setSubtype(prefillData.subtype);
      if (prefillData.note) setNote(prefillData.note);
    }
  }, [editingEventId, prefillData]);

  const validate = () => {
    onValidChange(true);
    return true;
  };

  useEffect(() => {
    validate();
  }, [subtype]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setError(null);
    try {
      const sanitizedNote = note ? sanitizeEventNote(note) : undefined;
      onSubmit({
        type: 'diaper',
        subtype,
        start_time: new Date().toISOString(),
        note: sanitizedNote,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not save diaper change';
      setError(message);
      toast.error('Failed to log diaper change');
    }
  };

  const getIcon = (type: 'wet' | 'dirty' | 'both') => {
    if (type === 'wet') return <Droplet className='h-5 w-5' />;
    if (type === 'dirty') return <Circle className='h-5 w-5' />;
    return <Circle className='h-5 w-5' />;
  };

  return (
    <form onSubmit={handleSubmit} className='space-y-6'>
      {error && (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{error}. Please try saving again.</AlertDescription>
        </Alert>
      )}

      {/* Quick Log Toggle */}
      {!editingEventId && (
        <div className='flex items-center justify-between p-3 bg-muted/50 rounded-lg'>
          <div className='flex items-center gap-2'>
            <Zap className='h-4 w-4 text-primary' />
            <span className='text-sm font-medium'>Quick log</span>
          </div>
          <Button
            type='button'
            variant={quickMode ? 'default' : 'outline'}
            size='sm'
            onClick={() => setQuickMode(!quickMode)}
          >
            {quickMode ? 'On' : 'Off'}
          </Button>
        </div>
      )}

      {/* Type Selection */}
      <div className='space-y-3'>
        <Label className='text-base font-medium'>Type</Label>
        <div className='grid grid-cols-3 gap-3'>
          {(['wet', 'dirty', 'both'] as const).map(type => (
            <Button
              key={type}
              type='button'
              variant={subtype === type ? 'default' : 'outline'}
              className='h-20 text-lg font-semibold capitalize flex flex-col gap-1'
              onClick={() => setSubtype(type)}
            >
              {getIcon(type)}
              {type}
            </Button>
          ))}
        </div>
      </div>

      {/* Optional Notes */}
      {!quickMode && (
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
      )}
    </form>
  );
}
