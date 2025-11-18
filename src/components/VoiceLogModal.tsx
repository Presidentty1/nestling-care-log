import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Mic, Sparkles } from 'lucide-react';
import { toast } from 'sonner';

interface VoiceLogModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function VoiceLogModal({ open, onOpenChange }: VoiceLogModalProps) {
  const handleBegin = () => {
    toast.info('Voice logging coming soon! 🎤');
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-primary" />
            Voice Logging
            <Badge variant="secondary">Coming Soon</Badge>
          </DialogTitle>
          <DialogDescription>
            Log activities hands-free using voice commands
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="flex justify-center">
            <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center">
              <Mic className="h-10 w-10 text-primary" />
            </div>
          </div>

          <div className="space-y-2 text-sm">
            <p className="font-medium">Example commands:</p>
            <ul className="space-y-1 text-muted-foreground pl-4">
              <li>• "Start sleep timer"</li>
              <li>• "Log 4 ounce bottle"</li>
              <li>• "Log wet diaper"</li>
              <li>• "Start tummy time"</li>
            </ul>
          </div>

          <div className="rounded-lg bg-muted p-3 text-sm text-muted-foreground">
            <strong>Coming soon:</strong> Voice logging will allow you to log activities
            completely hands-free. This feature is currently in development.
          </div>
        </div>

        <DialogFooter className="sm:justify-between">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleBegin} className="gap-2">
            <Mic className="h-4 w-4" />
            Begin (Demo)
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
