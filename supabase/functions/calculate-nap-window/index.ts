import 'https://deno.land/x/xhr@0.1.0/mod.ts';
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
    // SECURITY: Authenticate user
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace('Bearer ', '');
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // SECURITY: Validate input
    const body = await req.json();
    const { babyId } = body;

    if (!babyId || typeof babyId !== 'string') {
      return new Response(JSON.stringify({ error: 'Invalid babyId' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // SECURITY: Verify user has access to baby
    const { data: baby } = await supabase
      .from('babies')
      .select('*, family_id')
      .eq('id', babyId)
      .single();

    if (!baby) {
      return new Response(JSON.stringify({ error: 'Baby not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: member } = await supabase
      .from('user_roles')
      .select('role')
      .eq('family_id', baby.family_id)
      .eq('user_id', user.id)
      .single();

    if (!member) {
      return new Response(JSON.stringify({ error: 'Unauthorized access to baby' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const ageInWeeks = Math.floor(
      (Date.now() - new Date(baby.date_of_birth).getTime()) / (7 * 24 * 60 * 60 * 1000)
    );

    const { data: wakeWindow } = await supabase
      .from('wake_windows')
      .select('*')
      .lte('age_weeks_min', ageInWeeks)
      .gte('age_weeks_max', ageInWeeks)
      .single();

    if (!wakeWindow) {
      return new Response(JSON.stringify({ error: 'No wake window found for age' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

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
    const napWindowStart = new Date(
      lastWakeTime.getTime() + wakeWindow.wake_window_min * 60 * 1000
    );
    const napWindowEnd = new Date(lastWakeTime.getTime() + wakeWindow.wake_window_max * 60 * 1000);

    const { count } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .eq('baby_id', babyId)
      .eq('type', 'sleep')
      .gte('start_time', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

    const confidence = Math.min(0.95, 0.5 + (count || 0) * 0.05);

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
