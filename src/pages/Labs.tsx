import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Mic, AlertCircle, Settings } from 'lucide-react';
import { toast } from 'sonner';
import { useQuery } from '@tanstack/react-query';
import { aiPreferencesService } from '@/services/aiPreferencesService';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';

export default function Labs() {
  const { user } = useAuth();
  const navigate = useNavigate();
  
  const { data: aiEnabled } = useQuery({
    queryKey: ['ai-preferences', user?.id],
    queryFn: async () => {
      if (!user) return false;
      return await aiPreferencesService.canUseAI(user.id);
    },
    enabled: !!user,
  });

  const handleRecordCry = () => {
    if (!aiEnabled) {
      toast.error('Enable AI features in Settings to use Cry Insights');
      return;
    }
    toast.info('Cry Insights recording will be available soon');
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div>
          <h1 className="text-2xl font-bold">Labs</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Experimental features to help understand your baby
          </p>
        </div>

        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            Features in Labs are experimental and for guidance only. 
            They are NOT medical advice. If you're worried about your baby's health, 
            contact your pediatrician or local emergency services.
          </AlertDescription>
        </Alert>

        {!aiEnabled && (
          <Alert>
            <Settings className="h-4 w-4" />
            <AlertDescription className="flex items-center justify-between">
              <span>AI features are disabled. Enable them in Settings to use Cry Insights.</span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigate('/settings/ai-data-sharing')}
              >
                Enable
              </Button>
            </AlertDescription>
          </Alert>
        )}

        <Card>
          <CardHeader>
            <div className="flex items-start justify-between">
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <CardTitle>Cry Insights</CardTitle>
                  <Badge variant="secondary">Beta</Badge>
                </div>
                <CardDescription>
                  Record your baby's cry for AI-powered insights
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="bg-surface rounded-lg p-4 space-y-2">
              <h4 className="font-medium text-sm">How it works</h4>
              <p className="text-sm text-muted-foreground">
                When your baby cries, tap the button below to record for 10-20 seconds. 
                Our AI will analyze the cry pattern and suggest possible reasons 
                (tired, hungry, uncomfortable, etc.).
              </p>
            </div>

            <Button 
              onClick={handleRecordCry}
              className="w-full h-16"
              variant="secondary"
              disabled={!aiEnabled}
            >
              <Mic className="mr-2 h-5 w-5" />
              Record Cry (10-20 sec) {!aiEnabled && '(Disabled)'}
            </Button>

            <Alert>
              <AlertDescription className="text-xs">
                <strong>Privacy:</strong> Audio is processed locally and not stored. 
                Only metadata is saved for your reference.
              </AlertDescription>
            </Alert>
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
