import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Download, TrendingUp, TrendingDown, Minus, CheckCircle2, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';
import html2canvas from 'html2canvas';
import { useRef } from 'react';
import { toast } from 'sonner';

interface WeeklySummaryData {
  feeds: {
    total: number;
    avgPerDay: number;
    byType: {
      bottle: number;
      breast: number;
      solids: number;
    };
  };
  sleep: {
    totalHours: number;
    avgHoursPerDay: number;
    totalNaps: number;
  };
  diapers: {
    total: number;
    wet: number;
    dirty: number;
  };
}

interface WeeklySummaryCardProps {
  weekStart: Date;
  weekEnd: Date;
  babyName: string;
  summaryData: WeeklySummaryData;
  previousWeekData?: WeeklySummaryData;
  highlights?: string[];
  concerns?: string[];
}

export function WeeklySummaryCard({
  weekStart,
  weekEnd,
  babyName,
  summaryData,
  previousWeekData,
  highlights,
  concerns,
}: WeeklySummaryCardProps) {
  const cardRef = useRef<HTMLDivElement>(null);

  const getTrend = (current: number, previous?: number) => {
    if (!previous || previous === 0) return { icon: Minus, text: '-', color: 'text-muted-foreground' };
    
    const percentChange = ((current - previous) / previous) * 100;
    if (Math.abs(percentChange) < 5) {
      return { icon: Minus, text: 'Similar', color: 'text-muted-foreground' };
    }
    
    if (percentChange > 0) {
      return { 
        icon: TrendingUp, 
        text: `+${percentChange.toFixed(0)}%`, 
        color: 'text-green-600 dark:text-green-400' 
      };
    }
    
    return { 
      icon: TrendingDown, 
      text: `${percentChange.toFixed(0)}%`, 
      color: 'text-orange-600 dark:text-orange-400' 
    };
  };

  const sleepTrend = getTrend(
    summaryData.sleep.avgHoursPerDay,
    previousWeekData?.sleep.avgHoursPerDay
  );

  const feedTrend = getTrend(
    summaryData.feeds.avgPerDay,
    previousWeekData?.feeds.avgPerDay
  );

  const diaperTrend = getTrend(
    summaryData.diapers.total / 7,
    previousWeekData ? previousWeekData.diapers.total / 7 : undefined
  );

  const exportAsImage = async () => {
    if (!cardRef.current) return;

    try {
      const canvas = await html2canvas(cardRef.current, {
        backgroundColor: '#ffffff',
        scale: 2,
      });

      const link = document.createElement('a');
      link.download = `${babyName}_week_${format(weekStart, 'yyyy-MM-dd')}.png`;
      link.href = canvas.toDataURL('image/png');
      link.click();

      toast.success('Weekly summary exported!');
    } catch (error) {
      toast.error('Failed to export summary');
      console.error(error);
    }
  };

  return (
    <div>
      <div className="mb-4">
        <Button onClick={exportAsImage} variant="outline" size="sm">
          <Download className="w-4 h-4 mr-2" />
          Export as Image
        </Button>
      </div>

      <Card ref={cardRef} className="overflow-hidden">
        <div className="bg-gradient-to-br from-primary/10 to-primary/5 p-6 border-b">
          <div className="text-center">
            <h2 className="text-2xl font-bold mb-1">{babyName}'s Week</h2>
            <p className="text-muted-foreground">
              {format(weekStart, 'MMM d')} - {format(weekEnd, 'MMM d, yyyy')}
            </p>
          </div>
        </div>

        <CardContent className="p-6">
          <div className="grid grid-cols-3 gap-4 mb-6">
            {/* Sleep */}
            <div className="text-center p-4 rounded-lg bg-muted/50">
              <div className="text-3xl font-bold text-primary mb-1">
                {summaryData.sleep.avgHoursPerDay.toFixed(1)}h
              </div>
              <div className="text-sm text-muted-foreground mb-2">Sleep/day</div>
              <div className={`flex items-center justify-center gap-1 text-xs ${sleepTrend.color}`}>
                <sleepTrend.icon className="w-3 h-3" />
                <span>{sleepTrend.text}</span>
              </div>
            </div>

            {/* Feeding */}
            <div className="text-center p-4 rounded-lg bg-muted/50">
              <div className="text-3xl font-bold text-primary mb-1">
                {summaryData.feeds.avgPerDay.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground mb-2">Feeds/day</div>
              <div className={`flex items-center justify-center gap-1 text-xs ${feedTrend.color}`}>
                <feedTrend.icon className="w-3 h-3" />
                <span>{feedTrend.text}</span>
              </div>
            </div>

            {/* Diapers */}
            <div className="text-center p-4 rounded-lg bg-muted/50">
              <div className="text-3xl font-bold text-primary mb-1">
                {summaryData.diapers.total}
              </div>
              <div className="text-sm text-muted-foreground mb-2">Diapers</div>
              <div className={`flex items-center justify-center gap-1 text-xs ${diaperTrend.color}`}>
                <diaperTrend.icon className="w-3 h-3" />
                <span>{diaperTrend.text}</span>
              </div>
            </div>
          </div>

          {/* Week totals */}
          <div className="grid grid-cols-2 gap-4 mb-6 text-sm">
            <div className="flex justify-between p-3 rounded-lg bg-muted/30">
              <span className="text-muted-foreground">Total Sleep:</span>
              <span className="font-semibold">{summaryData.sleep.totalHours}h</span>
            </div>
            <div className="flex justify-between p-3 rounded-lg bg-muted/30">
              <span className="text-muted-foreground">Total Naps:</span>
              <span className="font-semibold">{summaryData.sleep.totalNaps}</span>
            </div>
            <div className="flex justify-between p-3 rounded-lg bg-muted/30">
              <span className="text-muted-foreground">Bottle Feeds:</span>
              <span className="font-semibold">{summaryData.feeds.byType.bottle}</span>
            </div>
            <div className="flex justify-between p-3 rounded-lg bg-muted/30">
              <span className="text-muted-foreground">Wet Diapers:</span>
              <span className="font-semibold">{summaryData.diapers.wet}</span>
            </div>
          </div>

          {/* Highlights */}
          {highlights && highlights.length > 0 && (
            <div className="mb-4">
              <h4 className="font-semibold mb-2 flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-600" />
                Highlights
              </h4>
              <ul className="space-y-1">
                {highlights.map((highlight, idx) => (
                  <li key={idx} className="text-sm text-muted-foreground pl-6">
                    • {highlight}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Concerns */}
          {concerns && concerns.length > 0 && (
            <div>
              <h4 className="font-semibold mb-2 flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-orange-600" />
                Areas to Monitor
              </h4>
              <ul className="space-y-1">
                {concerns.map((concern, idx) => (
                  <li key={idx} className="text-sm text-muted-foreground pl-6">
                    • {concern}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </CardContent>

        <div className="bg-muted/30 p-4 text-center text-xs text-muted-foreground border-t">
          Generated by Nestling · Track smarter, not harder
        </div>
      </Card>
    </div>
  );
}
