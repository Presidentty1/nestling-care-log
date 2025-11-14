import { useEffect } from 'react';
import { LocalNotifications } from '@capacitor/local-notifications';
import { useNavigate } from 'react-router-dom';

export function useNotificationHandler() {
  const navigate = useNavigate();

  useEffect(() => {
    let listenerHandle: any;

    const setupListener = async () => {
      listenerHandle = await LocalNotifications.addListener(
        'localNotificationActionPerformed',
        (notification) => {
          const { extra } = notification.notification;

          if (extra?.type === 'feed' || extra?.type === 'diaper') {
            navigate('/');
          } else if (extra?.type === 'nap') {
            navigate('/nap-details');
          } else if (extra?.type === 'medication') {
            navigate('/health');
          }
        }
      );
    };

    setupListener();

    return () => {
      if (listenerHandle) {
        listenerHandle.remove();
      }
    };
  }, [navigate]);
}
