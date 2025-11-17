import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Moon, TrendingUp, Clock } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { subDays } from 'date-fns';

interface SleepAnalysisProps {
  babyId: string;
  dateRange: 'week' | 'month' | 'all';
}

export function SleepAnalysis({ babyId, dateRange }: SleepAnalysisProps) {
  const { data: sleepData, isLoading } = useQuery({
    queryKey: ['sleep-analysis', babyId, dateRange],
    queryFn: async () => {
      const daysAgo = dateRange === 'week' ? 7 : dateRange === 'month' ? 30 : 365;
      const startDate = subDays(new Date(), daysAgo);
      const endDate = new Date();

      const allEvents = await dataService.listEventsRange(
        babyId,
        startDate.toISOString(),
        endDate.toISOString()
      );

      return allEvents.filter(e => e.type === 'sleep');
    },
  });

  if (isLoading) {
    return <Card className="p-6"><p className="text-muted-foreground">Loading sleep data...</p></Card>;
  }

  // Calculate metrics
  const completedSleeps = sleepData?.filter(s => s.endTime) || [];
  const totalSleepHours = completedSleeps.reduce((acc, sleep) => {
    const duration = (new Date(sleep.endTime).getTime() - new Date(sleep.startTime).getTime()) / (1000 * 60 * 60);
    return acc + duration;
  }, 0);
  const avgSleepDuration = completedSleeps.length > 0 ? totalSleepHours / completedSleeps.length : 0;
  const avgSleepPerDay = completedSleeps.length > 0 ? totalSleepHours / (dateRange === 'week' ? 7 : 30) : 0;

  // Prepare chart data
  const chartData = completedSleeps.map(sleep => ({
    date: new Date(sleep.startTime).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    hours: ((new Date(sleep.endTime).getTime() - new Date(sleep.startTime).getTime()) / (1000 * 60 * 60)).toFixed(1),
  }));

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Moon className="h-4 w-4 text-primary" />
            <p className="text-sm text-muted-foreground">Total Sleep</p>
          </div>
          <p className="text-2xl font-bold">{totalSleepHours.toFixed(1)}h</p>
        </Card>

        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="h-4 w-4 text-primary" />
            <p className="text-sm text-muted-foreground">Avg per Day</p>
          </div>
          <p className="text-2xl font-bold">{avgSleepPerDay.toFixed(1)}h</p>
        </Card>

        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Clock className="h-4 w-4 text-primary" />
            <p className="text-sm text-muted-foreground">Avg Duration</p>
          </div>
          <p className="text-2xl font-bold">{avgSleepDuration.toFixed(1)}h</p>
        </Card>
      </div>

      <Card className="p-6">
        <h3 className="font-semibold mb-4">Sleep Duration Trend</h3>
        {chartData.length > 0 ? (
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis label={{ value: 'Hours', angle: -90, position: 'insideLeft' }} />
              <Tooltip />
              <Line type="monotone" dataKey="hours" stroke="hsl(var(--primary))" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        ) : (
          <p className="text-muted-foreground text-center py-8">No sleep data available for this period</p>
        )}
      </Card>
    </div>
  );
}