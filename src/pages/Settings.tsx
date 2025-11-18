import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { useAppStore } from '@/store/appStore';
import { Users, Bell, Shield, ChevronRight, Baby, FileText, Info, Sparkles, Heart } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

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
            <button
              className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors text-left"
              onClick={() => navigate('/privacy')}
            >
              <div className="flex items-center gap-3">
                <Shield className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">Privacy Policy</span>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </button>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-primary/10 via-primary/5 to-background border-primary/20">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-primary" />
              Nestling Pro
            </CardTitle>
            <CardDescription>Unlock advanced features</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <ul className="space-y-2">
              <li className="flex items-start gap-2 text-sm">
                <span className="text-primary">✓</span>
                <span>AI nap predictions with wake window analysis</span>
              </li>
              <li className="flex items-start gap-2 text-sm">
                <span className="text-primary">✓</span>
                <span>Advanced reminders & notifications</span>
              </li>
              <li className="flex items-start gap-2 text-sm">
                <span className="text-primary">✓</span>
                <span>CSV export to share with pediatrician</span>
              </li>
              <li className="flex items-start gap-2 text-sm">
                <span className="text-primary">✓</span>
                <span>Priority support</span>
              </li>
            </ul>
            <div className="pt-2">
              <p className="text-sm text-muted-foreground mb-3">
                <strong className="text-primary">$39.99/yr</strong> (founder launch special)
                <br />
                <span className="text-xs">Also available: $4.99/mo • $79.99 lifetime</span>
              </p>
              <Button disabled className="w-full" variant="default">
                Coming Soon
              </Button>
            </div>
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
                <Label htmlFor="caregiver-mode" className="text-base">Caregiver Mode</Label>
                <p className="text-sm text-muted-foreground">
                  Larger text and buttons for easier use
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
          <CardContent className="space-y-3">
            <div className="text-sm text-muted-foreground space-y-2">
              <p className="flex items-center justify-between">
                <span>App Version</span>
                <span className="font-medium">1.0.0</span>
              </p>
              <Separator />
              <div className="p-3 bg-muted rounded-lg space-y-2">
                <div className="flex items-start gap-2">
                  <span className="text-lg">⚕️</span>
                  <div className="flex-1">
                    <p className="font-medium text-foreground text-sm">Medical Disclaimer</p>
                    <p className="text-xs leading-relaxed mt-1">
                      Nestling is not a medical device. Always consult your pediatrician or healthcare 
                      provider for medical advice, diagnosis, or treatment. AI features provide general 
                      information only and should not replace professional medical judgment.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
