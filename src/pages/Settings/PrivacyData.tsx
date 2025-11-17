import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';
import { ChevronLeft, Download, FileText, Trash2 } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import { format } from 'date-fns';
import jsPDF from 'jspdf';
import { toast } from 'sonner';

export default function PrivacyData() {
  const navigate = useNavigate();
  const { activeBabyId, setActiveBabyId } = useAppStore();
  const [deleteConfirm, setDeleteConfirm] = useState('');
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);

  const exportCSV = async () => {
    if (!activeBabyId) return;

    const events = await dataService.getAllEvents();
    const babyEvents = events.filter(e => e.babyId === activeBabyId);

    const csv = [
      ['Date', 'Type', 'Subtype', 'Amount', 'Unit', 'Start', 'End', 'Duration (min)', 'Notes'].join(','),
      ...babyEvents.map(e => [
        format(new Date(e.startTime), 'yyyy-MM-dd'),
        e.type,
        e.subtype || '',
        e.amount || '',
        e.unit || '',
        format(new Date(e.startTime), 'HH:mm'),
        e.endTime ? format(new Date(e.endTime), 'HH:mm') : '',
        e.durationMin || '',
        e.notes ? `"${e.notes.replace(/"/g, '""')}"` : '',
      ].join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `nestling-export-${format(new Date(), 'yyyy-MM-dd')}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    
    toast.success('CSV exported');
  };

  const exportPDF = async () => {
    if (!activeBabyId) return;

    const baby = await dataService.getBaby(activeBabyId);
    if (!baby) return;

    const today = format(new Date(), 'yyyy-MM-dd');
    const summary = await dataService.getDaySummary(activeBabyId, today);

    const doc = new jsPDF();
    
    doc.setFontSize(18);
    doc.text(`${baby.name}'s Daily Summary`, 20, 20);
    
    doc.setFontSize(12);
    doc.text(`Date: ${format(new Date(), 'MMMM d, yyyy')}`, 20, 35);
    
    doc.text(`Feeds: ${summary.feedCount}`, 20, 50);
    doc.text(`Total: ${summary.totalMl} ml`, 20, 57);
    
    doc.text(`Sleep: ${Math.floor(summary.sleepMinutes / 60)}h ${summary.sleepMinutes % 60}m`, 20, 70);
    
    doc.text(`Diapers: ${summary.diaperTotal}`, 20, 83);
    doc.text(`  Wet: ${summary.diaperWet}`, 30, 90);
    doc.text(`  Dirty: ${summary.diaperDirty}`, 30, 97);
    
    doc.save(`nestling-summary-${today}.pdf`);
    toast.success('PDF exported');
  };

  const handleDeleteAllData = async () => {
    if (deleteConfirm !== 'DELETE') {
      toast.error('Please type DELETE to confirm');
      return;
    }

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
            <CardTitle>Export Your Data</CardTitle>
            <CardDescription>
              Download your baby's data for your records
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button onClick={exportCSV} variant="outline" className="w-full justify-start">
              <Download className="mr-2 h-4 w-4" />
              Export as CSV
            </Button>
            <Button onClick={exportPDF} variant="outline" className="w-full justify-start">
              <FileText className="mr-2 h-4 w-4" />
              Export Today's Summary (PDF)
            </Button>
          </CardContent>
        </Card>

        <Card className="border-destructive">
          <CardHeader>
            <CardTitle className="text-destructive">Danger Zone</CardTitle>
            <CardDescription>
              Permanently delete all data. This action cannot be undone.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button
              variant="destructive"
              className="w-full"
              onClick={() => setIsDeleteDialogOpen(true)}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Delete All Data
            </Button>
          </CardContent>
        </Card>
      </div>

      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete All Data?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete ALL data including babies, events, and settings.
              This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div className="py-4">
            <Label>Type DELETE to confirm</Label>
            <Input
              value={deleteConfirm}
              onChange={(e) => setDeleteConfirm(e.target.value)}
              placeholder="DELETE"
            />
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setDeleteConfirm('')}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteAllData}
              disabled={deleteConfirm !== 'DELETE'}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete Everything
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
