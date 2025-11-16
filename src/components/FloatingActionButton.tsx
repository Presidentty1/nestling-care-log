import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Mic } from 'lucide-react';
import { VoiceMenu } from './sheets/VoiceMenu';
import { cn } from '@/lib/utils';

interface FloatingActionButtonProps {
  onVoiceCommand: (command: any) => void;
  className?: string;
}

export function FloatingActionButton({ onVoiceCommand, className }: FloatingActionButtonProps) {
  const [showVoiceMenu, setShowVoiceMenu] = useState(false);

  return (
    <>
      <div className={cn('fixed bottom-24 right-6 z-50', className)}>
        <Button
          onClick={() => setShowVoiceMenu(true)}
          size="lg"
          className="rounded-full w-14 h-14 shadow-lg"
          aria-label="Open voice menu"
        >
          <Mic className="h-5 w-5" />
        </Button>
      </div>
      
      <VoiceMenu 
        isOpen={showVoiceMenu}
        onClose={() => setShowVoiceMenu(false)}
      />
    </>
  );
}