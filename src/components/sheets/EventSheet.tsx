import { useState, useEffect, useRef } from 'react';
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerFooter } from '@/components/ui/drawer';
import { Button } from '@/components/ui/button';
import { X } from 'lucide-react';
import { EventType } from '@/types/events';
import { FeedForm } from './FeedForm';
import { SleepForm } from './SleepForm';
import { DiaperForm } from './DiaperForm';
import { TummyTimeForm } from './TummyTimeForm';
import { eventsService, CreateEventData } from '@/services/eventsService';
import { toast } from 'sonner';

interface EventSheetProps {
  isOpen: boolean;
  onClose: () => void;
  eventType: EventType;
  babyId: string;
  familyId: string;
  editingEventId?: string;
}

export function EventSheet({
  isOpen,
  onClose,
  eventType,
  babyId,
  familyId,
  editingEventId,
}: EventSheetProps) {
  const [isValid, setIsValid] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const sheetRef = useRef<HTMLDivElement>(null);
  
  const titles: Partial<Record<EventType, string>> = {
    feed: editingEventId ? 'Edit Feed' : 'Log Feed',
    sleep: editingEventId ? 'Edit Sleep' : 'Log Sleep',
    diaper: editingEventId ? 'Edit Diaper' : 'Log Diaper',
    tummy_time: editingEventId ? 'Edit Tummy Time' : 'Log Tummy Time',
  };
  
  const title = titles[eventType] || 'Log Event';
  
  // Escape key
  useEffect(() => {
    if (!isOpen) return;
    
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);
  
  const handleSave = async (data: Partial<CreateEventData>) => {
    setIsSaving(true);
    
    try {
      const eventData: CreateEventData = {
        baby_id: babyId,
        family_id: familyId,
        type: eventType,
        ...data,
      } as CreateEventData;

      if (editingEventId) {
        await eventsService.updateEvent(editingEventId, eventData);
        toast.success('Event updated');
      } else {
        await eventsService.createEvent(eventData);
        toast.success('Event saved');
      }
      
      onClose();
    } catch (error) {
      console.error('Failed to save event:', error);
      toast.error('We couldn\'t save this entry to the server. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };
  
  const renderForm = () => {
    switch (eventType) {
      case 'feed':
        return (
          <FeedForm
            babyId={babyId}
            editingEventId={editingEventId}
            onValidChange={setIsValid}
            onSubmit={handleSave}
          />
        );
      case 'sleep':
        return (
          <SleepForm
            babyId={babyId}
            editingEventId={editingEventId}
            onValidChange={setIsValid}
            onSubmit={handleSave}
          />
        );
      case 'diaper':
        return (
          <DiaperForm
            babyId={babyId}
            editingEventId={editingEventId}
            onValidChange={setIsValid}
            onSubmit={handleSave}
          />
        );
      case 'tummy_time':
        return (
          <TummyTimeForm
            babyId={babyId}
            editingEventId={editingEventId}
            onValidChange={setIsValid}
            onSubmit={handleSave}
          />
        );
      default:
        return null;
    }
  };
  
  return (
    <Drawer open={isOpen} onOpenChange={onClose}>
      <DrawerContent ref={sheetRef}>
        <DrawerHeader className="flex items-center justify-between">
          <DrawerTitle>{title}</DrawerTitle>
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </Button>
        </DrawerHeader>
        
        <div className="px-4 pb-4 overflow-y-auto max-h-[70vh]">
          {renderForm()}
        </div>
        
        <DrawerFooter>
          <Button
            onClick={() => {
              const form = sheetRef.current?.querySelector('form');
              form?.requestSubmit();
            }}
            disabled={!isValid || isSaving}
            className="w-full"
          >
            {isSaving ? 'Saving...' : 'Save'}
          </Button>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
}
