import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Input } from '@/components/ui/input';

interface DiaperFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: Partial<CreateEventData>) => void;
}

export function DiaperForm({ babyId, editingEventId, onValidChange, onSubmit }: DiaperFormProps) {
  const [subtype, setSubtype] = useState<'wet' | 'dirty' | 'both'>('wet');
  const [color, setColor] = useState('');
  const [texture, setTexture] = useState('');
  const [note, setNote] = useState('');
  const [timestamp, setTimestamp] = useState(new Date().toISOString().slice(0, 16));

  useEffect(() => {
    if (editingEventId) {
      eventsService.getEvent(editingEventId).then(event => {
        if (event) {
          setSubtype((event.subtype as 'wet' | 'dirty' | 'both') || 'wet');
          setColor(event.diaper_color || '');
          setTexture(event.diaper_texture || '');
          setNote(event.note || '');
          if (event.start_time) {
            setTimestamp(new Date(event.start_time).toISOString().slice(0, 16));
          }
        }
      });
    }
  }, [editingEventId]);

  const validate = () => {
    const valid = subtype !== undefined;
    onValidChange(valid);
    return valid;
  };

  useEffect(() => {
    validate();
  }, [subtype]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    const start = new Date(timestamp);

    onSubmit({
      type: 'diaper',
      subtype,
      start_time: start.toISOString(),
      diaper_color: (subtype === 'dirty' || subtype === 'both') && color ? color : undefined,
      diaper_texture: (subtype === 'dirty' || subtype === 'both') && texture ? texture : undefined,
      note: note || undefined,
    });
  };

  const showColorTexture = subtype === 'dirty' || subtype === 'both';

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="timestamp">Time</Label>
        <Input
          id="timestamp"
          type="datetime-local"
          value={timestamp}
          onChange={(e) => setTimestamp(e.target.value)}
        />
      </div>

      <div>
        <Label>Type</Label>
        <RadioGroup value={subtype} onValueChange={(v) => setSubtype(v as 'wet' | 'dirty' | 'both')}>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="wet" id="wet" />
            <Label htmlFor="wet" className="font-normal">Wet</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="dirty" id="dirty" />
            <Label htmlFor="dirty" className="font-normal">Dirty</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="both" id="both" />
            <Label htmlFor="both" className="font-normal">Both</Label>
          </div>
        </RadioGroup>
      </div>

      {showColorTexture && (
        <>
          <div>
            <Label htmlFor="color">Color (optional)</Label>
            <Input
              id="color"
              value={color}
              onChange={(e) => setColor(e.target.value)}
              placeholder="e.g., yellow, green"
            />
          </div>
          <div>
            <Label htmlFor="texture">Texture (optional)</Label>
            <Input
              id="texture"
              value={texture}
              onChange={(e) => setTexture(e.target.value)}
              placeholder="e.g., soft, runny"
            />
          </div>
        </>
      )}

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
