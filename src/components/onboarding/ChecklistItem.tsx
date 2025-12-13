import { Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ChecklistItemProps {
  completed: boolean;
  label: string;
  onClick: () => void;
}

export function ChecklistItem({ completed, label, onClick }: ChecklistItemProps) {
  return (
    <button
      onClick={onClick}
      disabled={completed}
      className={cn(
        'w-full flex items-center gap-3 p-3 rounded-lg border-2 transition-all',
        completed
          ? 'bg-primary/10 border-primary/30 cursor-not-allowed'
          : 'bg-surface border-border hover:border-primary/40 cursor-pointer'
      )}
    >
      <div
        className={cn(
          'w-5 h-5 rounded-full border-2 flex items-center justify-center',
          completed ? 'bg-primary border-primary' : 'border-muted-foreground'
        )}
      >
        {completed && <Check className='h-3 w-3 text-primary-foreground' />}
      </div>
      <span
        className={cn(
          'text-sm font-medium',
          completed ? 'text-muted-foreground line-through' : 'text-foreground'
        )}
      >
        {label}
      </span>
    </button>
  );
}
