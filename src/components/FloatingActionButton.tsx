import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Plus, Mic, X } from 'lucide-react';
import { VoiceButton } from './VoiceButton';
import { cn } from '@/lib/utils';

interface FloatingActionButtonProps {
  onVoiceCommand: (command: any) => void;
  className?: string;
}

export function FloatingActionButton({ onVoiceCommand, className }: FloatingActionButtonProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className={cn('fixed bottom-24 right-6 z-50', className)}>
      {isExpanded ? (
        <div className="flex flex-col items-center gap-4">
          <VoiceButton onCommandParsed={onVoiceCommand} />
          <Button
            onClick={() => setIsExpanded(false)}
            size="lg"
            variant="secondary"
            className="rounded-full w-14 h-14 shadow-lg"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>
      ) : (
        <Button
          onClick={() => setIsExpanded(true)}
          size="lg"
          className="rounded-full w-14 h-14 shadow-lg"
        >
          <Mic className="h-5 w-5" />
        </Button>
      )}
    </div>
  );
}