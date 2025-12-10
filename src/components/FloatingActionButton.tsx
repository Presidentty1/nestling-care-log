import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Mic } from 'lucide-react';
import { VoiceLogModal } from './VoiceLogModal';
import { cn } from '@/lib/utils';

interface FloatingActionButtonProps {
  className?: string;
}

export function FloatingActionButton({ className }: FloatingActionButtonProps) {
  const [showVoiceModal, setShowVoiceModal] = useState(false);

  return (
    <>
      <div className={cn('fixed bottom-24 right-6 z-50', className)}>
        <Button
          onClick={() => setShowVoiceModal(true)}
          size='lg'
          className='rounded-full w-14 h-14 shadow-lg hover:scale-110 transition-transform'
          aria-label='Voice logging'
        >
          <Mic className='h-5 w-5' />
        </Button>
      </div>

      <VoiceLogModal open={showVoiceModal} onOpenChange={setShowVoiceModal} />
    </>
  );
}
