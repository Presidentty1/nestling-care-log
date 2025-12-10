import { supabase } from '@/integrations/supabase/client';
import type { Baby } from './types';
import { differenceInMonths } from 'date-fns';

export async function buildBabyContext(baby: Baby) {
  const ageInMonths = differenceInMonths(new Date(), new Date(baby.date_of_birth));

  // Get recent events (last 7 days)
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const { data: recentEvents } = await supabase
    .from('events')
    .select('type, start_time, end_time, amount, unit')
    .eq('baby_id', baby.id)
    .gte('start_time', sevenDaysAgo.toISOString())
    .order('start_time', { ascending: false })
    .limit(50);

  // Calculate stats
  const feedCount = recentEvents?.filter(e => e.type === 'feed').length || 0;
  const sleepEvents = recentEvents?.filter(e => e.type === 'sleep' && e.end_time) || [];
  const totalSleepHours = sleepEvents.reduce((acc, e) => {
    if (!e.end_time) return acc;
    const duration =
      (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / (1000 * 60 * 60);
    return acc + duration;
  }, 0);
  const avgSleepHours = sleepEvents.length > 0 ? totalSleepHours / sleepEvents.length : 0;

  return {
    name: baby.name,
    ageInMonths,
    recentStats: {
      feedsPerDay: (feedCount / 7).toFixed(1),
      avgSleepHoursPerNight: avgSleepHours.toFixed(1),
      totalEventsTracked: recentEvents?.length || 0,
    },
  };
}
