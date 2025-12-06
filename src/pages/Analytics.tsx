import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { Baby } from '@/lib/types';
import { babyService } from '@/services/babyService';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BabySwitcher } from '@/components/BabySwitcher';
import { SleepAnalysis } from '@/components/analytics/SleepAnalysis';
import { FeedingAnalysis } from '@/components/analytics/FeedingAnalysis';
import { PatternVisualization } from '@/components/analytics/PatternVisualization';
import { SkeletonCard } from '@/components/common/SkeletonCard';
import { MobileNav } from '@/components/MobileNav';
import { ArrowLeft, Download, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { exportWeeklyReport } from '@/lib/reportExport';
import { useToast } from '@/hooks/use-toast';

export default function Analytics() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState<'week' | 'month' | 'all'>('week');
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  if (babies && babies.length > 0 && !selectedBabyId) {
    setSelectedBabyId(babies[0].id);
    localStorage.setItem('selected_baby_id', babies[0].id);
  }

  const selectedBaby = babies?.find(b => b.id === selectedBabyId);

  const handleExport = async () => {
    if (!selectedBaby) return;
    
    try {
      await exportWeeklyReport(selectedBaby);
      toast({
        title: 'Report Downloaded',
        description: 'Your weekly report has been saved.',
      });
    } catch (error) {
      toast({
        title: "Couldn't Export",
        description: 'Something went wrong. Try again?',
        variant: 'destructive',
      });
    }
  };

  if (!babies || babies.length === 0) {
    return (
      <div className="min-h-screen bg-background p-4">
        <Button onClick={() => navigate(-1)} variant="ghost" className="mb-4">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <Card className="p-8 text-center">
          <p className="text-muted-foreground">No babies yet. Add one to see insights!</p>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-4">
              <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
                <ArrowLeft className="h-4 w-4" />
              </Button>
              <div>
                <h1 className="text-2xl font-bold">Analytics</h1>
                <p className="text-sm text-muted-foreground">Insights and trends</p>
              </div>
            </div>
            <Button onClick={handleExport} variant="outline" size="sm">
              <Download className="mr-2 h-4 w-4" />
              Export
            </Button>
          </div>
          {babies.length > 1 && (
            <Button
              onClick={() => setIsSwitcherOpen(true)}
              variant="outline"
              size="sm"
              className="gap-2"
            >
              {selectedBaby?.name}
            </Button>
          )}
        </div>
      </div>

      <div className="container mx-auto p-4">
        <div className="flex gap-2 mb-4">
          <Button
            variant={dateRange === 'week' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setDateRange('week')}
          >
            Last Week
          </Button>
          <Button
            variant={dateRange === 'month' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setDateRange('month')}
          >
            Last Month
          </Button>
          <Button
            variant={dateRange === 'all' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setDateRange('all')}
          >
            All Time
          </Button>
        </div>

        <Tabs defaultValue="sleep" className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="sleep">Sleep</TabsTrigger>
            <TabsTrigger value="feeding">Feeding</TabsTrigger>
            <TabsTrigger value="patterns">
              <TrendingUp className="mr-2 h-4 w-4" />
              Patterns
            </TabsTrigger>
          </TabsList>

          <TabsContent value="sleep" className="space-y-4">
            {selectedBabyId && <SleepAnalysis babyId={selectedBabyId} dateRange={dateRange} />}
          </TabsContent>

          <TabsContent value="feeding" className="space-y-4">
            {selectedBabyId && <FeedingAnalysis babyId={selectedBabyId} dateRange={dateRange} />}
          </TabsContent>

          <TabsContent value="patterns" className="space-y-4">
            {selectedBabyId && <PatternVisualization babyId={selectedBabyId} dateRange={dateRange} />}
          </TabsContent>
        </Tabs>
      </div>

      <BabySwitcher
        babies={babies || []}
        selectedBabyId={selectedBabyId || ''}
        isOpen={isSwitcherOpen}
        onClose={() => setIsSwitcherOpen(false)}
        onSelect={(babyId) => {
          setSelectedBabyId(babyId);
          localStorage.setItem('selected_baby_id', babyId);
        }}
      />

      <MobileNav />
    </div>
  );
}