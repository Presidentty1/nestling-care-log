import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { babyId } = await req.json();
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get baby info
    const { data: baby } = await supabase
      .from('babies')
      .select('*')
      .eq('id', babyId)
      .single();

    if (!baby) throw new Error('Baby not found');

    // Calculate age in weeks
    const ageInWeeks = Math.floor(
      (Date.now() - new Date(baby.date_of_birth).getTime()) / (7 * 24 * 60 * 60 * 1000)
    );

    // Get appropriate wake window
    const { data: wakeWindow } = await supabase
      .from('wake_windows')
      .select('*')
      .lte('age_weeks_min', ageInWeeks)
      .gte('age_weeks_max', ageInWeeks)
      .single();

    if (!wakeWindow) {
      return new Response(
        JSON.stringify({ error: 'No wake window found for age' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get last sleep event
    const { data: lastSleep } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .eq('type', 'sleep')
      .not('end_time', 'is', null)
      .order('end_time', { ascending: false })
      .limit(1)
      .single();

    const lastWakeTime = lastSleep?.end_time ? new Date(lastSleep.end_time) : new Date();
    const napWindowStart = new Date(lastWakeTime.getTime() + wakeWindow.wake_window_min * 60 * 1000);
    const napWindowEnd = new Date(lastWakeTime.getTime() + wakeWindow.wake_window_max * 60 * 1000);

    // Calculate confidence based on data availability
    const { count } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .eq('baby_id', babyId)
      .eq('type', 'sleep')
      .gte('start_time', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

    const confidence = Math.min(0.95, 0.5 + (count || 0) * 0.05);

    // Save prediction
    const { data: prediction } = await supabase
      .from('sleep_predictions')
      .insert({
        baby_id: babyId,
        predicted_nap_start: napWindowStart.toISOString(),
        predicted_nap_end: napWindowEnd.toISOString(),
        confidence_score: confidence,
      })
      .select()
      .single();

    return new Response(
      JSON.stringify({
        napWindowStart: napWindowStart.toISOString(),
        napWindowEnd: napWindowEnd.toISOString(),
        lastWakeTime: lastWakeTime.toISOString(),
        confidence,
        wakeWindowMin: wakeWindow.wake_window_min,
        wakeWindowMax: wakeWindow.wake_window_max,
        predictionId: prediction?.id,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error calculating nap window:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});