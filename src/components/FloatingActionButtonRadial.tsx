import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Mic, X } from 'lucide-react';
import { VoiceLogModal } from './VoiceLogModal';
import { cn } from '@/lib/utils';

interface FloatingActionButtonRadialProps {
  className?: string;
}

export function FloatingActionButtonRadial({ className }: FloatingActionButtonRadialProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [showVoiceModal, setShowVoiceModal] = useState(false);

  const handleMainClick = () => {
    setIsExpanded(!isExpanded);
  };

  const handleVoiceClick = () => {
    setIsExpanded(false);
    setShowVoiceModal(true);
  };

  const handleCancel = () => {
    setIsExpanded(false);
  };

  return (
    <>
      <div className={cn('fixed bottom-24 right-6 z-50', className)}>
        {/* Backdrop overlay */}
        {isExpanded && (
          <div
            className="fixed inset-0 bg-background/80 backdrop-blur-sm -z-10"
            onClick={handleCancel}
            aria-hidden="true"
          />
        )}

        {/* Radial menu items */}
        <div className="relative">
          {/* Voice Log button */}
          <Button
            size="lg"
            onClick={handleVoiceClick}
            className={cn(
              'absolute rounded-full w-12 h-12 shadow-lg transition-all duration-300',
              'flex items-center justify-center',
              isExpanded
                ? 'opacity-100 translate-y-[-80px] translate-x-0 scale-100'
                : 'opacity-0 translate-y-0 scale-50 pointer-events-none'
            )}
            aria-label="Voice logging (Beta)"
          >
            <Mic className="h-5 w-5" />
          </Button>

          {/* Main FAB */}
          <Button
            onClick={handleMainClick}
            size="lg"
            className={cn(
              'rounded-full w-14 h-14 shadow-lg transition-all duration-300',
              isExpanded ? 'rotate-45 scale-110' : 'rotate-0 scale-100'
            )}
            aria-label={isExpanded ? 'Close menu' : 'Open voice menu'}
            aria-expanded={isExpanded}
          >
            {isExpanded ? (
              <X className="h-5 w-5" />
            ) : (
              <Mic className="h-5 w-5" />
            )}
          </Button>
        </div>

        {/* Label hint when expanded */}
        {isExpanded && (
          <div
            className={cn(
              'absolute right-full mr-4 top-[-72px]',
              'bg-popover text-popover-foreground px-3 py-1.5 rounded-md shadow-md',
              'text-sm whitespace-nowrap animate-in fade-in slide-in-from-right-2',
              'pointer-events-none'
            )}
          >
            Voice Log (Beta)
          </div>
        )}
      </div>

      <VoiceLogModal open={showVoiceModal} onOpenChange={setShowVoiceModal} />
    </>
  );
}
