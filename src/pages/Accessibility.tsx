import { useState, useEffect } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { Eye, Type, Moon, Sun } from 'lucide-react';
import { appSettingsService } from '@/services/appSettingsService';
import { useAuth } from '@/hooks/useAuth';

export default function Accessibility() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const [settings, setSettings] = useState({
    theme: 'system' as 'light' | 'dark' | 'system',
    font_size: 'medium' as 'small' | 'medium' | 'large' | 'xlarge',
    caregiver_mode: false,
  });

  const { data: userSettings } = useQuery({
    queryKey: ['app-settings', user?.id],
    queryFn: async () => {
      if (!user) return null;
      return await appSettingsService.getAppSettings(user.id);
    },
    enabled: !!user,
  });

  useEffect(() => {
    if (userSettings) {
      setSettings({
        theme: userSettings.theme || 'system',
        font_size: userSettings.font_size || 'medium',
        caregiver_mode: userSettings.caregiver_mode || false,
      });
      applySettings(userSettings);
    }
  }, [userSettings]);

  const applySettings = (settings: any) => {
    // Apply theme with smooth transition
    const root = document.documentElement;

    // Use requestAnimationFrame for smoother theme switching
    requestAnimationFrame(() => {
      if (settings.theme === 'dark') {
        root.classList.add('dark');
        localStorage.setItem('theme', 'dark');
      } else if (settings.theme === 'light') {
        root.classList.remove('dark');
        localStorage.setItem('theme', 'light');
      } else {
        // System theme
        localStorage.removeItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        if (prefersDark) {
          root.classList.add('dark');
        } else {
          root.classList.remove('dark');
        }
      }
    });

    // Apply font size
    root.style.fontSize =
      {
        small: '14px',
        medium: '16px',
        large: '18px',
        xlarge: '20px',
      }[settings.font_size] || '16px';
  };

  const saveMutation = useMutation({
    mutationFn: async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      await appSettingsService.createOrUpdateAppSettings({
        theme: settings.theme,
        font_size: settings.font_size,
        caregiver_mode: settings.caregiver_mode,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['app-settings'] });
      applySettings(settings);
      toast({ title: 'Settings saved!' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to save settings',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  return (
    <div className='min-h-screen bg-background p-4'>
      <div className='max-w-2xl mx-auto space-y-6'>
        <h1 className='text-3xl font-bold'>Accessibility</h1>

        <Card className='p-6 space-y-6'>
          <div className='space-y-4'>
            <div className='flex items-center justify-between'>
              <div className='space-y-0.5'>
                <Label className='flex items-center gap-2'>
                  {settings.theme === 'dark' ? (
                    <Moon className='w-4 h-4' />
                  ) : (
                    <Sun className='w-4 h-4' />
                  )}
                  Theme
                </Label>
                <p className='text-sm text-muted-foreground'>Choose your preferred color scheme</p>
              </div>
              <Select
                value={settings.theme}
                onValueChange={value => setSettings({ ...settings, theme: value })}
              >
                <SelectTrigger className='w-32'>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value='light'>Light</SelectItem>
                  <SelectItem value='dark'>Dark</SelectItem>
                  <SelectItem value='system'>System</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className='flex items-center justify-between'>
              <div className='space-y-0.5'>
                <Label className='flex items-center gap-2'>
                  <Type className='w-4 h-4' />
                  Font Size
                </Label>
                <p className='text-sm text-muted-foreground'>Adjust text size for readability</p>
              </div>
              <Select
                value={settings.font_size}
                onValueChange={value => setSettings({ ...settings, font_size: value })}
              >
                <SelectTrigger className='w-32'>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value='small'>Small</SelectItem>
                  <SelectItem value='medium'>Medium</SelectItem>
                  <SelectItem value='large'>Large</SelectItem>
                  <SelectItem value='xlarge'>X-Large</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className='flex items-center justify-between'>
              <div className='space-y-0.5'>
                <Label className='flex items-center gap-2'>
                  <Eye className='w-4 h-4' />
                  Caregiver Mode
                </Label>
                <p className='text-sm text-muted-foreground'>
                  Larger buttons and simplified interface
                </p>
              </div>
              <Switch
                checked={settings.caregiver_mode}
                onCheckedChange={checked => setSettings({ ...settings, caregiver_mode: checked })}
              />
            </div>
          </div>

          <Button
            className='w-full'
            onClick={() => saveMutation.mutate()}
            disabled={saveMutation.isPending}
          >
            Save Settings
          </Button>
        </Card>

        <Card className='p-6'>
          <h3 className='font-semibold mb-4'>Accessibility Features</h3>
          <ul className='space-y-2 text-sm text-muted-foreground'>
            <li>✓ High contrast mode support</li>
            <li>✓ Screen reader optimized</li>
            <li>✓ Keyboard navigation</li>
            <li>✓ WCAG AA compliant colors</li>
            <li>✓ Touch targets ≥ 44px</li>
            <li>✓ Clear focus indicators</li>
          </ul>
        </Card>
      </div>
    </div>
  );
}
