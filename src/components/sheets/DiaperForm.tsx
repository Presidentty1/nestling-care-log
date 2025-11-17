import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { CreateEventData, eventsService } from '@/services/eventsService';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Input } from '@/components/ui/input';
import { Circle, Square, Droplet, Grid3x3, Waves } from 'lucide-react';
import { cn } from '@/lib/utils';
import { hapticFeedback } from '@/lib/haptics';

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
            <Label>Color (optional)</Label>
            <div className="grid grid-cols-5 gap-2 mt-2">
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setColor('yellow');
                }}
                className={cn(
                  "h-12 w-12 rounded-full bg-yellow-400 transition-all min-h-[44px] min-w-[44px]",
                  color === 'yellow' && "ring-2 ring-primary ring-offset-2"
                )}
                aria-label="Yellow"
              />
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setColor('green');
                }}
                className={cn(
                  "h-12 w-12 rounded-full bg-green-500 transition-all min-h-[44px] min-w-[44px]",
                  color === 'green' && "ring-2 ring-primary ring-offset-2"
                )}
                aria-label="Green"
              />
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setColor('brown');
                }}
                className={cn(
                  "h-12 w-12 rounded-full bg-amber-700 transition-all min-h-[44px] min-w-[44px]",
                  color === 'brown' && "ring-2 ring-primary ring-offset-2"
                )}
                aria-label="Brown"
              />
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setColor('black');
                }}
                className={cn(
                  "h-12 w-12 rounded-full bg-gray-900 transition-all min-h-[44px] min-w-[44px]",
                  color === 'black' && "ring-2 ring-primary ring-offset-2"
                )}
                aria-label="Black"
              />
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setColor('red');
                }}
                className={cn(
                  "h-12 w-12 rounded-full bg-red-500 transition-all min-h-[44px] min-w-[44px]",
                  color === 'red' && "ring-2 ring-primary ring-offset-2"
                )}
                aria-label="Red"
              />
            </div>
            {color === 'red' && (
              <p className="text-sm text-destructive mt-2">If you see red, contact your pediatrician</p>
            )}
          </div>

          <div>
            <Label>Texture (optional)</Label>
            <div className="grid grid-cols-3 gap-2 mt-2">
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setTexture('soft');
                }}
                className={cn(
                  "h-12 px-3 rounded-lg border-2 flex items-center gap-2 justify-center transition-all min-h-[44px]",
                  texture === 'soft' ? "border-primary bg-primary/10" : "border-border"
                )}
              >
                <Circle className="h-4 w-4" />
                <span className="text-sm">Soft</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setTexture('firm');
                }}
                className={cn(
                  "h-12 px-3 rounded-lg border-2 flex items-center gap-2 justify-center transition-all min-h-[44px]",
                  texture === 'firm' ? "border-primary bg-primary/10" : "border-border"
                )}
              >
                <Square className="h-4 w-4" />
                <span className="text-sm">Firm</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setTexture('runny');
                }}
                className={cn(
                  "h-12 px-3 rounded-lg border-2 flex items-center gap-2 justify-center transition-all min-h-[44px]",
                  texture === 'runny' ? "border-primary bg-primary/10" : "border-border"
                )}
              >
                <Droplet className="h-4 w-4" />
                <span className="text-sm">Runny</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setTexture('seedy');
                }}
                className={cn(
                  "h-12 px-3 rounded-lg border-2 flex items-center gap-2 justify-center transition-all min-h-[44px]",
                  texture === 'seedy' ? "border-primary bg-primary/10" : "border-border"
                )}
              >
                <Grid3x3 className="h-4 w-4" />
                <span className="text-sm">Seedy</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  hapticFeedback.light();
                  setTexture('mucous');
                }}
                className={cn(
                  "h-12 px-3 rounded-lg border-2 flex items-center gap-2 justify-center transition-all min-h-[44px] col-span-2",
                  texture === 'mucous' ? "border-primary bg-primary/10" : "border-border"
                )}
              >
                <Waves className="h-4 w-4" />
                <span className="text-sm">Mucous</span>
              </button>
            </div>
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
