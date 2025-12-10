import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Mic, X } from 'lucide-react';
import { toast } from 'sonner';

interface VoiceMenuProps {
  isOpen: boolean;
  onClose: () => void;
}

export function VoiceMenu({ isOpen, onClose }: VoiceMenuProps) {
  if (!isOpen) return null;

  const handleBegin = () => {
    toast.info('Voice logging coming soon!');
    onClose();
  };

  return (
    <div
      className='fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center sm:justify-center animate-in fade-in duration-200'
      onClick={onClose}
    >
      <div
        className='bg-background w-full sm:max-w-md rounded-t-3xl sm:rounded-2xl p-6 animate-in slide-in-from-bottom duration-300 sm:slide-in-from-bottom-0'
        onClick={e => e.stopPropagation()}
      >
        <div className='flex items-center justify-between mb-4'>
          <div className='flex items-center gap-3'>
            <div className='p-2 bg-primary/10 rounded-full'>
              <Mic className='h-5 w-5 text-primary' />
            </div>
            <h2 className='text-lg font-semibold'>Voice Log (Beta)</h2>
          </div>
          <Button variant='ghost' size='icon' onClick={onClose} aria-label='Close'>
            <X className='h-5 w-5' />
          </Button>
        </div>

        <Card className='mb-4'>
          <CardContent className='p-4'>
            <p className='text-sm text-muted-foreground mb-2'>Say commands like:</p>
            <ul className='space-y-1 text-sm'>
              <li>• "Start sleep timer"</li>
              <li>• "Log wet diaper"</li>
              <li>• "Baby had 4 ounces"</li>
            </ul>
          </CardContent>
        </Card>

        <div className='flex gap-3'>
          <Button variant='outline' className='flex-1' onClick={onClose}>
            Cancel
          </Button>
          <Button className='flex-1' onClick={handleBegin}>
            Begin
          </Button>
        </div>
      </div>
    </div>
  );
}
