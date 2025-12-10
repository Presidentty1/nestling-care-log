import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { format, subDays } from 'date-fns';
import { CalendarIcon, Download, Mail, FileText } from 'lucide-react';
import { cn } from '@/lib/utils';
import { exportEventsCSV } from '@/lib/csvExport';
import { generateDoctorReport, downloadDoctorReport } from '@/lib/doctorReportPDF';
import { eventsService } from '@/services/eventsService';
import { growthRecordsService } from '@/services/growthRecordsService';
import { healthRecordsService } from '@/services/healthRecordsService';
import { toast } from 'sonner';

interface DoctorShareModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  babyId: string;
  babyName: string;
  babySex?: string;
  babyBirthDate: string;
}

export function DoctorShareModal({
  open,
  onOpenChange,
  babyId,
  babyName,
  babySex,
  babyBirthDate,
}: DoctorShareModalProps) {
  const [startDate, setStartDate] = useState<Date>(subDays(new Date(), 30));
  const [endDate, setEndDate] = useState<Date>(new Date());
  const [isExporting, setIsExporting] = useState(false);

  const handleExportCSV = async () => {
    try {
      setIsExporting(true);
      await exportEventsCSV(babyId, babyName, startDate, endDate);
      toast.success('CSV exported successfully!');
      onOpenChange(false);
    } catch (error) {
      console.error('CSV export error:', error);
      toast.error('Failed to export CSV');
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportPDF = async () => {
    try {
      setIsExporting(true);

      // Fetch events
      const events = await eventsService.getEvents({
        babyId,
        startTime: startDate.toISOString(),
        endTime: endDate.toISOString(),
      });

      // Fetch growth records
      const growthRecords = await growthRecordsService.getGrowthRecords(babyId);

      // Fetch health records
      const healthRecords = await healthRecordsService.getHealthRecords(babyId);

      const baby = {
        id: babyId,
        name: babyName,
        sex: babySex || null,
        date_of_birth: babyBirthDate,
      };

      const doc = await generateDoctorReport(
        baby as any,
        growthRecords || [],
        events || [],
        healthRecords || [],
        [startDate, endDate]
      );

      downloadDoctorReport(doc, babyName);
      toast.success('PDF report exported successfully!');
      onOpenChange(false);
    } catch (error) {
      console.error('PDF export error:', error);
      toast.error('Failed to export PDF');
    } finally {
      setIsExporting(false);
    }
  };

  const handleShareEmail = () => {
    const subject = encodeURIComponent(`Baby tracking data for ${babyName}`);
    const body = encodeURIComponent(
      `Hi,\n\nI'm sharing ${babyName}'s tracking data from ${format(startDate, 'PPP')} to ${format(endDate, 'PPP')}.\n\nPlease find the attached report.\n\nBest regards`
    );
    window.location.href = `mailto:?subject=${subject}&body=${body}`;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='sm:max-w-md'>
        <DialogHeader>
          <DialogTitle>Share with Doctor</DialogTitle>
          <DialogDescription>
            Export {babyName}'s data to share with your pediatrician
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4'>
          {/* Date Range Selection */}
          <div className='space-y-2'>
            <Label>Date Range</Label>
            <div className='flex gap-2'>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant='outline'
                    className={cn(
                      'flex-1 justify-start text-left font-normal',
                      !startDate && 'text-muted-foreground'
                    )}
                  >
                    <CalendarIcon className='mr-2 h-4 w-4' />
                    {startDate ? format(startDate, 'PPP') : 'Start date'}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className='w-auto p-0'>
                  <Calendar
                    mode='single'
                    selected={startDate}
                    onSelect={date => date && setStartDate(date)}
                    disabled={date => date > new Date()}
                  />
                </PopoverContent>
              </Popover>

              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant='outline'
                    className={cn(
                      'flex-1 justify-start text-left font-normal',
                      !endDate && 'text-muted-foreground'
                    )}
                  >
                    <CalendarIcon className='mr-2 h-4 w-4' />
                    {endDate ? format(endDate, 'PPP') : 'End date'}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className='w-auto p-0'>
                  <Calendar
                    mode='single'
                    selected={endDate}
                    onSelect={date => date && setEndDate(date)}
                    disabled={date => date > new Date() || date < startDate}
                  />
                </PopoverContent>
              </Popover>
            </div>
          </div>

          {/* Quick Date Presets */}
          <div className='flex gap-2'>
            <Button
              variant='outline'
              size='sm'
              onClick={() => {
                setStartDate(subDays(new Date(), 7));
                setEndDate(new Date());
              }}
            >
              Last 7 days
            </Button>
            <Button
              variant='outline'
              size='sm'
              onClick={() => {
                setStartDate(subDays(new Date(), 30));
                setEndDate(new Date());
              }}
            >
              Last 30 days
            </Button>
          </div>

          {/* Export Options */}
          <div className='space-y-2 pt-2'>
            <Label>Export Format</Label>
            <div className='grid grid-cols-2 gap-2'>
              <Button
                variant='outline'
                onClick={handleExportCSV}
                disabled={isExporting}
                className='flex flex-col h-auto py-4'
              >
                <FileText className='h-6 w-6 mb-2' />
                <span className='text-sm font-medium'>CSV</span>
                <span className='text-xs text-muted-foreground'>Spreadsheet</span>
              </Button>

              <Button
                variant='outline'
                onClick={handleExportPDF}
                disabled={isExporting}
                className='flex flex-col h-auto py-4'
              >
                <Download className='h-6 w-6 mb-2' />
                <span className='text-sm font-medium'>PDF</span>
                <span className='text-xs text-muted-foreground'>Report</span>
              </Button>
            </div>
          </div>

          {/* Share via Email */}
          <Button variant='secondary' className='w-full' onClick={handleShareEmail}>
            <Mail className='mr-2 h-4 w-4' />
            Open Email to Share
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
