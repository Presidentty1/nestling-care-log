import { useState, useEffect } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { PartyPopper } from 'lucide-react';
import { triggerConfetti } from '@/lib/confetti';

interface DailyAffirmationProps {
  open: boolean;
  onClose: () => void;
}

const AFFIRMATIONS = [
  'You logged every diaper today! 🎉',
  'Amazing! You tracked all feeds today! 🍼',
  "You're doing great! Every sleep logged today! 😴",
  "Fantastic tracking today! You're a data champion! 📊",
  "Well done! You didn't miss a single event! ⭐",
];

export function DailyAffirmation({ open, onClose }: DailyAffirmationProps) {
  const [message] = useState(() => AFFIRMATIONS[Math.floor(Math.random() * AFFIRMATIONS.length)]);

  useEffect(() => {
    if (open) {
      triggerConfetti();
    }
  }, [open]);

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className='max-w-sm'>
        <DialogHeader>
          <div className='flex justify-center mb-4'>
            <div className='w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center'>
              <PartyPopper className='h-8 w-8 text-primary-foreground' />
            </div>
          </div>
          <DialogTitle className='text-center text-xl'>Amazing Work!</DialogTitle>
          <DialogDescription className='text-center text-base pt-2'>{message}</DialogDescription>
        </DialogHeader>
        <div className='pt-4'>
          <Button onClick={onClose} className='w-full' size='lg'>
            Keep Going! 💪
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
