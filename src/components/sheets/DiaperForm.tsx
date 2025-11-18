import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { Droplet, Circle, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from 'sonner';

interface DiaperFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
  prefillData?: any;
}

export function DiaperForm({ babyId, editingEventId, onValidChange, onSubmit, prefillData }: DiaperFormProps) {
  const [subtype, setSubtype] = useState<'wet' | 'dirty' | 'both'>(prefillData?.subtype || 'wet');
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSubtype((event.subtype as 'wet' | 'dirty' | 'both') || 'wet');
          setNote(event.note || '');
        }
      });
    }
  }, [editingEventId]);

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
      onSubmit({
        type: 'diaper',
        subtype,
        start_time: new Date().toISOString(),
        note: note || undefined,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not save diaper change';
      setError(message);
      toast.error('Failed to log diaper change');
    }
  };

  const getIcon = (type: 'wet' | 'dirty' | 'both') => {
    if (type === 'wet') return <Droplet className="h-5 w-5" />;
    if (type === 'dirty') return <Circle className="h-5 w-5" />;
    return <Circle className="h-5 w-5" />;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            {error}. Please try saving again.
          </AlertDescription>
        </Alert>
      )}

      {/* Type Selection */}
      <div className="space-y-3">
        <Label className="text-base font-medium">Type</Label>
        <div className="grid grid-cols-3 gap-3">
          {(['wet', 'dirty', 'both'] as const).map((type) => (
            <Button
              key={type}
              type="button"
              variant={subtype === type ? 'default' : 'outline'}
              className="h-16 text-base font-semibold capitalize flex flex-col gap-1"
              onClick={() => setSubtype(type)}
            >
              {getIcon(type)}
              {type}
            </Button>
          ))}
        </div>
      </div>

      {/* Optional Notes */}
      <div className="space-y-3">
        <Label htmlFor="note" className="text-base">Notes (optional)</Label>
        <Textarea
          id="note"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="Any observations..."
          className="min-h-[100px] text-base resize-none"
          maxLength={500}
        />
        {note.length > 0 && (
          <p className="text-xs text-muted-foreground text-right">{note.length}/500</p>
        )}
      </div>
    </form>
  );
}
