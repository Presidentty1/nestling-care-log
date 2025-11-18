import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { MobileNav } from '@/components/MobileNav';
import { ArrowLeft, Mic, Zap } from 'lucide-react';
import { toast } from 'sonner';

export default function ShortcutsSettings() {
  const navigate = useNavigate();
  const [voiceEnabled, setVoiceEnabled] = useState(() => {
    const stored = localStorage.getItem('voice_enabled');
    return stored !== null ? JSON.parse(stored) : true;
  });
  const [quickActionsEnabled, setQuickActionsEnabled] = useState(() => {
    const stored = localStorage.getItem('quick_actions_enabled');
    return stored !== null ? JSON.parse(stored) : true;
  });
  const [floatingButtonEnabled, setFloatingButtonEnabled] = useState(() => {
    const stored = localStorage.getItem('floating_button_enabled');
    return stored !== null ? JSON.parse(stored) : true;
  });

  const handleSave = () => {
    localStorage.setItem('voice_enabled', JSON.stringify(voiceEnabled));
    localStorage.setItem('quick_actions_enabled', JSON.stringify(quickActionsEnabled));
    localStorage.setItem('floating_button_enabled', JSON.stringify(floatingButtonEnabled));
    
    toast.success('Settings saved');
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center gap-4">
            <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">Quick Actions & Shortcuts</h1>
              <p className="text-sm text-muted-foreground">Customize your quick logging options</p>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto p-4 space-y-4 max-w-2xl">
        <Card className="p-6 space-y-6">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <Mic className="h-5 w-5 text-primary" />
              <h3 className="font-semibold">Voice Logging</h3>
            </div>
            <p className="text-sm text-muted-foreground mb-4">
              Enable hands-free event logging with voice commands
            </p>
            <div className="flex items-center justify-between">
              <Label htmlFor="voice-enabled">Enable Voice Logging</Label>
              <Switch
                id="voice-enabled"
                checked={voiceEnabled}
                onCheckedChange={setVoiceEnabled}
              />
            </div>
          </div>

          <div>
            <div className="flex items-center gap-3 mb-2">
              <Zap className="h-5 w-5 text-primary" />
              <h3 className="font-semibold">Quick Actions Widget</h3>
            </div>
            <p className="text-sm text-muted-foreground mb-4">
              Show quick action buttons on home screen
            </p>
            <div className="flex items-center justify-between">
              <Label htmlFor="quick-actions">Enable Quick Actions</Label>
              <Switch
                id="quick-actions"
                checked={quickActionsEnabled}
                onCheckedChange={setQuickActionsEnabled}
              />
            </div>
          </div>

          <div>
            <h3 className="font-semibold mb-2">Floating Action Button</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Show floating microphone button for quick voice logging
            </p>
            <div className="flex items-center justify-between">
              <Label htmlFor="floating-button">Enable Floating Button</Label>
              <Switch
                id="floating-button"
                checked={floatingButtonEnabled}
                onCheckedChange={setFloatingButtonEnabled}
              />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold mb-3">Voice Command Examples</h3>
          <div className="space-y-2 text-sm">
            <div className="p-3 bg-muted rounded">
              <p className="font-medium mb-1">Feeding:</p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>"Log bottle feed 120 ml"</li>
                <li>"Breast feeding session"</li>
                <li>"Fed baby 4 ounces"</li>
              </ul>
            </div>
            <div className="p-3 bg-muted rounded">
              <p className="font-medium mb-1">Diaper:</p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>"Wet diaper"</li>
                <li>"Dirty diaper"</li>
                <li>"Baby had a diaper change"</li>
              </ul>
            </div>
            <div className="p-3 bg-muted rounded">
              <p className="font-medium mb-1">Sleep:</p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>"Log nap 2 hours"</li>
                <li>"Baby sleeping"</li>
                <li>"Start sleep timer"</li>
              </ul>
            </div>
          </div>
        </Card>

        <Button onClick={handleSave} className="w-full">
          Save Settings
        </Button>
      </div>

      <MobileNav />
    </div>
  );
}