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
    const { babyId, predictionType = 'next_feed' } = await req.json();

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Check AI consent from user
    const authHeader = req.headers.get('Authorization');
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const {
        data: { user },
      } = await supabaseClient.auth.getUser(token);

      if (user) {
        const { data: profile } = await supabaseClient
          .from('profiles')
          .select('ai_data_sharing_enabled')
          .eq('id', user.id)
          .single();

        if (!profile?.ai_data_sharing_enabled) {
          return new Response(
            JSON.stringify({
              error: 'AI features are disabled. Enable in Settings → AI & Data Sharing.',
            }),
            {
              status: 403,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        // Check subscription status - nap predictions are premium-only
        const { data: tierData, error: tierError } = await supabaseClient.rpc(
          'check_subscription_status',
          { user_uuid: user.id }
        );

        if (tierError) {
          console.error('Subscription check error:', tierError);
          return new Response(
            JSON.stringify({
              error: 'Unable to verify subscription status',
            }),
            {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        const isPremium = tierData === 'premium';
        if (!isPremium) {
          return new Response(
            JSON.stringify({
              error:
                'Nap predictions are a Premium feature. Upgrade to unlock AI-powered predictions.',
              upgradeRequired: true,
            }),
            {
              status: 403,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }
      }
    }

    // Get recent events for pattern analysis
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const { data: events } = await supabaseClient
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', sevenDaysAgo.toISOString())
      .order('start_time', { ascending: false })
      .limit(100);

    if (!events || events.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'Not enough data for predictions',
          prediction: null,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    let predictionData: any = {};
    let confidence = 0.5;

    if (predictionType === 'next_feed') {
      const feeds = events.filter(e => e.type === 'feed');
      if (feeds.length >= 3) {
        // Calculate average interval
        const intervals: number[] = [];
        for (let i = 0; i < feeds.length - 1 && i < 10; i++) {
          const interval =
            (new Date(feeds[i].start_time).getTime() -
              new Date(feeds[i + 1].start_time).getTime()) /
            (1000 * 60 * 60);
          intervals.push(interval);
        }
        const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
        const lastFeedTime = new Date(feeds[0].start_time);
        const nextFeedTime = new Date(lastFeedTime.getTime() + avgInterval * 60 * 60 * 1000);

        predictionData = {
          nextFeedTime: nextFeedTime.toISOString(),
          avgInterval: avgInterval.toFixed(1),
          confidenceInterval: [
            new Date(nextFeedTime.getTime() - 30 * 60 * 1000).toISOString(),
            new Date(nextFeedTime.getTime() + 30 * 60 * 1000).toISOString(),
          ],
        };
        confidence = intervals.length >= 5 ? 0.85 : 0.65;
      }
    } else if (predictionType === 'next_nap') {
      const sleeps = events.filter(e => e.type === 'sleep');
      if (sleeps.length >= 2) {
        const lastSleep = sleeps[0];
        const wakeTime = lastSleep.end_time ? new Date(lastSleep.end_time) : null;

        if (wakeTime) {
          // Estimate wake window (2-3 hours for typical age)
          const napTime = new Date(wakeTime.getTime() + 2.5 * 60 * 60 * 1000);

          predictionData = {
            nextNapTime: napTime.toISOString(),
            wakeWindowHours: 2.5,
            confidenceInterval: [
              new Date(napTime.getTime() - 30 * 60 * 1000).toISOString(),
              new Date(napTime.getTime() + 30 * 60 * 1000).toISOString(),
            ],
          };
          confidence = 0.75;
        }
      }
    }

    // Save prediction to database
    const { error: insertError } = await supabaseClient.from('predictions').insert({
      baby_id: babyId,
      prediction_type: predictionType,
      prediction_data: predictionData,
      confidence_score: confidence,
      model_version: 'v1.0',
    });

    if (insertError) {
      console.error('Error saving prediction:', insertError);
    }

    return new Response(
      JSON.stringify({
        predictionType,
        prediction: predictionData,
        confidence,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error in generate-predictions:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
