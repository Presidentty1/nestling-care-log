import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async req => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { babyId } = await req.json();

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

    const { data: events } = await supabaseClient
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', fourteenDaysAgo.toISOString())
      .order('start_time', { ascending: true });

    if (!events || events.length < 10) {
      return new Response(JSON.stringify({ anomalies: [] }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const anomalies: any[] = [];

    // Check feeding frequency
    const feeds = events.filter(e => e.type === 'feed');
    const recentFeeds = feeds.filter(
      f => new Date(f.start_time) >= new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    );
    const olderFeeds = feeds.filter(
      f =>
        new Date(f.start_time) < new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) &&
        new Date(f.start_time) >= fourteenDaysAgo
    );

    const recentFeedRate = recentFeeds.length / 2; // per day
    const olderFeedRate = olderFeeds.length / 12; // per day

    if (recentFeedRate < olderFeedRate * 0.6) {
      anomalies.push({
        baby_id: babyId,
        anomaly_type: 'feeding_frequency',
        severity: 'warning',
        description: `Feeding frequency has decreased from ${olderFeedRate.toFixed(1)} to ${recentFeedRate.toFixed(1)} feeds per day`,
        metrics: { recentFeedRate, olderFeedRate },
        suggested_actions: [
          "Monitor baby's weight",
          'Check for signs of dehydration',
          'Consider consulting pediatrician if persists',
        ],
      });
    }

    // Check sleep duration
    const sleeps = events.filter(e => e.type === 'sleep' && e.end_time);
    const recentSleeps = sleeps.filter(
      s => new Date(s.start_time) >= new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    );

    if (recentSleeps.length > 0) {
      const avgRecentSleep =
        recentSleeps.reduce((acc, s) => {
          const duration =
            (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
          return acc + duration;
        }, 0) / recentSleeps.length;

      const olderSleeps = sleeps.filter(
        s => new Date(s.start_time) < new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
      );

      if (olderSleeps.length > 0) {
        const avgOlderSleep =
          olderSleeps.reduce((acc, s) => {
            const duration =
              (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) /
              (1000 * 60 * 60);
            return acc + duration;
          }, 0) / olderSleeps.length;

        if (avgRecentSleep < avgOlderSleep * 0.65) {
          anomalies.push({
            baby_id: babyId,
            anomaly_type: 'sleep_duration',
            severity: 'warning',
            description: `Sleep duration has decreased from ${avgOlderSleep.toFixed(1)} to ${avgRecentSleep.toFixed(1)} hours per session`,
            metrics: { avgRecentSleep, avgOlderSleep },
            suggested_actions: [
              'Check for signs of sleep regression',
              'Review sleep environment',
              'Monitor for illness symptoms',
            ],
          });
        }
      }
    }

    // Save anomalies to database
    for (const anomaly of anomalies) {
      await supabaseClient.from('anomalies').insert(anomaly);
    }

    return new Response(
      JSON.stringify({
        anomalies,
        detectedAt: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error in detect-anomalies:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
