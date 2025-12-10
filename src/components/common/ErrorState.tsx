import { AlertCircle, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
  retrying?: boolean;
}

export function ErrorState({
  title = 'Something went wrong',
  message,
  onRetry,
  retrying = false,
}: ErrorStateProps) {
  return (
    <Card>
      <CardContent className='flex flex-col items-center justify-center py-12 px-4 text-center'>
        <div className='rounded-full bg-destructive/10 p-4 mb-4'>
          <AlertCircle className='h-8 w-8 text-destructive' />
        </div>
        <h3 className='text-title mb-2 text-foreground'>{title}</h3>
        <p className='text-caption text-muted-foreground mb-6 max-w-sm'>{message}</p>
        {onRetry && (
          <Button
            onClick={onRetry}
            disabled={retrying}
            size='lg'
            className='min-h-[44px] min-w-[120px]'
          >
            {retrying ? (
              <>
                <RefreshCw className='mr-2 h-4 w-4 animate-spin' />
                Retrying...
              </>
            ) : (
              <>
                <RefreshCw className='mr-2 h-4 w-4' />
                Try Again
              </>
            )}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}
