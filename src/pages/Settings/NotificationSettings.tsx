import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ChevronLeft } from 'lucide-react';
import { useAppStore } from '@/store/appStore';
import { dataService } from '@/services/dataService';
import { notifyService } from '@/services/notifyService';
import { NotificationSettings } from '@/types/events';
import { toast } from 'sonner';

export default function NotificationSettingsPage() {
  const navigate = useNavigate();
  const { activeBabyId } = useAppStore();
  const [settings, setSettings] = useState<NotificationSettings>({
    feedReminderEnabled: false,
    feedReminderHours: 3,
    napWindowAlertEnabled: true,
    diaperReminderEnabled: false,
    diaperReminderHours: 3,
    quietHoursStart: '22:00',
    quietHoursEnd: '06:00',
  });
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    loadSettings();
    checkPermission();
  }, [activeBabyId]);

  const loadSettings = async () => {
    if (!activeBabyId) return;
    const saved = await dataService.getNotificationSettings(activeBabyId);
    if (saved) {
      setSettings(saved);
    }
  };

  const checkPermission = async () => {
    const granted = await notifyService.checkPermission();
    setHasPermission(granted);
  };

  const requestPermission = async () => {
    const granted = await notifyService.requestPermission();
    setHasPermission(granted);
    if (granted) {
      toast.success('Notifications enabled');
    } else {
      toast.error('Notification permission denied');
    }
  };

  const updateSettings = async (updates: Partial<NotificationSettings>) => {
    if (!activeBabyId) return;
    
    const newSettings = { ...settings, ...updates };
    setSettings(newSettings);
    await dataService.saveNotificationSettings(activeBabyId, newSettings);
    
    notifyService.stopMonitoring();
    notifyService.startMonitoring(activeBabyId);
  };

  const testNotification = async () => {
    await notifyService.sendNotification(
      'Test Notification',
      'Notifications are working!'
    );
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={() => navigate('/settings')}>
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-2xl font-bold">Notifications</h1>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Permission</CardTitle>
            <CardDescription>
              {hasPermission
                ? 'Notifications are enabled'
                : 'Enable notifications to get reminders'}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {!hasPermission && (
              <Button onClick={requestPermission} className="w-full">
                Enable Notifications
              </Button>
            )}
            {hasPermission && (
              <Button onClick={testNotification} variant="outline" className="w-full">
                Send Test Notification
              </Button>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Feed Reminders</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Enable reminders</Label>
              <Switch
                checked={settings.feedReminderEnabled}
                onCheckedChange={(checked) =>
                  updateSettings({ feedReminderEnabled: checked })
                }
              />
            </div>
            {settings.feedReminderEnabled && (
              <div>
                <Label>Hours since last feed</Label>
                <Input
                  type="number"
                  min={1}
                  max={12}
                  value={settings.feedReminderHours}
                  onChange={(e) =>
                    updateSettings({ feedReminderHours: parseInt(e.target.value) })
                  }
                />
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Nap Window Alerts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <Label>Alert when nap window starts</Label>
              <Switch
                checked={settings.napWindowAlertEnabled}
                onCheckedChange={(checked) =>
                  updateSettings({ napWindowAlertEnabled: checked })
                }
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Diaper Reminders</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Enable reminders</Label>
              <Switch
                checked={settings.diaperReminderEnabled}
                onCheckedChange={(checked) =>
                  updateSettings({ diaperReminderEnabled: checked })
                }
              />
            </div>
            {settings.diaperReminderEnabled && (
              <div>
                <Label>Hours since last change</Label>
                <Input
                  type="number"
                  min={1}
                  max={6}
                  value={settings.diaperReminderHours}
                  onChange={(e) =>
                    updateSettings({ diaperReminderHours: parseInt(e.target.value) })
                  }
                />
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quiet Hours</CardTitle>
            <CardDescription>No notifications during these hours</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Start time</Label>
              <Input
                type="time"
                value={settings.quietHoursStart}
                onChange={(e) =>
                  updateSettings({ quietHoursStart: e.target.value })
                }
              />
            </div>
            <div>
              <Label>End time</Label>
              <Input
                type="time"
                value={settings.quietHoursEnd}
                onChange={(e) =>
                  updateSettings({ quietHoursEnd: e.target.value })
                }
              />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
