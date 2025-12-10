import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Sparkles, Shield, Database, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { useAuth } from '@/hooks/useAuth';
import { aiPreferencesService } from '@/services/aiPreferencesService';
import { toast } from 'sonner';
import { MobileContainer } from '@/components/layout/MobileContainer';
import { track } from '@/analytics/analytics';

export default function AIDataSharing() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [enabled, setEnabled] = useState(true);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadPreferences();
  }, [user]);

  async function loadPreferences() {
    if (!user) return;

    try {
      const prefs = await aiPreferencesService.getPreferences(user.id);
      setEnabled(prefs.aiDataSharingEnabled);
    } catch (error) {
      console.error('Error loading AI preferences:', error);
      toast.error('Could not load preferences');
    } finally {
      setLoading(false);
    }
  }

  async function handleToggle(value: boolean) {
    if (!user) return;

    setSaving(true);
    try {
      await aiPreferencesService.setPreferences(user.id, value);
      setEnabled(value);

      // Track analytics
      track('ai_consent_changed', {
        enabled: value,
        source: 'settings',
      });

      toast.success(value ? 'AI features enabled' : 'AI features disabled');
    } catch (error) {
      console.error('Error saving AI preferences:', error);
      toast.error('Could not save preferences');
    } finally {
      setSaving(false);
    }
  }

  return (
    <MobileContainer>
      {/* Header */}
      <header className='flex items-center gap-3 mb-6'>
        <Button variant='ghost' size='icon' onClick={() => navigate(-1)} className='shrink-0'>
          <ArrowLeft className='h-5 w-5' />
        </Button>
        <div className='flex items-center gap-2'>
          <Sparkles className='h-6 w-6 text-primary' />
          <h1 className='text-2xl font-bold'>AI & Data Sharing</h1>
        </div>
      </header>

      {/* Main Toggle Card */}
      <Card className='mb-4'>
        <CardHeader>
          <div className='flex items-start justify-between gap-4'>
            <div className='flex-1'>
              <CardTitle className='text-lg mb-2'>Allow AI features to use my data</CardTitle>
              <CardDescription className='text-sm leading-relaxed'>
                Baby logs and optional audio may be sent to our AI provider (Google Gemini) to
                generate predictions, cry analysis, and personalized advice. Your data is never sold
                or used for advertising.
              </CardDescription>
            </div>
            <Switch
              checked={enabled}
              onCheckedChange={handleToggle}
              disabled={loading || saving}
              className='shrink-0'
            />
          </div>
        </CardHeader>
      </Card>

      {/* Info Cards */}
      <div className='space-y-4 mb-6'>
        <Card>
          <CardHeader className='pb-3'>
            <CardTitle className='text-base flex items-center gap-2'>
              <Database className='h-4 w-4 text-primary' />
              What data is shared?
            </CardTitle>
          </CardHeader>
          <CardContent className='text-sm text-muted-foreground space-y-2'>
            <p>When AI features are enabled, we share:</p>
            <ul className='list-disc pl-5 space-y-1'>
              <li>Baby's age and profile information</li>
              <li>Recent event history (last 7 days)</li>
              <li>Optional audio recordings for cry analysis</li>
              <li>Your questions to the AI Assistant</li>
            </ul>
            <p className='mt-3 text-xs'>
              Data is sent securely and processed in real-time. We do not store your data on AI
              provider servers.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className='pb-3'>
            <CardTitle className='text-base flex items-center gap-2'>
              <Sparkles className='h-4 w-4 text-primary' />
              How is it used?
            </CardTitle>
          </CardHeader>
          <CardContent className='text-sm text-muted-foreground space-y-2'>
            <p>AI features provide:</p>
            <ul className='list-disc pl-5 space-y-1'>
              <li>
                <strong>Smart Predictions:</strong> Next nap/feed times based on patterns
              </li>
              <li>
                <strong>Cry Insights:</strong> Possible causes and suggestions
              </li>
              <li>
                <strong>AI Assistant:</strong> Answers to parenting questions
              </li>
            </ul>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className='pb-3'>
            <CardTitle className='text-base flex items-center gap-2'>
              <Shield className='h-4 w-4 text-primary' />
              Privacy & Control
            </CardTitle>
          </CardHeader>
          <CardContent className='text-sm text-muted-foreground space-y-2'>
            <ul className='list-disc pl-5 space-y-1'>
              <li>You can disable AI features anytime</li>
              <li>Your event logs remain private in your account</li>
              <li>Export or delete your data anytime in Privacy Center</li>
              <li>We comply with GDPR and CCPA privacy regulations</li>
            </ul>
            <Button
              variant='link'
              size='sm'
              className='pl-0 h-auto mt-2'
              onClick={() => navigate('/settings/privacy-data')}
            >
              Go to Privacy Center →
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Medical Disclaimer */}
      <MedicalDisclaimer variant='ai' className='mb-6' />

      {/* Warning when disabled */}
      {!enabled && (
        <Card className='border-warning bg-warning/5'>
          <CardContent className='pt-6'>
            <div className='flex gap-3'>
              <AlertCircle className='h-5 w-5 text-warning shrink-0 mt-0.5' />
              <div className='space-y-2'>
                <p className='font-medium'>AI features are currently disabled</p>
                <p className='text-sm text-muted-foreground'>
                  Smart Predictions, Cry Analysis, and AI Assistant will not work until you enable
                  AI data sharing.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </MobileContainer>
  );
}
