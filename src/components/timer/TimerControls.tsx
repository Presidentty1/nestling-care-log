import { Button } from '@/components/ui/button';
import { Play, Pause, Square } from 'lucide-react';

interface TimerControlsProps {
  status: 'idle' | 'running' | 'paused' | 'stopped';
  onStart: () => void;
  onPause: () => void;
  onResume: () => void;
  onStop: () => void;
}

export function TimerControls({
  status,
  onStart,
  onPause,
  onResume,
  onStop,
}: TimerControlsProps) {
  return (
    <div className="flex gap-3 justify-center">
      {status === 'idle' && (
        <Button
          size="lg"
          onClick={onStart}
          className="min-w-32"
          aria-label="Start timer"
        >
          <Play className="mr-2 h-5 w-5" />
          Start
        </Button>
      )}
      
      {status === 'running' && (
        <>
          <Button
            size="lg"
            variant="outline"
            onClick={onPause}
            aria-label="Pause timer"
          >
            <Pause className="mr-2 h-5 w-5" />
            Pause
          </Button>
          <Button
            size="lg"
            variant="destructive"
            onClick={onStop}
            aria-label="Stop timer"
          >
            <Square className="mr-2 h-5 w-5" />
            Stop
          </Button>
        </>
      )}
      
      {status === 'paused' && (
        <>
          <Button
            size="lg"
            onClick={onResume}
            aria-label="Resume timer"
          >
            <Play className="mr-2 h-5 w-5" />
            Resume
          </Button>
          <Button
            size="lg"
            variant="destructive"
            onClick={onStop}
            aria-label="Stop timer"
          >
            <Square className="mr-2 h-5 w-5" />
            Stop
          </Button>
        </>
      )}
    </div>
  );
}
