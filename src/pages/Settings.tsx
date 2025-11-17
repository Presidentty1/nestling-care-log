import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { useAppStore } from '@/store/appStore';
import { Users, Bell, Shield, ChevronRight, Baby, FileText, Info } from 'lucide-react';

export default function Settings() {
  const navigate = useNavigate();
  const { caregiverMode, setCaregiverMode } = useAppStore();

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <h1 className="text-2xl font-bold">Settings</h1>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Users className="h-5 w-5" />
              Family & Caregivers
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <button
              className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors text-left"
              onClick={() => navigate('/settings/babies')}
            >
              <div className="flex items-center gap-3">
                <Baby className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">Manage Babies</span>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </button>
            <button
              className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors text-left"
              onClick={() => navigate('/settings/caregivers')}
            >
              <div className="flex items-center gap-3">
                <Users className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">Manage Caregivers</span>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Notifications & Reminders
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <button
              className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors text-left"
              onClick={() => navigate('/settings/notifications')}
            >
              <div className="flex items-center gap-3">
                <Bell className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">Notification Settings</span>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Privacy & Data
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <button
              className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors text-left"
              onClick={() => navigate('/settings/privacy')}
            >
              <div className="flex items-center gap-3">
                <FileText className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">Export & Delete Data</span>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Accessibility</CardTitle>
            <CardDescription>Adjust settings for easier use</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="caregiver-mode">Caregiver Mode</Label>
                <p className="text-sm text-muted-foreground">
                  Larger text and buttons for easier viewing
                </p>
              </div>
              <Switch
                id="caregiver-mode"
                checked={caregiverMode}
                onCheckedChange={setCaregiverMode}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Info className="h-5 w-5" />
              About
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="text-sm text-muted-foreground">Nestling Care Log v1.0.0</p>
            <p className="text-sm text-muted-foreground">
              A local-first baby tracking app for modern parents
            </p>
            <Separator className="my-3" />
            <p className="text-xs text-muted-foreground">
              All your data is stored locally on your device and never leaves your device.
            </p>
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
