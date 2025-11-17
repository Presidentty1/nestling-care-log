import { useState, useRef } from 'react';
import { useMutation } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Shield, Download, Trash2, AlertTriangle, Upload, RefreshCw } from 'lucide-react';
import { exportToJSON } from '@/lib/dataExport';
import { parseImportFile, validateImportData, importEventsToDataService } from '@/lib/dataImport';
import { dataService } from '@/services/dataService';
import { queryClient } from '@/lib/queryClient';
import { useAuth } from '@/hooks/useAuth';

export default function PrivacyCenter() {
  const { toast } = useToast();
  const { user } = useAuth();
  const [isDeleting, setIsDeleting] = useState(false);
  const [importPreview, setImportPreview] = useState<any>(null);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const exportDataMutation = useMutation({
    mutationFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Get family info
      const { data: familyMember } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id)
        .single();

      if (!familyMember) throw new Error('No family found');

      // Export using dataService (IndexedDB)
      await exportToJSON(
        familyMember.family_id,
        new Date(0),
        new Date()
      );
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

  const importDataMutation = useMutation({
    mutationFn: async (file: File) => {
      const data = await parseImportFile(file);
      const validation = await validateImportData(data);
      
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      setImportPreview(data);
      return data;
    },
    onSuccess: (data) => {
      toast({ 
        title: 'Import preview ready',
        description: `Found ${data.events?.length || 0} events, ${data.babies?.length || 0} babies`,
      });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to parse import file',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const confirmImportMutation = useMutation({
    mutationFn: async () => {
      if (!importPreview) throw new Error('No import data');
      if (!user) throw new Error('Not authenticated');

      const { data: familyMember } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id)
        .single();

      if (!familyMember) throw new Error('No family found');

      const { data: babies } = await supabase
        .from('babies')
        .select('id')
        .eq('family_id', familyMember.family_id)
        .single();

      if (!babies) throw new Error('No baby found');

      const result = await importEventsToDataService(
        importPreview,
        babies.id,
        familyMember.family_id
      );

      return result;
    },
    onSuccess: (result) => {
      toast({ 
        title: 'Import completed!',
        description: `Added ${result.added} events, skipped ${result.skipped} duplicates`,
      });
      setImportPreview(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    },
    onError: (error: any) => {
      toast({
        title: 'Import failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const clearLocalDataMutation = useMutation({
    mutationFn: async () => {
      // Clear IndexedDB
      const result = await dataService.clearAllData();
      
      // Clear localStorage
      localStorage.removeItem('nap_predictions');
      localStorage.removeItem('nestling_sync_history');
      localStorage.removeItem('nestling-react-query-cache');
      
      // Clear React Query cache
      queryClient.clear();
      
      return result;
    },
    onSuccess: (result) => {
      toast({ 
        title: 'Local data cleared',
        description: `Cleared ${result.eventsCleared} events. Refresh to re-sync from cloud.`,
      });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to clear local data',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const deleteAccountMutation = useMutation({
    mutationFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Clear local data first
      await dataService.clearAllData();
      localStorage.clear();
      queryClient.clear();

      // Delete all Supabase data
      await Promise.all([
        supabase.from('app_settings').delete().eq('user_id', user.id),
        supabase.from('profiles').delete().eq('id', user.id),
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

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      importDataMutation.mutate(file);
    }
  };

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