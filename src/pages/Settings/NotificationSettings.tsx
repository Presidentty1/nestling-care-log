import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ChevronLeft, Users } from 'lucide-react';
import { useAppStore } from '@/store/appStore';
import { dataService } from '@/services/dataService';
import { notifyService } from '@/services/notifyService';
import type { NotificationSettings } from '@/types/events';
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
  const [caregiverRole, setCaregiverRole] = useState<
    'primary_daytime' | 'evening' | 'summaries_only'
  >('primary_daytime');
  const [withBabyNow, setWithBabyNow] = useState(false);

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
    await notifyService.sendNotification('Test Notification', 'Notifications are working!');
  };

  return (
    <div className='min-h-screen bg-background pb-20'>
      <div className='max-w-2xl mx-auto p-4 space-y-6'>
        {/* Header */}
        <div className='flex items-center gap-3'>
          <Button
            variant='ghost'
            size='icon'
            onClick={() => navigate('/settings')}
            className='h-11 w-11'
          >
            <ChevronLeft className='h-5 w-5' />
          </Button>
          <h1 className='text-[28px] leading-[34px] font-semibold'>Notifications</h1>
        </div>

        {/* Permission Status */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold'>Permission</CardTitle>
            <CardDescription className='text-[15px]'>
              {hasPermission
                ? 'Notifications are enabled'
                : 'Enable notifications to get reminders'}
            </CardDescription>
          </CardHeader>
          <CardContent className='space-y-3'>
            {!hasPermission && (
              <>
                <div className='rounded-[12px] bg-primary/5 border border-primary/10 p-4'>
                  <p className='text-[15px] text-foreground/80'>
                    Enable browser notifications for reminders about feedings, naps, and diaper
                    changes.
                  </p>
                </div>
                <Button
                  onClick={requestPermission}
                  className='w-full h-12 text-[17px] rounded-[14px]'
                >
                  Enable Notifications
                </Button>
              </>
            )}
            {hasPermission && (
              <Button
                onClick={testNotification}
                variant='outline'
                className='w-full h-12 text-[17px] rounded-[14px]'
              >
                Send Test Notification
              </Button>
            )}
          </CardContent>
        </Card>

        {/* Feed Reminders */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold'>Feed Reminders</CardTitle>
            <CardDescription className='text-[15px]'>
              Get reminded when it's time to feed
            </CardDescription>
          </CardHeader>
          <CardContent className='space-y-4'>
            <div className='flex items-center justify-between min-h-[44px]'>
              <Label htmlFor='feed-enabled' className='text-[17px]'>
                Enable Reminders
              </Label>
              <Switch
                id='feed-enabled'
                checked={settings.feedReminderEnabled}
                onCheckedChange={checked => updateSettings({ feedReminderEnabled: checked })}
              />
            </div>
            {settings.feedReminderEnabled && (
              <div className='space-y-2 pt-2 border-t'>
                <Label htmlFor='feed-hours' className='text-[15px] font-semibold'>
                  Remind every (hours)
                </Label>
                <Input
                  id='feed-hours'
                  type='number'
                  min='1'
                  max='12'
                  value={settings.feedReminderHours}
                  onChange={e =>
                    updateSettings({ feedReminderHours: parseInt(e.target.value) || 3 })
                  }
                  className='h-12 text-[17px] rounded-[12px]'
                />
              </div>
            )}
          </CardContent>
        </Card>

        {/* Nap Window Alerts */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold'>Nap Window Alerts</CardTitle>
            <CardDescription className='text-[15px]'>
              Get notified of predicted nap times
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className='flex items-center justify-between min-h-[44px]'>
              <Label htmlFor='nap-enabled' className='text-[17px]'>
                Enable Alerts
              </Label>
              <Switch
                id='nap-enabled'
                checked={settings.napWindowAlertEnabled}
                onCheckedChange={checked => updateSettings({ napWindowAlertEnabled: checked })}
              />
            </div>
          </CardContent>
        </Card>

        {/* Diaper Reminders */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold'>Diaper Reminders</CardTitle>
            <CardDescription className='text-[15px]'>Get reminded to check diapers</CardDescription>
          </CardHeader>
          <CardContent className='space-y-4'>
            <div className='flex items-center justify-between min-h-[44px]'>
              <Label htmlFor='diaper-enabled' className='text-[17px]'>
                Enable Reminders
              </Label>
              <Switch
                id='diaper-enabled'
                checked={settings.diaperReminderEnabled}
                onCheckedChange={checked => updateSettings({ diaperReminderEnabled: checked })}
              />
            </div>
            {settings.diaperReminderEnabled && (
              <div className='space-y-2 pt-2 border-t'>
                <Label htmlFor='diaper-hours' className='text-[15px] font-semibold'>
                  Remind every (hours)
                </Label>
                <Input
                  id='diaper-hours'
                  type='number'
                  min='1'
                  max='12'
                  value={settings.diaperReminderHours}
                  onChange={e =>
                    updateSettings({ diaperReminderHours: parseInt(e.target.value) || 3 })
                  }
                  className='h-12 text-[17px] rounded-[12px]'
                />
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quiet Hours */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold'>Quiet Hours</CardTitle>
            <CardDescription className='text-[15px]'>
              No notifications during these times
            </CardDescription>
          </CardHeader>
          <CardContent className='space-y-4'>
            <div className='space-y-2'>
              <Label htmlFor='quiet-start' className='text-[15px] font-semibold'>
                Start Time
              </Label>
              <Input
                id='quiet-start'
                type='time'
                value={settings.quietHoursStart}
                onChange={e => updateSettings({ quietHoursStart: e.target.value })}
                className='h-12 text-[17px] rounded-[12px]'
              />
            </div>
            <div className='space-y-2'>
              <Label htmlFor='quiet-end' className='text-[15px] font-semibold'>
                End Time
              </Label>
              <Input
                id='quiet-end'
                type='time'
                value={settings.quietHoursEnd}
                onChange={e => updateSettings({ quietHoursEnd: e.target.value })}
                className='h-12 text-[17px] rounded-[12px]'
              />
            </div>
          </CardContent>
        </Card>

        {/* Caregiver Preferences */}
        <Card className='shadow-soft'>
          <CardHeader>
            <CardTitle className='text-[17px] font-semibold flex items-center gap-2'>
              <Users className='h-5 w-5' />
              Caregiver Preferences
            </CardTitle>
            <CardDescription className='text-[15px]'>
              Customize how you receive notifications when sharing care
            </CardDescription>
          </CardHeader>
          <CardContent className='space-y-4'>
            <div className='space-y-2'>
              <Label className='text-[15px] font-semibold'>Your Role</Label>
              <Select value={caregiverRole} onValueChange={(value: any) => setCaregiverRole(value)}>
                <SelectTrigger className='h-12 text-[17px] rounded-[12px]'>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value='primary_daytime'>Primary daytime caregiver</SelectItem>
                  <SelectItem value='evening'>Evening caregiver</SelectItem>
                  <SelectItem value='summaries_only'>Just want summaries</SelectItem>
                </SelectContent>
              </Select>
              <p className='text-xs text-muted-foreground'>
                This helps customize when you receive reminders
              </p>
            </div>

            <div className='flex items-center justify-between'>
              <div className='space-y-1'>
                <Label className='text-[15px] font-semibold'>With baby now</Label>
                <p className='text-xs text-muted-foreground'>
                  Reminders will be sent to whoever is currently with the baby
                </p>
              </div>
              <Switch
                checked={withBabyNow}
                onCheckedChange={setWithBabyNow}
                className='data-[state=checked]:bg-primary'
              />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
