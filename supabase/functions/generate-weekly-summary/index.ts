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
    const { babyId, weekStart } = await req.json();

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const weekStartDate = new Date(weekStart);
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setDate(weekEndDate.getDate() + 7);

    // Fetch all events for the week
    const { data: events } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', weekStartDate.toISOString())
      .lt('start_time', weekEndDate.toISOString());

    if (!events || events.length === 0) {
      return new Response(JSON.stringify({ error: 'No data for this week' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Analyze events
    const feedEvents = events.filter(e => e.type === 'feed');
    const sleepEvents = events.filter(e => e.type === 'sleep' && e.end_time);
    const diaperEvents = events.filter(e => e.type === 'diaper');

    const totalFeeds = feedEvents.length;
    const avgFeedsPerDay = totalFeeds / 7;

    const totalSleepMinutes = sleepEvents.reduce((sum, e) => {
      const duration = (new Date(e.end_time).getTime() - new Date(e.start_time).getTime()) / 60000;
      return sum + duration;
    }, 0);
    const avgSleepHoursPerDay = totalSleepMinutes / 60 / 7;

    const totalDiapers = diaperEvents.length;
    const wetDiapers = diaperEvents.filter(e => e.subtype?.includes('wet')).length;
    const dirtyDiapers = diaperEvents.filter(e => e.subtype?.includes('dirty')).length;

    const summaryData = {
      feeds: {
        total: totalFeeds,
        avgPerDay: Math.round(avgFeedsPerDay * 10) / 10,
        byType: {
          bottle: feedEvents.filter(e => e.subtype === 'bottle').length,
          breast: feedEvents.filter(e => e.subtype === 'breast').length,
          solids: feedEvents.filter(e => e.subtype === 'solids').length,
        },
      },
      sleep: {
        totalHours: Math.round((totalSleepMinutes / 60) * 10) / 10,
        avgHoursPerDay: Math.round(avgSleepHoursPerDay * 10) / 10,
        totalNaps: sleepEvents.length,
      },
      diapers: {
        total: totalDiapers,
        wet: wetDiapers,
        dirty: dirtyDiapers,
      },
    };

    const highlights = [];
    const concerns = [];

    // Generate insights
    if (avgSleepHoursPerDay < 12) {
      concerns.push('Sleep duration below recommended average');
    } else if (avgSleepHoursPerDay > 16) {
      highlights.push('Great sleep patterns this week!');
    }

    if (avgFeedsPerDay < 6) {
      concerns.push('Feeding frequency lower than typical');
    }

    if (wetDiapers < 35) {
      concerns.push('Fewer wet diapers than expected');
    }

    // Save summary
    const { data: summary } = await supabase
      .from('weekly_summaries')
      .insert({
        baby_id: babyId,
        week_start: weekStartDate.toISOString().split('T')[0],
        week_end: weekEndDate.toISOString().split('T')[0],
        summary_data: summaryData,
        highlights: highlights.length > 0 ? highlights : null,
        concerns: concerns.length > 0 ? concerns : null,
      })
      .select()
      .single();

    return new Response(JSON.stringify({ summary, data: summaryData }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error generating weekly summary:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
