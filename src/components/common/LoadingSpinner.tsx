import { Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Card, CardContent } from '@/components/ui/card';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  text?: string;
  fullHeight?: boolean;
}

export function LoadingSpinner({ size = 'md', className, text, fullHeight = false }: LoadingSpinnerProps) {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-8 w-8',
    lg: 'h-12 w-12',
  };

  const content = (
    <div className={cn('flex flex-col items-center justify-center gap-3 animate-fade-in', className)}>
      <Loader2 className={cn('animate-spin text-primary', sizeClasses[size])} aria-label="Loading" />
      {text && <p className="text-body text-muted-foreground">{text}</p>}
    </div>
  );

  if (fullHeight) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-4">
        {content}
      </div>
    );
  }

  return content;
}

export function LoadingCard({ text }: { text?: string }) {
  return (
    <Card>
      <CardContent className="py-12">
        <LoadingSpinner text={text} />
      </CardContent>
    </Card>
  );
}
