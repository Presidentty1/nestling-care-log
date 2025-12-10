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
        notification => {
          const { actionId, notification: notif } = notification;
          const { extra } = notif;

          // Handle quick log actions from action buttons
          if (actionId === 'log-feed') {
            navigate('/', {
              state: {
                openSheet: 'feed',
                babyId: extra?.babyId,
                prefillData: {},
              },
            });
          } else if (actionId === 'log-nap') {
            navigate('/', {
              state: {
                openSheet: 'sleep',
                babyId: extra?.babyId,
                prefillData: { subtype: 'nap' },
              },
            });
          } else if (actionId === 'log-diaper') {
            navigate('/', {
              state: {
                openSheet: 'diaper',
                babyId: extra?.babyId,
                prefillData: {},
              },
            });
          } else if (actionId === 'dismiss') {
            // User dismissed, do nothing
            return;
          } else {
            // Handle regular notification tap (no action button)
            if (extra?.type === 'feed' || extra?.type === 'diaper') {
              navigate('/');
            } else if (extra?.type === 'nap') {
              navigate('/nap-details');
            } else if (extra?.type === 'medication') {
              navigate('/health');
            }
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
