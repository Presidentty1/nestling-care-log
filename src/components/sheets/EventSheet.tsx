import { useState, useEffect, useRef } from 'react';
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerFooter } from '@/components/ui/drawer';
import { Button } from '@/components/ui/button';
import { X } from 'lucide-react';
import { EventType } from '@/types/events';
import { FeedForm } from './FeedForm';
import { SleepForm } from './SleepForm';
import { DiaperForm } from './DiaperForm';
import { TummyTimeForm } from './TummyTimeForm';
import { dataService } from '@/services/dataService';
import { analyticsService } from '@/services/analyticsService';
import { napService } from '@/services/napService';
import { supabase } from '@/integrations/supabase/client';
import { differenceInMonths } from 'date-fns';
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
    feed: 'Log Feed',
    sleep: 'Log Sleep',
    diaper: 'Log Diaper',
    tummy_time: 'Log Tummy Time',
  };
  
  const title = titles[eventType] || 'Log Event';
  
  // Focus trap
  useEffect(() => {
    if (!isOpen) return;
    
    const focusableElements = sheetRef.current?.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    if (!focusableElements || focusableElements.length === 0) return;
    
    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;
    
    setTimeout(() => firstElement.focus(), 100);
    
    const handleTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;
      
      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          e.preventDefault();
          lastElement.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          e.preventDefault();
          firstElement.focus();
        }
      }
    };
    
    document.addEventListener('keydown', handleTab);
    return () => document.removeEventListener('keydown', handleTab);
  }, [isOpen]);
  
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
  
  const handleSave = async (data: any) => {
    setIsSaving(true);
    try {
      if (editingEventId) {
        await dataService.updateEvent(editingEventId, data);
        analyticsService.track('event_edited', { type: eventType });
        toast.success('Event updated');
      } else {
        await dataService.addEvent({
          ...data,
          babyId,
          familyId,
        });
        analyticsService.track('event_saved', {
          type: eventType,
          subtype: data.subtype,
          hasAmount: !!data.amount,
          hasDuration: !!data.durationMin,
        });
        toast.success('Event saved');
      }

      // Recalculate nap prediction after sleep event
      if (eventType === 'sleep' && data.endTime) {
        try {
          // Get baby data to calculate age
          const { data: baby, error } = await supabase
            .from('babies')
            .select('*')
            .eq('id', babyId)
            .single();
          
          if (!error && baby) {
            const ageMonths = differenceInMonths(new Date(), new Date(baby.date_of_birth));
            const prediction = await napService.recalculate(babyId, ageMonths);
            if (prediction) {
              await dataService.storeNapPrediction(babyId, prediction);
              analyticsService.track('nap_prediction_updated', { babyId });
            }
          }
        } catch (error) {
          console.error('Failed to recalculate nap prediction:', error);
          // Don't show error to user, this is background work
        }
      }

      onClose();
    } catch (error) {
      console.error('Failed to save event:', error);
      toast.error('Failed to save event');
    } finally {
      setIsSaving(false);
    }
  };
  
  return (
    <Drawer open={isOpen} onOpenChange={(open) => { if (!open) onClose(); }}>
      <DrawerContent 
        ref={sheetRef}
        className="rounded-t-[24px] max-h-[90vh]"
        aria-labelledby="event-sheet-title"
      >
        <DrawerHeader className="border-b">
          <div className="flex items-center justify-between">
            <DrawerTitle id="event-sheet-title">{title}</DrawerTitle>
            <Button
              variant="ghost"
              size="icon"
              onClick={onClose}
              aria-label="Close"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>
        </DrawerHeader>
        
        <div className="overflow-y-auto max-h-[60vh] px-4 py-6">
          {eventType === 'feed' && (
            <FeedForm
              babyId={babyId}
              editingEventId={editingEventId}
              onValidChange={setIsValid}
              onSubmit={handleSave}
            />
          )}
          {eventType === 'sleep' && (
            <SleepForm
              babyId={babyId}
              editingEventId={editingEventId}
              onValidChange={setIsValid}
              onSubmit={handleSave}
            />
          )}
          {eventType === 'diaper' && (
            <DiaperForm
              babyId={babyId}
              editingEventId={editingEventId}
              onValidChange={setIsValid}
              onSubmit={handleSave}
            />
          )}
          {eventType === 'tummy_time' && (
            <TummyTimeForm
              babyId={babyId}
              editingEventId={editingEventId}
              onValidChange={setIsValid}
              onSubmit={handleSave}
            />
          )}
        </div>
        
        <DrawerFooter className="border-t sticky bottom-0 bg-background pt-4">
          <div className="flex gap-3 w-full">
            <Button
              variant="outline"
              className="flex-1"
              onClick={onClose}
              disabled={isSaving}
            >
              Cancel
            </Button>
            <Button
              className="flex-1"
              onClick={() => {
                document.getElementById('event-form')?.dispatchEvent(
                  new Event('submit', { cancelable: true, bubbles: true })
                );
              }}
              disabled={!isValid || isSaving}
            >
              {isSaving ? 'Saving...' : 'Save Log'}
            </Button>
          </div>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
}
