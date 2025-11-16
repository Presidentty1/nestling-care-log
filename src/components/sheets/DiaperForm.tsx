import { useState, useEffect } from 'react';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { dataService } from '@/services/dataService';

interface DiaperFormProps {
  babyId: string;
  editingEventId?: string;
  onValidChange: (valid: boolean) => void;
  onSubmit: (data: any) => void;
}

export function DiaperForm({ babyId, editingEventId, onValidChange, onSubmit }: DiaperFormProps) {
  const [diaperType, setDiaperType] = useState<'wet' | 'dirty' | 'both'>('wet');
  const [color, setColor] = useState('yellow');
  const [texture, setTexture] = useState('seedy');
  const [notes, setNotes] = useState('');
  
  useEffect(() => {
    onValidChange(true); // Diaper form is always valid
  }, [onValidChange]);
  
  useEffect(() => {
    if (editingEventId) {
      dataService.getEvent(editingEventId).then(event => {
        if (!event) return;
        setNotes(event.notes || '');
        if (event.subtype) setDiaperType(event.subtype as any);
        if (event.diaperColor) setColor(event.diaperColor);
        if (event.diaperTexture) setTexture(event.diaperTexture);
      });
    }
  }, [editingEventId]);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const eventData: any = {
      type: 'diaper',
      subtype: diaperType,
      startTime: new Date().toISOString(),
      notes,
    };
    
    if (diaperType === 'dirty' || diaperType === 'both') {
      eventData.diaperColor = color;
      eventData.diaperTexture = texture;
    }
    
    await onSubmit(eventData);
  };
  
  const showColorTexture = diaperType === 'dirty' || diaperType === 'both';
  
  return (
    <form id="event-form" onSubmit={handleSubmit} className="space-y-6">
      <div>
        <Label>Diaper Type</Label>
        <RadioGroup value={diaperType} onValueChange={(v) => setDiaperType(v as any)}>
          <div className="flex gap-4 mt-2">
            <div className="flex items-center">
              <RadioGroupItem value="wet" id="wet" />
              <Label htmlFor="wet" className="ml-2 cursor-pointer">Wet</Label>
            </div>
            <div className="flex items-center">
              <RadioGroupItem value="dirty" id="dirty" />
              <Label htmlFor="dirty" className="ml-2 cursor-pointer">Dirty</Label>
            </div>
            <div className="flex items-center">
              <RadioGroupItem value="both" id="diaper-both" />
              <Label htmlFor="diaper-both" className="ml-2 cursor-pointer">Both</Label>
            </div>
          </div>
        </RadioGroup>
      </div>
      
      {showColorTexture && (
        <>
          <div>
            <Label htmlFor="color">Color</Label>
            <Select value={color} onValueChange={setColor}>
              <SelectTrigger id="color" className="mt-1">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="yellow">Yellow</SelectItem>
                <SelectItem value="brown">Brown</SelectItem>
                <SelectItem value="green">Green</SelectItem>
                <SelectItem value="other">Other</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div>
            <Label htmlFor="texture">Texture</Label>
            <Select value={texture} onValueChange={setTexture}>
              <SelectTrigger id="texture" className="mt-1">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="seedy">Seedy</SelectItem>
                <SelectItem value="loose">Loose</SelectItem>
                <SelectItem value="solid">Solid</SelectItem>
                <SelectItem value="other">Other</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </>
      )}
      
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
