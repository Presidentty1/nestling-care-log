import { useNavigate } from 'react-router-dom';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { useAuth } from '@/hooks/useAuth';
import { LogOut, Users, Bell, Shield, Info, ChevronRight } from 'lucide-react';
import { toast } from 'sonner';

export default function Settings() {
  const { signOut, user } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    const { error } = await signOut();
    if (error) {
      toast.error('Failed to sign out');
    }
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <h1 className="text-2xl font-bold">Settings</h1>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Account</CardTitle>
            <CardDescription>{user?.email}</CardDescription>
          </CardHeader>
          <CardContent>
            <Button 
              variant="outline" 
              className="w-full justify-start"
              onClick={handleSignOut}
            >
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Users className="h-5 w-5" />
              Family & Caregivers
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Card className="cursor-pointer hover:bg-accent border-0 shadow-none" onClick={() => navigate('/settings/caregivers')}>
              <CardContent className="p-4 flex items-center justify-between">
                <span className="font-medium">Manage Caregivers</span>
                <ChevronRight className="h-5 w-5 text-muted-foreground" />
              </CardContent>
            </Card>
            <Button 
              variant="outline" 
              className="w-full justify-start"
              onClick={() => toast.info('Baby profiles coming soon')}
            >
              Manage Babies
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Notifications
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Button 
              variant="outline" 
              className="w-full justify-start"
              onClick={() => navigate('/settings/notifications')}
            >
              Configure Reminders
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Health & Growth</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <Button variant="outline" className="w-full justify-start" onClick={() => navigate('/growth')}>
              Growth Tracker
            </Button>
            <Button variant="outline" className="w-full justify-start" onClick={() => navigate('/health')}>
              Health Records
            </Button>
            <Button variant="outline" className="w-full justify-start" onClick={() => navigate('/milestones')}>
              Milestones
            </Button>
            <Button variant="outline" className="w-full justify-start" onClick={() => navigate('/photos')}>
              Photo Gallery
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Privacy & Data
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button 
              variant="outline" 
              className="w-full justify-start"
              onClick={() => toast.info('Data download coming soon')}
            >
              Download My Data
            </Button>
            <Separator />
            <Button 
              variant="outline" 
              className="w-full justify-start text-destructive hover:text-destructive"
              onClick={() => toast.info('Account deletion coming soon')}
            >
              Delete Account
            </Button>
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
            <div className="text-sm space-y-1">
              <p className="font-medium">Nestling v1.0.0</p>
              <p className="text-muted-foreground text-xs">
                The fastest shared baby logger
              </p>
            </div>
            <Separator className="my-3" />
            <div className="text-xs text-muted-foreground space-y-1">
              <p>
                <strong>Disclaimer:</strong> Nestling provides general wellness guidance only 
                and is not a medical device. It does not diagnose, treat, cure, or prevent 
                any disease. If you're worried about your baby's health, contact your 
                pediatrician or local emergency services immediately.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
