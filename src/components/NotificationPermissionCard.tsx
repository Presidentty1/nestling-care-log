import { useState } from 'react';
import { Bell } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { notificationManager } from '@/lib/notificationManager';
import { hapticFeedback } from '@/lib/haptics';

interface NotificationPermissionCardProps {
  onDismiss: () => void;
}

export function NotificationPermissionCard({ onDismiss }: NotificationPermissionCardProps) {
  const [isRequesting, setIsRequesting] = useState(false);

  const handleEnable = async () => {
    hapticFeedback.medium();
    setIsRequesting(true);
    try {
      await notificationManager.requestPermission();
      onDismiss();
    } catch (error) {
      console.error('Failed to request notification permission:', error);
    } finally {
      setIsRequesting(false);
    }
  };

  const handleNotNow = () => {
    hapticFeedback.light();
    onDismiss();
  };

  return (
    <Card className='border-primary/20 bg-primary/5'>
      <CardContent className='p-4 flex gap-3'>
        <Bell className='h-5 w-5 text-primary mt-0.5 flex-shrink-0' />
        <div className='flex-1'>
          <h3 className='font-medium text-[15px] mb-1'>Want feeding reminders?</h3>
          <p className='text-[13px] text-muted-foreground mb-3 leading-relaxed'>
            We can alert you when it's time to feed again based on your baby's pattern.
          </p>
          <div className='flex gap-2'>
            <Button
              onClick={handleEnable}
              size='sm'
              disabled={isRequesting}
              className='min-h-[44px]'
            >
              {isRequesting ? 'Enabling...' : 'Enable Alerts'}
            </Button>
            <Button
              onClick={handleNotNow}
              variant='ghost'
              size='sm'
              disabled={isRequesting}
              className='min-h-[44px]'
            >
              Not Now
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
