import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BabySelector } from '@/components/BabySelector';
import { SleepAnalysis } from '@/components/analytics/SleepAnalysis';
import { FeedingAnalysis } from '@/components/analytics/FeedingAnalysis';
import { PatternVisualization } from '@/components/analytics/PatternVisualization';
import { MobileNav } from '@/components/MobileNav';
import { ArrowLeft, Download, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { exportWeeklyReport } from '@/lib/reportExport';
import { useToast } from '@/hooks/use-toast';

export default function Analytics() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [dateRange, setDateRange] = useState<'week' | 'month' | 'all'>('week');

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', (await supabase.auth.getUser()).data.user?.id);

      if (!familyMembers || familyMembers.length === 0) return [];

      const { data: babies } = await supabase
        .from('babies')
        .select('*')
        .in('family_id', familyMembers.map(fm => fm.family_id));

      return babies as Baby[];
    },
  });

  if (babies && babies.length > 0 && !selectedBaby) {
    setSelectedBaby(babies[0]);
  }

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
        title: 'Export Failed',
        description: 'Could not generate report. Please try again.',
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
          <p className="text-muted-foreground">No babies found. Please add a baby first.</p>
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
          <BabySelector
            babies={babies}
            selectedBabyId={selectedBaby?.id || null}
            onSelect={(babyId) => {
              const baby = babies.find(b => b.id === babyId);
              if (baby) setSelectedBaby(baby);
            }}
          />
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
            {selectedBaby && <SleepAnalysis babyId={selectedBaby.id} dateRange={dateRange} />}
          </TabsContent>

          <TabsContent value="feeding" className="space-y-4">
            {selectedBaby && <FeedingAnalysis babyId={selectedBaby.id} dateRange={dateRange} />}
          </TabsContent>

          <TabsContent value="patterns" className="space-y-4">
            {selectedBaby && <PatternVisualization babyId={selectedBaby.id} dateRange={dateRange} />}
          </TabsContent>
        </Tabs>
      </div>

      <MobileNav />
    </div>
  );
}