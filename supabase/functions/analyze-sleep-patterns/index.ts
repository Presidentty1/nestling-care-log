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
    const { babyId, days = 30 } = await req.json();
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Get sleep data for analysis
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const { data: sleepEvents } = await supabaseClient
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .eq('type', 'sleep')
      .gte('start_time', startDate.toISOString())
      .order('start_time', { ascending: true });

    if (!sleepEvents || sleepEvents.length === 0) {
      return new Response(JSON.stringify({ 
        error: 'Not enough sleep data',
        recommendations: []
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Calculate baseline metrics
    const completedSleeps = sleepEvents.filter(s => s.end_time);
    const avgDuration = completedSleeps.reduce((acc, s) => {
      const duration = (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
      return acc + duration;
    }, 0) / completedSleeps.length;

    // Detect regressions (sudden changes in last week vs previous weeks)
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    const recentSleeps = completedSleeps.filter(s => new Date(s.start_time) >= oneWeekAgo);
    const olderSleeps = completedSleeps.filter(s => new Date(s.start_time) < oneWeekAgo);

    const recentAvg = recentSleeps.reduce((acc, s) => {
      const duration = (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
      return acc + duration;
    }, 0) / (recentSleeps.length || 1);

    const olderAvg = olderSleeps.reduce((acc, s) => {
      const duration = (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
      return acc + duration;
    }, 0) / (olderSleeps.length || 1);

    const regressionDetected = recentAvg < olderAvg * 0.7; // 30% decrease

    // Use AI for recommendations
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    
    let recommendations = [];
    if (LOVABLE_API_KEY) {
      const context = `
Baby sleep analysis:
- Average sleep duration: ${avgDuration.toFixed(1)} hours
- Recent average: ${recentAvg.toFixed(1)} hours
- Previous average: ${olderAvg.toFixed(1)} hours
- Regression detected: ${regressionDetected}
- Total sleep events analyzed: ${completedSleeps.length}

Provide 3-5 actionable recommendations for improving sleep patterns.
`;

      const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${LOVABLE_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "google/gemini-2.5-flash",
          messages: [
            { role: "system", content: "You are a pediatric sleep consultant. Provide clear, evidence-based recommendations." },
            { role: "user", content: context }
          ],
        }),
      });

      if (response.ok) {
        const aiData = await response.json();
        const content = aiData.choices[0].message.content;
        recommendations = content.split('\n').filter((line: string) => line.trim());
      }
    }

    return new Response(JSON.stringify({
      avgDuration: avgDuration.toFixed(1),
      recentAvg: recentAvg.toFixed(1),
      olderAvg: olderAvg.toFixed(1),
      regressionDetected,
      totalSleeps: completedSleeps.length,
      recommendations,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error("Error in analyze-sleep-patterns:", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});