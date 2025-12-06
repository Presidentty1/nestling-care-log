import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { BabySwitcher } from '@/components/BabySwitcher';
import { authService } from '@/services/authService';
import { babyService } from '@/services/babyService';
import { weeklySummariesService } from '@/services/weeklySummariesService';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { Calendar, RefreshCw, AlertCircle, CheckCircle2 } from 'lucide-react';
import { Baby } from '@/lib/types';
import { format, startOfWeek, subWeeks } from 'date-fns';

export default function WeeklyReports() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [weekOffset, setWeekOffset] = useState(0);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  const weekStart = startOfWeek(subWeeks(new Date(), weekOffset), { weekStartsOn: 1 });

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  const { data: summaries } = useQuery({
    queryKey: ['weekly-summaries', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      return await weeklySummariesService.getSummaries(selectedBabyId, 10);
    },
    enabled: !!selectedBabyId,
  });

  const generateMutation = useMutation({
    mutationFn: async () => {
      if (!selectedBabyId) return;
      return await weeklySummariesService.generateSummary(selectedBabyId, weekStart.toISOString());
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['weekly-summaries'] });
      toast({ title: 'Weekly summary generated!' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to generate summary',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Weekly Reports</h1>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsSwitcherOpen(true)}
            className="flex items-center gap-2"
          >
            <span>👶</span>
            <span>{babies?.find(b => b.id === selectedBabyId)?.name || 'Select Baby'}</span>
          </Button>
        </div>

        {selectedBabyId && (
          <Card className="p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Calendar className="w-5 h-5" />
                <span className="font-semibold">
                  Week of {format(weekStart, 'MMM d, yyyy')}
                </span>
              </div>
              <Button
                onClick={() => generateMutation.mutate()}
                disabled={generateMutation.isPending}
              >
                <RefreshCw className={`w-4 h-4 mr-2 ${generateMutation.isPending ? 'animate-spin' : ''}`} />
                Generate Report
              </Button>
            </div>
          </Card>
        )}

        {summaries && summaries.length > 0 && (
          <div className="space-y-4">
            {summaries.map((summary) => (
              <Card key={summary.id} className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold">
                    {format(new Date(summary.week_start), 'MMM d')} -{' '}
                    {format(new Date(summary.week_end), 'MMM d, yyyy')}
                  </h3>
                  <span className="text-sm text-muted-foreground">
                    Generated {format(new Date(summary.generated_at), 'MMM d')}
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                  <div>
                    <h4 className="font-semibold mb-2">Feeding</h4>
                    <p className="text-2xl font-bold">{summary.summary_data?.feeds?.total || 0}</p>
                    <p className="text-sm text-muted-foreground">
                      {summary.summary_data?.feeds?.avgPerDay || 0} per day avg
                    </p>
                  </div>

                  <div>
                    <h4 className="font-semibold mb-2">Sleep</h4>
                    <p className="text-2xl font-bold">
                      {summary.summary_data?.sleep?.totalHours || 0}h
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {summary.summary_data?.sleep?.avgHoursPerDay || 0}h per day avg
                    </p>
                  </div>

                  <div>
                    <h4 className="font-semibold mb-2">Diapers</h4>
                    <p className="text-2xl font-bold">{summary.summary_data?.diapers?.total || 0}</p>
                    <p className="text-sm text-muted-foreground">
                      {summary.summary_data?.diapers?.wet || 0} wet,{' '}
                      {summary.summary_data?.diapers?.dirty || 0} dirty
                    </p>
                  </div>
                </div>

                {summary.highlights && summary.highlights.length > 0 && (
                  <div className="mb-4">
                    <h4 className="font-semibold mb-2 flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-green-600" />
                      Highlights
                    </h4>
                    <ul className="space-y-1">
                      {summary.highlights.map((highlight: string, idx: number) => (
                        <li key={idx} className="text-sm text-muted-foreground">• {highlight}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {summary.concerns && summary.concerns.length > 0 && (
                  <div>
                    <h4 className="font-semibold mb-2 flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 text-orange-600" />
                      Areas to Monitor
                    </h4>
                    <ul className="space-y-1">
                      {summary.concerns.map((concern: string, idx: number) => (
                        <li key={idx} className="text-sm text-muted-foreground">• {concern}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </Card>
            ))}
          </div>
        )}

        {summaries && summaries.length === 0 && (
          <Card className="p-6 text-center text-muted-foreground">
            No weekly summaries yet. Generate your first report to see insights!
          </Card>
        )}
      </div>
    </div>
  );
}