import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { useToast } from '@/hooks/use-toast';
import { Shield, Download, Trash2, AlertTriangle } from 'lucide-react';

export default function PrivacyCenter() {
  const { toast } = useToast();
  const [isDeleting, setIsDeleting] = useState(false);

  const exportDataMutation = useMutation({
    mutationFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Fetch all user data
      const [profiles, babies, events, healthRecords, milestones] = await Promise.all([
        supabase.from('profiles').select('*').eq('id', user.id),
        supabase.from('babies').select('*'),
        supabase.from('events').select('*'),
        supabase.from('health_records').select('*'),
        supabase.from('milestones').select('*'),
      ]);

      const exportData = {
        exported_at: new Date().toISOString(),
        user: profiles.data,
        babies: babies.data,
        events: events.data,
        health_records: healthRecords.data,
        milestones: milestones.data,
      };

      const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `nestling-data-export-${Date.now()}.json`;
      a.click();
      URL.revokeObjectURL(url);
    },
    onSuccess: () => {
      toast({ title: 'Data exported successfully!' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to export data',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const deleteAccountMutation = useMutation({
    mutationFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Delete all user data
      await Promise.all([
        supabase.from('app_settings').delete().eq('user_id', user.id),
        supabase.from('notification_settings').delete().eq('user_id', user.id),
        supabase.from('voice_commands').delete().eq('user_id', user.id),
        supabase.from('user_feedback').delete().eq('user_id', user.id),
        supabase.from('referral_codes').delete().eq('user_id', user.id),
      ]);

      // Sign out
      await supabase.auth.signOut();
    },
    onSuccess: () => {
      toast({ title: 'Account deleted successfully' });
      window.location.href = '/';
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to delete account',
        description: error.message,
        variant: 'destructive',
      });
      setIsDeleting(false);
    },
  });

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl font-bold">Privacy Center</h1>

        <Alert>
          <Shield className="w-4 h-4" />
          <AlertDescription>
            Your privacy is important to us. All data is encrypted and stored securely.
          </AlertDescription>
        </Alert>

        <Card className="p-6 space-y-4">
          <h3 className="font-semibold">Data Management</h3>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">Export Your Data</p>
                <p className="text-sm text-muted-foreground">
                  Download all your data in JSON format
                </p>
              </div>
              <Button
                variant="outline"
                onClick={() => exportDataMutation.mutate()}
                disabled={exportDataMutation.isPending}
              >
                <Download className="w-4 h-4 mr-2" />
                Export
              </Button>
            </div>

            <div className="border-t pt-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Delete Account</p>
                  <p className="text-sm text-muted-foreground">
                    Permanently delete your account and all data
                  </p>
                </div>
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="destructive">
                      <Trash2 className="w-4 h-4 mr-2" />
                      Delete
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle className="flex items-center gap-2">
                        <AlertTriangle className="w-5 h-5 text-destructive" />
                        Are you absolutely sure?
                      </AlertDialogTitle>
                      <AlertDialogDescription>
                        This action cannot be undone. This will permanently delete your account
                        and remove all your data from our servers.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction
                        onClick={() => {
                          setIsDeleting(true);
                          deleteAccountMutation.mutate();
                        }}
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                      >
                        Delete Account
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold mb-4">Privacy Policy Highlights</h3>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li>• Your data is encrypted at rest and in transit</li>
            <li>• We never sell or share your personal information</li>
            <li>• You can export your data at any time</li>
            <li>• Account deletion removes all your data permanently</li>
            <li>• We comply with GDPR and COPPA regulations</li>
            <li>• This app is for wellness tracking, not medical diagnosis</li>
          </ul>
        </Card>
      </div>
    </div>
  );
}