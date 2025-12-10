import { useState, useEffect } from 'react';
import { X, Bell, Clock, Baby as BabyIcon, AlertTriangle, Wifi, WifiOff } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useOfflineQueue } from '@/hooks/useOfflineQueue';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';

interface Notification {
  id: string;
  type: 'feed' | 'nap' | 'diaper';
  message: string;
  timestamp: Date;
}

let notificationQueue: Notification[] = [];
let listeners: ((notifications: Notification[]) => void)[] = [];

export const notificationService = {
  show: (type: Notification['type'], message: string) => {
    const notification: Notification = {
      id: crypto.randomUUID(),
      type,
      message,
      timestamp: new Date(),
    };
    notificationQueue = [...notificationQueue, notification];
    listeners.forEach(listener => listener(notificationQueue));

    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      notificationService.dismiss(notification.id);
    }, 5000);
  },

  dismiss: (id: string) => {
    notificationQueue = notificationQueue.filter(n => n.id !== id);
    listeners.forEach(listener => listener(notificationQueue));
  },

  subscribe: (listener: (notifications: Notification[]) => void) => {
    listeners.push(listener);
    listener(notificationQueue);
    return () => {
      listeners = listeners.filter(l => l !== listener);
    };
  },
};

export function NotificationBanner() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const { pendingCount, conflictCount, isSyncing } = useOfflineQueue();
  const isOnline = useNetworkStatus();

  useEffect(() => {
    return notificationService.subscribe(setNotifications);
  }, []);

  if (notifications.length === 0) return null;

  const getIcon = (type: Notification['type']) => {
    switch (type) {
      case 'feed':
        return <Bell className='h-4 w-4' />;
      case 'nap':
        return <Clock className='h-4 w-4' />;
      case 'diaper':
        return <BabyIcon className='h-4 w-4' />;
    }
  };

  return (
    <div className='fixed top-0 left-0 right-0 z-50 p-4 pointer-events-none'>
      <div className='max-w-2xl mx-auto space-y-2 pointer-events-auto'>
        {/* Offline/Sync Status */}
        {!isOnline && (
          <Card className='p-3 bg-warning/10 border-warning/20 text-warning-foreground'>
            <div className='flex items-center gap-2'>
              <WifiOff className='h-4 w-4' />
              <span className='text-sm font-medium'>You're offline</span>
              {pendingCount > 0 && <span className='text-xs'>({pendingCount} pending)</span>}
            </div>
          </Card>
        )}

        {isOnline && isSyncing && (
          <Card className='p-3 bg-info/10 border-info/20 text-info-foreground'>
            <div className='flex items-center gap-2'>
              <div className='animate-spin rounded-full h-3 w-3 border border-current border-t-transparent' />
              <span className='text-sm font-medium'>Syncing...</span>
            </div>
          </Card>
        )}

        {conflictCount > 0 && (
          <Card className='p-3 bg-destructive/10 border-destructive/20 text-destructive-foreground'>
            <div className='flex items-center gap-2'>
              <AlertTriangle className='h-4 w-4' />
              <span className='text-sm font-medium'>
                {conflictCount} data conflict{conflictCount > 1 ? 's' : ''} need resolution
              </span>
              <Button
                variant='outline'
                size='sm'
                className='ml-auto h-6 px-2 text-xs'
                onClick={() => {
                  // This would trigger showing the conflict modal
                  // For now, just show an alert
                  alert('Conflict resolution modal would open here');
                }}
              >
                Resolve
              </Button>
            </div>
          </Card>
        )}

        {notifications.map(notification => (
          <Card
            key={notification.id}
            className='p-4 bg-primary text-primary-foreground shadow-lg animate-slide-in-down'
          >
            <div className='flex items-center justify-between gap-3'>
              <div className='flex items-center gap-3 flex-1'>
                {getIcon(notification.type)}
                <p className='font-medium'>{notification.message}</p>
              </div>
              <Button
                variant='ghost'
                size='icon'
                onClick={() => notificationService.dismiss(notification.id)}
                className='flex-shrink-0 hover:bg-primary-foreground/20'
                aria-label='Dismiss notification'
              >
                <X className='h-4 w-4' />
              </Button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
