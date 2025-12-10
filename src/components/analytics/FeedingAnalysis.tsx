import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { Milk, TrendingUp, Calendar } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { subDays } from 'date-fns';

interface FeedingAnalysisProps {
  babyId: string;
  dateRange: 'week' | 'month' | 'all';
}

export function FeedingAnalysis({ babyId, dateRange }: FeedingAnalysisProps) {
  const { data: feedData, isLoading } = useQuery({
    queryKey: ['feeding-analysis', babyId, dateRange],
    queryFn: async () => {
      const daysAgo = dateRange === 'week' ? 7 : dateRange === 'month' ? 30 : 365;
      const startDate = subDays(new Date(), daysAgo);
      const endDate = new Date();

      const allEvents = await dataService.listEventsRange(
        babyId,
        startDate.toISOString(),
        endDate.toISOString()
      );

      return allEvents.filter(e => e.type === 'feed');
    },
  });

  if (isLoading) {
    return (
      <Card className='p-6'>
        <p className='text-muted-foreground'>Loading feeding data...</p>
      </Card>
    );
  }

  // Calculate metrics
  const totalFeeds = feedData?.length || 0;
  const feedsWithAmount = feedData?.filter(f => f.amount) || [];
  const totalAmount = feedsWithAmount.reduce((acc, feed) => acc + (feed.amount || 0), 0);
  const avgAmount = feedsWithAmount.length > 0 ? totalAmount / feedsWithAmount.length : 0;
  const avgFeedsPerDay = totalFeeds / (dateRange === 'week' ? 7 : dateRange === 'month' ? 30 : 30);

  // Group by subtype
  const byType =
    feedData?.reduce((acc: any, feed) => {
      const type = feed.subtype || 'other';
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {}) || {};

  const typeChartData = Object.entries(byType).map(([type, count]) => ({
    type: type.charAt(0).toUpperCase() + type.slice(1),
    count,
  }));

  // Daily chart data
  const dailyData: { [key: string]: number } = {};
  feedData?.forEach(feed => {
    const date = new Date(feed.startTime).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
    dailyData[date] = (dailyData[date] || 0) + 1;
  });

  const dailyChartData = Object.entries(dailyData).map(([date, count]) => ({
    date,
    count,
  }));

  return (
    <div className='space-y-4'>
      <div className='grid grid-cols-1 md:grid-cols-3 gap-4'>
        <Card className='p-4'>
          <div className='flex items-center gap-2 mb-2'>
            <Milk className='h-4 w-4 text-primary' />
            <p className='text-sm text-muted-foreground'>Total Feeds</p>
          </div>
          <p className='text-2xl font-bold'>{totalFeeds}</p>
        </Card>

        <Card className='p-4'>
          <div className='flex items-center gap-2 mb-2'>
            <TrendingUp className='h-4 w-4 text-primary' />
            <p className='text-sm text-muted-foreground'>Avg per Day</p>
          </div>
          <p className='text-2xl font-bold'>{avgFeedsPerDay.toFixed(1)}</p>
        </Card>

        <Card className='p-4'>
          <div className='flex items-center gap-2 mb-2'>
            <Calendar className='h-4 w-4 text-primary' />
            <p className='text-sm text-muted-foreground'>Avg Amount</p>
          </div>
          <p className='text-2xl font-bold'>{avgAmount.toFixed(0)} ml</p>
        </Card>
      </div>

      <Card className='p-6'>
        <h3 className='font-semibold mb-4'>Feeds by Type</h3>
        {typeChartData.length > 0 ? (
          <ResponsiveContainer width='100%' height={250}>
            <BarChart data={typeChartData}>
              <CartesianGrid strokeDasharray='3 3' />
              <XAxis dataKey='type' />
              <YAxis />
              <Tooltip />
              <Bar dataKey='count' fill='hsl(var(--primary))' />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <p className='text-muted-foreground text-center py-8'>No feeding data available</p>
        )}
      </Card>

      <Card className='p-6'>
        <h3 className='font-semibold mb-4'>Daily Feeding Frequency</h3>
        {dailyChartData.length > 0 ? (
          <ResponsiveContainer width='100%' height={250}>
            <BarChart data={dailyChartData}>
              <CartesianGrid strokeDasharray='3 3' />
              <XAxis dataKey='date' />
              <YAxis />
              <Tooltip />
              <Bar dataKey='count' fill='hsl(var(--chart-2))' />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <p className='text-muted-foreground text-center py-8'>No feeding data available</p>
        )}
      </Card>
    </div>
  );
}
