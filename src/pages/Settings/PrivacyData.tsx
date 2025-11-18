import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ChevronLeft, Download, FileText, Trash2 } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import { format, subDays } from 'date-fns';
import { toast } from 'sonner';
import { exportEventsCSV } from '@/lib/csvExport';
import { exportDaySummaryPDF } from '@/lib/pdfExport';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';

export default function PrivacyData() {
  const navigate = useNavigate();
  const { activeBabyId, setActiveBabyId } = useAppStore();
  const [deleteConfirm, setDeleteConfirm] = useState('');
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [isFinalDeleteOpen, setIsFinalDeleteOpen] = useState(false);
  
  // CSV export date range
  const [csvStartDate, setCsvStartDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
  const [csvEndDate, setCsvEndDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  
  // PDF export date
  const [pdfDate, setPdfDate] = useState(format(new Date(), 'yyyy-MM-dd'));

  const handleExportCSV = async () => {
    if (!activeBabyId) {
      toast.error('No baby selected');
      return;
    }

    try {
      const baby = await dataService.getBaby(activeBabyId);
      if (!baby) {
        toast.error('Baby not found');
        return;
      }

      await exportEventsCSV(
        activeBabyId,
        baby.name,
        new Date(csvStartDate),
        new Date(csvEndDate)
      );
      
      toast.success('CSV exported successfully');
    } catch (error) {
      console.error('CSV export error:', error);
      toast.error('Failed to export CSV');
    }
  };

  const handleExportPDF = async () => {
    if (!activeBabyId) {
      toast.error('No baby selected');
      return;
    }

    try {
      const baby = await dataService.getBaby(activeBabyId);
      if (!baby) {
        toast.error('Baby not found');
        return;
      }

      await exportDaySummaryPDF(baby, new Date(pdfDate));
      toast.success('PDF exported successfully');
    } catch (error) {
      console.error('PDF export error:', error);
      toast.error('Failed to export PDF');
    }
  };

  const handleDeleteClick = () => {
    if (deleteConfirm !== 'DELETE') {
      toast.error('Please type DELETE to confirm');
      return;
    }
    setIsDeleteDialogOpen(false);
    setIsFinalDeleteOpen(true);
  };

  const handleFinalDelete = async () => {
    await dataService.clearAllData();
    localStorage.clear();
    setActiveBabyId(null);
    toast.success('All data deleted');
    navigate('/onboarding-simple');
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={() => navigate('/settings')}>
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-2xl font-bold">Privacy & Data</h1>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Your Data, Your Control</CardTitle>
            <CardDescription>
              Your baby's data is stored securely and never sold to third parties. 
              You have full control to export, import, or delete your data at any time.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <Button 
              variant="link" 
              size="sm" 
              className="pl-0 h-auto"
              onClick={() => window.open('https://nestling.app/privacy', '_blank')}
            >
              Privacy Policy →
            </Button>
            <Button 
              variant="link" 
              size="sm" 
              className="pl-0 h-auto"
              onClick={() => window.open('https://nestling.app/terms', '_blank')}
            >
              Terms of Use →
            </Button>
            <Button 
              variant="link" 
              size="sm" 
              className="pl-0 h-auto"
              onClick={() => navigate('/settings/ai-data-sharing')}
            >
              AI & Data Sharing Settings →
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Download className="h-5 w-5" />
              Export Your Data (CSV)
            </CardTitle>
            <CardDescription>
              Download your baby's events in CSV format for a custom date range
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="csv-start-date">Start Date</Label>
                <Input
                  id="csv-start-date"
                  type="date"
                  value={csvStartDate}
                  onChange={(e) => setCsvStartDate(e.target.value)}
                  max={csvEndDate}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="csv-end-date">End Date</Label>
                <Input
                  id="csv-end-date"
                  type="date"
                  value={csvEndDate}
                  onChange={(e) => setCsvEndDate(e.target.value)}
                  min={csvStartDate}
                  max={format(new Date(), 'yyyy-MM-dd')}
                  className="mt-1"
                />
              </div>
            </div>
            <Button onClick={handleExportCSV} className="w-full">
              <Download className="mr-2 h-4 w-4" />
              Export CSV
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Export Daily Summary (PDF)
            </CardTitle>
            <CardDescription>
              Generate a PDF summary for any day
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="pdf-date">Select Date</Label>
              <Input
                id="pdf-date"
                type="date"
                value={pdfDate}
                onChange={(e) => setPdfDate(e.target.value)}
                max={format(new Date(), 'yyyy-MM-dd')}
                className="mt-1"
              />
            </div>
            <Button onClick={handleExportPDF} className="w-full">
              <FileText className="mr-2 h-4 w-4" />
              Export PDF
            </Button>
          </CardContent>
        </Card>

        <Card className="border-destructive">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-destructive">
              <Trash2 className="h-5 w-5" />
              Delete All Data
            </CardTitle>
            <CardDescription>
              Permanently delete all your data from this device. This action cannot be undone.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="delete-confirm">Type DELETE to confirm</Label>
              <Input
                id="delete-confirm"
                value={deleteConfirm}
                onChange={(e) => setDeleteConfirm(e.target.value)}
                placeholder="DELETE"
                className="mt-1 font-mono"
              />
            </div>
            <Button
              variant="destructive"
              onClick={() => setIsDeleteDialogOpen(true)}
              disabled={deleteConfirm !== 'DELETE'}
              className="w-full"
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Delete All Data
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground text-center">
              <strong>Important:</strong> Nestling is a care tracking tool, not medical advice. 
              Always consult healthcare professionals for medical decisions.
            </p>
          </CardContent>
        </Card>
      </div>

      <ConfirmDialog
        open={isDeleteDialogOpen}
        onOpenChange={setIsDeleteDialogOpen}
        onConfirm={handleDeleteClick}
        title="Are you sure?"
        description="You typed DELETE. Click continue to proceed with permanent deletion."
        confirmText="Continue"
        variant="destructive"
      />

      <ConfirmDialog
        open={isFinalDeleteOpen}
        onOpenChange={setIsFinalDeleteOpen}
        onConfirm={handleFinalDelete}
        title="Final Confirmation"
        description="This will permanently delete ALL your data from this device. This action CANNOT be undone. Are you absolutely sure?"
        confirmText="Yes, Delete Everything"
        variant="destructive"
      />
    </div>
  );
}
