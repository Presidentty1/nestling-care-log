import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby, NotificationSettings as NotificationSettingsType } from '@/lib/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { LocalNotifications } from '@capacitor/local-notifications';
import { toast } from 'sonner';
import { Bell } from 'lucide-react';

export default function NotificationSettings() {
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [permissionStatus, setPermissionStatus] = useState<'granted' | 'denied' | 'prompt' | 'prompt-with-rationale'>('prompt');
  const queryClient = useQueryClient();

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data, error } = await supabase.from('babies').select('*');
      if (error) throw error;
      if (data && data.length > 0 && !selectedBaby) {
        setSelectedBaby(data[0]);
      }
      return data as Baby[];
    },
  });

  const { data: settings } = useQuery({
    queryKey: ['notification-settings', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return null;
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) return null;

      const { data, error } = await supabase
        .from('notification_settings')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .eq('user_id', user.user.id)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') throw error;
      
      if (!data) {
        // Create default settings
        const defaultSettings: Partial<NotificationSettingsType> = {
          baby_id: selectedBaby.id,
          user_id: user.user.id,
          enabled: true,
          feed_reminders_enabled: false,
          feed_reminder_interval_hours: 3,
          nap_reminders_enabled: true,
          nap_window_reminder_minutes: 15,
          diaper_reminders_enabled: false,
          diaper_reminder_interval_hours: 3,
          medication_reminders_enabled: true,
        };

        const { data: newSettings, error: insertError } = await supabase
          .from('notification_settings')
          .insert(defaultSettings)
          .select()
          .single();

        if (insertError) throw insertError;
        return newSettings as NotificationSettingsType;
      }

      return data as NotificationSettingsType;
    },
    enabled: !!selectedBaby,
  });

  const updateSettingsMutation = useMutation({
    mutationFn: async (updates: Partial<NotificationSettingsType>) => {
      if (!settings) return;
      const { error } = await supabase
        .from('notification_settings')
        .update(updates)
        .eq('id', settings.id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notification-settings'] });
      toast.success('Settings updated');
    },
  });

  useEffect(() => {
    checkPermission();
  }, []);

  const checkPermission = async () => {
    const result = await LocalNotifications.checkPermissions();
    setPermissionStatus(result.display);
  };

  const requestPermission = async () => {
    const result = await LocalNotifications.requestPermissions();
    setPermissionStatus(result.display);
    if (result.display === 'granted') {
      toast.success('Notifications enabled');
    } else {
      toast.error('Notification permission denied');
    }
  };

  const sendTestNotification = async () => {
    if (permissionStatus !== 'granted') {
      toast.error('Please enable notifications first');
      return;
    }

    await LocalNotifications.schedule({
      notifications: [
        {
          title: 'Test Notification',
          body: 'Notifications are working! 🎉',
          id: Math.floor(Math.random() * 100000),
          schedule: { at: new Date(Date.now() + 1000) },
        },
      ],
    });
    toast.success('Test notification sent');
  };

  if (!selectedBaby || !settings) {
    return (
      <div className="container max-w-4xl mx-auto p-4">
        <p className="text-muted-foreground text-center py-8">Loading...</p>
      </div>
    );
  }

  return (
    <div className="container max-w-4xl mx-auto p-4 pb-20">
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Notification Settings</h1>
        <p className="text-muted-foreground">{selectedBaby.name}</p>
      </div>

      <Card className="mb-4">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              <CardTitle>Notifications</CardTitle>
            </div>
            <Switch
              checked={settings.enabled}
              onCheckedChange={(checked) => 
                updateSettingsMutation.mutate({ enabled: checked })
              }
            />
          </div>
          <p className="text-sm text-muted-foreground">
            {permissionStatus === 'granted' 
              ? 'Notifications are enabled'
              : 'Enable notifications to receive reminders'}
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          {permissionStatus !== 'granted' && (
            <Button onClick={requestPermission} className="w-full">
              Enable Notifications
            </Button>
          )}
          {permissionStatus === 'granted' && (
            <Button variant="outline" onClick={sendTestNotification} className="w-full">
              Send Test Notification
            </Button>
          )}
        </CardContent>
      </Card>

      <Card className="mb-4">
        <CardHeader>
          <CardTitle>Quiet Hours</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Start Time</Label>
              <Select
                value={settings.quiet_hours_start || '22:00'}
                onValueChange={(value) =>
                  updateSettingsMutation.mutate({ quiet_hours_start: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 24 }, (_, i) => {
                    const hour = i.toString().padStart(2, '0');
                    return (
                      <SelectItem key={hour} value={`${hour}:00`}>
                        {hour}:00
                      </SelectItem>
                    );
                  })}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>End Time</Label>
              <Select
                value={settings.quiet_hours_end || '07:00'}
                onValueChange={(value) =>
                  updateSettingsMutation.mutate({ quiet_hours_end: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 24 }, (_, i) => {
                    const hour = i.toString().padStart(2, '0');
                    return (
                      <SelectItem key={hour} value={`${hour}:00`}>
                        {hour}:00
                      </SelectItem>
                    );
                  })}
                </SelectContent>
              </Select>
            </div>
          </div>
          <p className="text-sm text-muted-foreground">
            No notifications will be sent during quiet hours
          </p>
        </CardContent>
      </Card>

      <Card className="mb-4">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Feed Reminders</CardTitle>
            <Switch
              checked={settings.feed_reminders_enabled}
              onCheckedChange={(checked) =>
                updateSettingsMutation.mutate({ feed_reminders_enabled: checked })
              }
            />
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <Label>Remind me if no feed logged in:</Label>
            <Select
              value={settings.feed_reminder_interval_hours.toString()}
              onValueChange={(value) =>
                updateSettingsMutation.mutate({ feed_reminder_interval_hours: parseInt(value) })
              }
              disabled={!settings.feed_reminders_enabled}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="2">2 hours</SelectItem>
                <SelectItem value="3">3 hours</SelectItem>
                <SelectItem value="4">4 hours</SelectItem>
                <SelectItem value="6">6 hours</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card className="mb-4">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Nap Window Reminders</CardTitle>
            <Switch
              checked={settings.nap_reminders_enabled}
              onCheckedChange={(checked) =>
                updateSettingsMutation.mutate({ nap_reminders_enabled: checked })
              }
            />
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <Label>Alert me before nap window:</Label>
            <Select
              value={settings.nap_window_reminder_minutes.toString()}
              onValueChange={(value) =>
                updateSettingsMutation.mutate({ nap_window_reminder_minutes: parseInt(value) })
              }
              disabled={!settings.nap_reminders_enabled}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="10">10 minutes</SelectItem>
                <SelectItem value="15">15 minutes</SelectItem>
                <SelectItem value="30">30 minutes</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card className="mb-4">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Diaper Reminders</CardTitle>
            <Switch
              checked={settings.diaper_reminders_enabled}
              onCheckedChange={(checked) =>
                updateSettingsMutation.mutate({ diaper_reminders_enabled: checked })
              }
            />
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <Label>Remind me if no change in:</Label>
            <Select
              value={settings.diaper_reminder_interval_hours.toString()}
              onValueChange={(value) =>
                updateSettingsMutation.mutate({ diaper_reminder_interval_hours: parseInt(value) })
              }
              disabled={!settings.diaper_reminders_enabled}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="2">2 hours</SelectItem>
                <SelectItem value="3">3 hours</SelectItem>
                <SelectItem value="4">4 hours</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Medication Reminders</CardTitle>
            <Switch
              checked={settings.medication_reminders_enabled}
              onCheckedChange={(checked) =>
                updateSettingsMutation.mutate({ medication_reminders_enabled: checked })
              }
            />
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Managed per medication in Health Records
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
