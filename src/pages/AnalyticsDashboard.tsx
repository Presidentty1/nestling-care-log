import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { ArrowLeft, TrendingUp, TrendingDown, Activity, Calendar } from 'lucide-react';
import type { EventRecord } from '@/services/eventsService';
import { eventsService } from '@/services/eventsService';
import type { Baby } from '@/services/babyService';
import { babyService } from '@/services/babyService';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { format, subDays, startOfDay, endOfDay, differenceInDays } from 'date-fns';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { MobileContainer } from '@/components/layout/MobileContainer';
import { track } from '@/analytics/analytics';

interface AnalyticsData {
  totalEvents: number;
  feedCount: number;
  sleepHours: number;
  diaperCount: number;
  tummyTimeMinutes: number;
  averageFeedAmount: number;
  averageSleepDuration: number;
  trends: {
    date: string;
    feeds: number;
    sleep: number;
    diapers: number;
  }[];
  feedPatterns: {
    hour: number;
    count: number;
  }[];
  sleepPatterns: {
    hour: number;
    duration: number;
  }[];
}

export default function AnalyticsDashboard() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { activeBabyId } = useAppStore();
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [dateRange, setDateRange] = useState<number>(7); // days
  const [loading, setLoading] = useState(true);
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);

  useEffect(() => {
    if (user) {
      track('analytics_viewed', {
        date_range: dateRange,
        baby_id: activeBabyId
      });
    }
  }, [user, dateRange, activeBabyId]);

  useEffect(() => {
    loadAnalytics();
  }, [activeBabyId, dateRange]);

  async function loadAnalytics() {
    if (!activeBabyId) return;

    setLoading(true);
    try {
      const babies = await babyService.getUserBabies();
      const baby = babies.find(b => b.id === activeBabyId);
      if (!baby) return;

      setSelectedBaby(baby);

      const endDate = new Date();
      const startDate = subDays(endDate, dateRange);

      // Fetch events for date range
      const events = await eventsService.getEventsByRange(
        activeBabyId,
        startDate.toISOString(),
        endDate.toISOString()
      );

      // Calculate analytics
      const data = calculateAnalytics(events, startDate, endDate);
      setAnalyticsData(data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  }

  function calculateAnalytics(
    events: EventRecord[],
    startDate: Date,
    endDate: Date
  ): AnalyticsData {
    const feeds = events.filter(e => e.type === 'feed');
    const sleeps = events.filter(e => e.type === 'sleep' && e.end_time);
    const diapers = events.filter(e => e.type === 'diaper');
    const tummyTimes = events.filter(e => e.type === 'tummy_time' && e.end_time);

    // Calculate totals
    const totalEvents = events.length;
    const feedCount = feeds.length;
    const sleepHours = sleeps.reduce((sum, e) => {
      if (e.duration_min) return sum + e.duration_min / 60;
      if (e.start_time && e.end_time) {
        return sum + (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / (1000 * 60 * 60);
      }
      return sum;
    }, 0);
    const diaperCount = diapers.length;
    const tummyTimeMinutes = tummyTimes.reduce((sum, e) => {
      if (e.duration_min) return sum + e.duration_min;
      if (e.start_time && e.end_time) {
        return sum + (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / (1000 * 60);
      }
      return sum;
    }, 0);

    // Calculate averages
    const totalFeedAmount = feeds.reduce((sum, e) => sum + (e.amount || 0), 0);
    const averageFeedAmount = feedCount > 0 ? totalFeedAmount / feedCount : 0;

    const totalSleepMinutes = sleeps.reduce((sum, e) => {
      if (e.duration_min) return sum + e.duration_min;
      if (e.start_time && e.end_time) {
        return sum + (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / (1000 * 60);
      }
      return sum;
    }, 0);
    const averageSleepDuration = sleeps.length > 0 ? totalSleepMinutes / sleeps.length : 0;

    // Calculate daily trends
    const trends: { date: string; feeds: number; sleep: number; diapers: number }[] = [];
    const days = differenceInDays(endDate, startDate);
    
    for (let i = 0; i <= days; i++) {
      const date = subDays(endDate, days - i);
      const dayStart = startOfDay(date);
      const dayEnd = endOfDay(date);
      
      const dayEvents = events.filter(e => {
        const eventDate = new Date(e.start_time);
        return eventDate >= dayStart && eventDate <= dayEnd;
      });
      
      const dayFeeds = dayEvents.filter(e => e.type === 'feed').length;
      const daySleeps = dayEvents.filter(e => e.type === 'sleep' && e.end_time);
      const daySleepHours = daySleeps.reduce((sum, e) => {
        if (e.duration_min) return sum + e.duration_min / 60;
        return sum;
      }, 0);
      const dayDiapers = dayEvents.filter(e => e.type === 'diaper').length;
      
      trends.push({
        date: format(date, 'MMM d'),
        feeds: dayFeeds,
        sleep: Math.round(daySleepHours * 10) / 10,
        diapers: dayDiapers,
      });
    }

    // Calculate feed patterns by hour
    const feedPatterns: { hour: number; count: number }[] = Array.from({ length: 24 }, (_, i) => ({
      hour: i,
      count: 0,
    }));

    feeds.forEach(feed => {
      const hour = new Date(feed.start_time).getHours();
      feedPatterns[hour].count++;
    });

    // Calculate sleep patterns by hour
    const sleepPatterns: { hour: number; duration: number }[] = Array.from({ length: 24 }, (_, i) => ({
      hour: i,
      duration: 0,
    }));

    sleeps.forEach(sleep => {
      const startHour = new Date(sleep.start_time).getHours();
      const duration = sleep.duration_min ? sleep.duration_min / 60 : 0;
      sleepPatterns[startHour].duration += duration;
    });

    return {
      totalEvents,
      feedCount,
      sleepHours: Math.round(sleepHours * 10) / 10,
      diaperCount,
      tummyTimeMinutes: Math.round(tummyTimeMinutes),
      averageFeedAmount: Math.round(averageFeedAmount),
      averageSleepDuration: Math.round(averageSleepDuration),
      trends,
      feedPatterns,
      sleepPatterns,
    };
  }

  if (loading || !analyticsData || !selectedBaby) {
    return (
      <MobileContainer>
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
            <p className="mt-4 text-muted-foreground">Loading analytics...</p>
          </div>
        </div>
      </MobileContainer>
    );
  }

  return (
    <MobileContainer>
      {/* Header */}
      <header className="flex items-center gap-3 mb-6">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => navigate(-1)}
          className="shrink-0"
        >
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold">Analytics Dashboard</h1>
          <p className="text-sm text-muted-foreground">{selectedBaby.name}</p>
        </div>
      </header>

      {/* Date Range Selector */}
      <div className="mb-4 flex gap-2">
        {[7, 14, 30, 90].map((days) => (
          <Button
            key={days}
            variant={dateRange === days ? 'default' : 'outline'}
            size="sm"
            onClick={() => setDateRange(days)}
          >
            {days}d
          </Button>
        ))}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Events</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analyticsData.totalEvents}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Feeds</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analyticsData.feedCount}</div>
            <p className="text-xs text-muted-foreground">
              Avg: {analyticsData.averageFeedAmount}ml
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Sleep</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analyticsData.sleepHours}h</div>
            <p className="text-xs text-muted-foreground">
              Avg: {analyticsData.averageSleepDuration}m
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Diapers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analyticsData.diaperCount}</div>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <Tabs defaultValue="trends" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="trends">Trends</TabsTrigger>
          <TabsTrigger value="feeds">Feeds</TabsTrigger>
          <TabsTrigger value="sleep">Sleep</TabsTrigger>
        </TabsList>

        <TabsContent value="trends" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Daily Trends</CardTitle>
              <CardDescription>Events over the last {dateRange} days</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={analyticsData.trends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="feeds" stroke="hsl(var(--event-feed))" name="Feeds" />
                  <Line type="monotone" dataKey="sleep" stroke="hsl(var(--event-sleep))" name="Sleep (h)" />
                  <Line type="monotone" dataKey="diapers" stroke="hsl(var(--event-diaper))" name="Diapers" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="feeds" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Feed Patterns</CardTitle>
              <CardDescription>Feeding frequency by hour of day</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={analyticsData.feedPatterns}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="hour" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="hsl(var(--event-feed))" name="Feed Count" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="sleep" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Sleep Patterns</CardTitle>
              <CardDescription>Sleep duration by start hour</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={analyticsData.sleepPatterns}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="hour" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="duration" fill="hsl(var(--event-sleep))" name="Sleep Duration (h)" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </MobileContainer>
  );
}

