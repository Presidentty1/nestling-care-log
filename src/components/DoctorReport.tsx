import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { FileText, Share, Download, Mail, MessageCircle } from 'lucide-react';
import { toast } from 'sonner';
import type { Baby } from '@/services/babyService';
import { exportWeeklyReport } from '@/lib/reportExport';
import { differenceInMonths, format } from 'date-fns';

interface DoctorReportProps {
  baby: Baby;
  className?: string;
}

export function DoctorReport({ baby, className }: DoctorReportProps) {
  const [isGenerating, setIsGenerating] = useState(false);
  const [isOpen, setIsOpen] = useState(false);

  const handleGenerateReport = async () => {
    setIsGenerating(true);
    try {
      await exportWeeklyReport(baby);
      toast.success('Report downloaded successfully!');
    } catch (error) {
      console.error('Error generating report:', error);
      toast.error('Failed to generate report. Please try again.');
    } finally {
      setIsGenerating(false);
    }
  };

  const handleShare = async () => {
    setIsGenerating(true);
    try {
      await exportWeeklyReport(baby);

      // Try native share API first
      if (navigator.share) {
        const fileName = `${baby.name}_weekly_report_${new Date().toISOString().split('T')[0]}.pdf`;
        // Note: In a real implementation, we'd need to get the blob from exportWeeklyReport
        // For now, we'll just show the download toast
        toast.success('Report generated and ready to share!');
      } else {
        // Fallback to download
        await exportWeeklyReport(baby);
        toast.success('Report downloaded! You can share it via email or messaging apps.');
      }
    } catch (error) {
      console.error('Error sharing report:', error);
      toast.error('Failed to share report. Please try again.');
    } finally {
      setIsGenerating(false);
      setIsOpen(false);
    }
  };

  const babyAge = differenceInMonths(new Date(), new Date(baby.date_of_birth));
  const reportPeriod = `${format(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), 'MMM d')} - ${format(new Date(), 'MMM d, yyyy')}`;

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant='outline' className={className}>
          <FileText className='mr-2 h-4 w-4' />
          Share Report
        </Button>
      </DialogTrigger>
      <DialogContent className='sm:max-w-md'>
        <DialogHeader>
          <DialogTitle className='flex items-center gap-2'>
            <FileText className='h-5 w-5' />
            Doctor Report
          </DialogTitle>
        </DialogHeader>

        <div className='space-y-4'>
          <div className='text-center space-y-2'>
            <h3 className='font-semibold text-lg'>{baby.name}</h3>
            <p className='text-sm text-muted-foreground'>
              {babyAge} month{babyAge !== 1 ? 's' : ''} old
            </p>
            <Badge variant='secondary'>{reportPeriod}</Badge>
          </div>

          <Card>
            <CardHeader className='pb-3'>
              <CardTitle className='text-base'>Report Includes:</CardTitle>
            </CardHeader>
            <CardContent className='space-y-2 text-sm'>
              <div className='flex items-center gap-2'>
                <div className='w-2 h-2 bg-primary rounded-full' />
                <span>Daily feeding counts and volumes</span>
              </div>
              <div className='flex items-center gap-2'>
                <div className='w-2 h-2 bg-primary rounded-full' />
                <span>Sleep duration and nap patterns</span>
              </div>
              <div className='flex items-center gap-2'>
                <div className='w-2 h-2 bg-primary rounded-full' />
                <span>Diaper change frequency</span>
              </div>
              <div className='flex items-center gap-2'>
                <div className='w-2 h-2 bg-primary rounded-full' />
                <span>Weekly averages and trends</span>
              </div>
            </CardContent>
          </Card>

          <div className='space-y-3'>
            <p className='text-sm text-muted-foreground text-center'>
              Share with pediatricians, nannies, or family members
            </p>

            <div className='grid grid-cols-2 gap-3'>
              <Button
                onClick={handleShare}
                disabled={isGenerating}
                className='flex items-center gap-2'
              >
                <Share className='h-4 w-4' />
                Share
              </Button>
              <Button
                variant='outline'
                onClick={handleGenerateReport}
                disabled={isGenerating}
                className='flex items-center gap-2'
              >
                <Download className='h-4 w-4' />
                Download
              </Button>
            </div>

            <div className='flex items-center justify-center gap-4 text-xs text-muted-foreground'>
              <div className='flex items-center gap-1'>
                <MessageCircle className='h-3 w-3' />
                <span>Messages</span>
              </div>
              <div className='flex items-center gap-1'>
                <Mail className='h-3 w-3' />
                <span>Email</span>
              </div>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
