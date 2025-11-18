import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { BabySwitcher } from '@/components/BabySwitcher';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { Calendar, TrendingUp, RefreshCw, AlertCircle, CheckCircle2 } from 'lucide-react';
import { Baby } from '@/lib/types';
import { format, startOfWeek, subWeeks, addDays } from 'date-fns';
import { WeeklySummaryCard } from '@/components/WeeklySummaryCard';

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
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return [];
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id);
      if (!familyMembers || familyMembers.length === 0) return [];
      const { data } = await supabase
        .from('babies')
        .select('*')
        .eq('family_id', familyMembers[0].family_id);
      return data || [];
    },
  });

  const { data: summaries } = useQuery({
    queryKey: ['weekly-summaries', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      const { data } = await supabase
        .from('weekly_summaries')
        .select('*')
        .eq('baby_id', selectedBabyId)
        .order('week_start', { ascending: false })
        .limit(10);
      return data || [];
    },
    enabled: !!selectedBabyId,
  });

  const selectedBaby = babies?.find(b => b.id === selectedBabyId);

  const generateMutation = useMutation({
    mutationFn: async () => {
      if (!selectedBabyId) return;
      
      const { data, error } = await supabase.functions.invoke('generate-weekly-summary', {
        body: { 
          babyId: selectedBabyId,
          weekStart: weekStart.toISOString().split('T')[0]
        }
      });

      if (error) throw error;
      return data;
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
          <div className="space-y-6">
            {summaries.map((summary, index) => {
              const previousSummary = summaries[index + 1];
              const weekStartDate = new Date(summary.week_start);
              const weekEndDate = new Date(summary.week_end);
              
              return (
                <WeeklySummaryCard
                  key={summary.id}
                  weekStart={weekStartDate}
                  weekEnd={weekEndDate}
                  babyName={selectedBaby?.name || 'Baby'}
                  summaryData={summary.summary_data}
                  previousWeekData={previousSummary?.summary_data}
                  highlights={summary.highlights}
                  concerns={summary.concerns}
                />
              );
            })}
          </div>
        )}

        {summaries && summaries.length === 0 && selectedBabyId && (
          <Card className="p-6 text-center text-muted-foreground">
            No weekly summaries yet. Generate your first report to see insights!
          </Card>
        )}
        
        <BabySwitcher
          isOpen={isSwitcherOpen}
          onClose={() => setIsSwitcherOpen(false)}
          onSelectBaby={(baby) => {
            setSelectedBabyId(baby.id);
            setIsSwitcherOpen(false);
          }}
        />
      </div>
    </div>
  );
}