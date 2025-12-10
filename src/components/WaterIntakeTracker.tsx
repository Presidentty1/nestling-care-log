import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Droplets, Plus } from 'lucide-react';

interface WaterIntakeTrackerProps {
  currentIntake: number;
  onAddWater: (amount: number) => void;
}

const DAILY_GOAL = 2000; // ml

export function WaterIntakeTracker({ currentIntake, onAddWater }: WaterIntakeTrackerProps) {
  const progress = Math.min((currentIntake / DAILY_GOAL) * 100, 100);
  const glassesCount = Math.floor(currentIntake / 250);

  return (
    <div className='space-y-3'>
      <div className='flex items-center justify-between'>
        <div className='flex items-center gap-2'>
          <Droplets className='h-4 w-4 text-muted-foreground' />
          <span className='text-sm font-medium'>Water Intake</span>
        </div>
        <span className='text-sm text-muted-foreground'>
          {currentIntake} / {DAILY_GOAL} ml
        </span>
      </div>

      <Progress value={progress} className='h-2' />

      <div className='flex items-center gap-2'>
        <Button variant='outline' size='sm' onClick={() => onAddWater(250)} className='flex-1'>
          <Plus className='h-4 w-4 mr-1' />
          Glass (250ml)
        </Button>
        <Button variant='outline' size='sm' onClick={() => onAddWater(500)} className='flex-1'>
          <Plus className='h-4 w-4 mr-1' />
          Bottle (500ml)
        </Button>
      </div>

      {glassesCount > 0 && (
        <div className='text-center text-sm text-muted-foreground'>
          🥤 {glassesCount} glass{glassesCount > 1 ? 'es' : ''} today
        </div>
      )}
    </div>
  );
}
