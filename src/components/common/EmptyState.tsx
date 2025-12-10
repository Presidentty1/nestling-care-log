import type { LucideIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  className?: string;
}

export function EmptyState({ icon: Icon, title, description, action, className }: EmptyStateProps) {
  return (
    <Card className={className}>
      <CardContent className='flex flex-col items-center justify-center py-12 px-4 text-center'>
        <div className='rounded-full bg-muted p-4 mb-4'>
          <Icon className='h-8 w-8 text-muted-foreground' />
        </div>
        <h3 className='text-title mb-2 text-foreground'>{title}</h3>
        <p className='text-caption text-muted-foreground mb-6 max-w-sm'>{description}</p>
        {action && (
          <Button onClick={action.onClick} size='lg' className='min-h-[44px] min-w-[140px]'>
            {action.label}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}
