import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Card } from '@/components/ui/card';
import { TrendingUp, Clock, AlertCircle } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

interface PatternVisualizationProps {
  babyId: string;
  dateRange: 'week' | 'month' | 'all';
}

export function PatternVisualization({ babyId, dateRange }: PatternVisualizationProps) {
  const { data: events, isLoading } = useQuery({
    queryKey: ['pattern-events', babyId, dateRange],
    queryFn: async () => {
      const daysAgo = dateRange === 'week' ? 7 : dateRange === 'month' ? 30 : 365;
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - daysAgo);

      const { data } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', babyId)
        .gte('start_time', startDate.toISOString())
        .order('start_time', { ascending: true });

      return data || [];
    },
  });

  if (isLoading) {
    return <Card className="p-6"><p className="text-muted-foreground">Analyzing patterns...</p></Card>;
  }

  // Analyze patterns
  const analyzePatterns = () => {
    if (!events || events.length === 0) return [];

    const patterns: any[] = [];

    // Sleep pattern analysis
    const sleeps = events.filter(e => e.type === 'sleep' && e.end_time);
    if (sleeps.length > 3) {
      const nightSleeps = sleeps.filter(s => {
        const hour = new Date(s.start_time).getHours();
        return hour >= 19 || hour <= 6;
      });

      if (nightSleeps.length > 0) {
        const avgDuration = nightSleeps.reduce((acc, s) => {
          const duration = (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
          return acc + duration;
        }, 0) / nightSleeps.length;

        patterns.push({
          type: 'sleep',
          title: 'Night Sleep Pattern',
          description: `Average night sleep duration: ${avgDuration.toFixed(1)} hours`,
          confidence: nightSleeps.length >= 5 ? 85 : 65,
          icon: Clock,
        });
      }
    }

    // Feeding pattern analysis
    const feeds = events.filter(e => e.type === 'feed');
    if (feeds.length > 5) {
      const intervals: number[] = [];
      for (let i = 1; i < feeds.length; i++) {
        const interval = (new Date(feeds[i].start_time).getTime() - new Date(feeds[i-1].start_time).getTime()) / (1000 * 60 * 60);
        intervals.push(interval);
      }
      const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;

      patterns.push({
        type: 'feeding',
        title: 'Feeding Schedule',
        description: `Baby typically feeds every ${avgInterval.toFixed(1)} hours`,
        confidence: intervals.length >= 7 ? 80 : 60,
        icon: TrendingUp,
      });
    }

    // Activity pattern
    const morningEvents = events.filter(e => {
      const hour = new Date(e.start_time).getHours();
      return hour >= 6 && hour < 12;
    });

    const afternoonEvents = events.filter(e => {
      const hour = new Date(e.start_time).getHours();
      return hour >= 12 && hour < 18;
    });

    if (morningEvents.length > afternoonEvents.length * 1.5) {
      patterns.push({
        type: 'activity',
        title: 'Morning Activity Peak',
        description: 'Baby is most active in the morning hours',
        confidence: 70,
        icon: TrendingUp,
      });
    } else if (afternoonEvents.length > morningEvents.length * 1.5) {
      patterns.push({
        type: 'activity',
        title: 'Afternoon Activity Peak',
        description: 'Baby is most active in the afternoon',
        confidence: 70,
        icon: TrendingUp,
      });
    }

    return patterns;
  };

  const patterns = analyzePatterns();

  return (
    <div className="space-y-4">
      {patterns.length > 0 ? (
        patterns.map((pattern, idx) => (
          <Card key={idx} className="p-4">
            <div className="flex items-start justify-between mb-2">
              <div className="flex items-start gap-3">
                <pattern.icon className="h-5 w-5 text-primary mt-0.5" />
                <div>
                  <h4 className="font-medium">{pattern.title}</h4>
                  <p className="text-sm text-muted-foreground mt-1">{pattern.description}</p>
                </div>
              </div>
              <Badge variant="secondary">
                {pattern.confidence}% confidence
              </Badge>
            </div>
          </Card>
        ))
      ) : (
        <Card className="p-8 text-center">
          <AlertCircle className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
          <p className="text-muted-foreground">
            Not enough data to detect patterns yet. Keep tracking events to see insights!
          </p>
        </Card>
      )}
    </div>
  );
}