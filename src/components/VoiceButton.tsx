import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Mic, MicOff, Loader2 } from 'lucide-react';
import { useVoiceLogging } from '@/hooks/useVoiceLogging';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

interface VoiceButtonProps {
  onCommandParsed: (command: any) => void;
  className?: string;
}

export function VoiceButton({ onCommandParsed, className }: VoiceButtonProps) {
  const { toast } = useToast();
  const { isListening, transcript, startListening, parseCommand } = useVoiceLogging();
  const [showTranscript, setShowTranscript] = useState(false);

  const handleVoiceInput = async () => {
    setShowTranscript(false);
    const result = await startListening();
    
    if (result) {
      setShowTranscript(true);
      const command = parseCommand(result);
      
      if (command.type) {
        toast({
          title: 'Command Recognized',
          description: `Detected: ${command.type}${command.amount ? ` - ${command.amount}${command.unit}` : ''}`,
        });
        onCommandParsed(command);
        setTimeout(() => setShowTranscript(false), 3000);
      } else {
        toast({
          title: 'Command Not Recognized',
          description: 'Try saying: "Log bottle feed 120ml" or "Baby had a wet diaper"',
          variant: 'destructive',
        });
      }
    }
  };

  return (
    <div className={cn('relative', className)}>
      <Button
        onClick={handleVoiceInput}
        disabled={isListening}
        size="lg"
        className={cn(
          'rounded-full w-16 h-16 shadow-lg',
          isListening && 'animate-pulse bg-destructive hover:bg-destructive'
        )}
      >
        {isListening ? (
          <Loader2 className="h-6 w-6 animate-spin" />
        ) : (
          <Mic className="h-6 w-6" />
        )}
      </Button>

      {showTranscript && transcript && (
        <Card className="absolute bottom-20 left-1/2 -translate-x-1/2 p-3 min-w-[250px] shadow-lg">
          <p className="text-sm text-muted-foreground">You said:</p>
          <p className="text-sm font-medium">{transcript}</p>
        </Card>
      )}

      {isListening && (
        <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 whitespace-nowrap">
          <p className="text-xs text-muted-foreground">Listening...</p>
        </div>
      )}
    </div>
  );
}