import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Sparkles } from 'lucide-react';
import { useState } from 'react';
import { ChecklistItem } from './ChecklistItem';
import type { EventType } from '@/types/events';

interface WelcomeCardProps {
  onLogFirstEvent: (type: EventType) => void;
}

export function WelcomeCard({ onLogFirstEvent }: WelcomeCardProps) {
  const [completed] = useState({
    firstFeed: localStorage.getItem('completed_firstFeed') === 'true',
    firstDiaper: localStorage.getItem('completed_firstDiaper') === 'true',
    firstSleep: localStorage.getItem('completed_firstSleep') === 'true',
  });

  const completedCount = Object.values(completed).filter(Boolean).length;
  const progress = (completedCount / 3) * 100;

  return (
    <Card className='border-2 border-primary/30 bg-gradient-to-br from-primary/5 to-primary/10 shadow-lg animate-fade-in'>
      <CardContent className='p-6'>
        <div className='flex items-start gap-4 mb-4'>
          <div className='w-14 h-14 rounded-xl bg-primary/20 flex items-center justify-center shrink-0'>
            <Sparkles className='h-7 w-7 text-primary' />
          </div>
          <div className='flex-1'>
            <h3 className='text-xl font-semibold mb-2'>Get Started with 3 Quick Logs</h3>
            <p className='text-sm text-muted-foreground'>
              After 3 logs, you'll unlock patterns and smart predictions!
            </p>
          </div>
        </div>

        <div className='space-y-2 mb-4'>
          <ChecklistItem
            completed={completed.firstFeed}
            label='Log first feed'
            onClick={() => onLogFirstEvent('feed')}
          />
          <ChecklistItem
            completed={completed.firstDiaper}
            label='Log first diaper'
            onClick={() => onLogFirstEvent('diaper')}
          />
          <ChecklistItem
            completed={completed.firstSleep}
            label='Log first sleep'
            onClick={() => onLogFirstEvent('sleep')}
          />
        </div>

        <div className='space-y-1'>
          <div className='flex justify-between text-xs text-muted-foreground'>
            <span>{completedCount} of 3 completed</span>
            <span>{3 - completedCount} remaining</span>
          </div>
          <Progress value={progress} className='h-2' />
        </div>
      </CardContent>
    </Card>
  );
}
