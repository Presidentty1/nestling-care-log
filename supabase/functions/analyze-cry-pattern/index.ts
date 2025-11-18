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
    const { babyId, recentEvents, timeOfDay, timeSinceLastFeed, lastSleepDuration } = await req.json();
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Check AI consent from user
    const authHeader = req.headers.get('Authorization');
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user } } = await supabaseClient.auth.getUser(token);
      
      if (user) {
        const { data: profile } = await supabaseClient
          .from('profiles')
          .select('ai_data_sharing_enabled')
          .eq('id', user.id)
          .single();
        
        if (!profile?.ai_data_sharing_enabled) {
          return new Response(JSON.stringify({ 
            error: 'Cry analysis is disabled. Enable AI features in Settings → AI & Data Sharing.' 
          }), {
            status: 403,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }
      }
    }
    
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      throw new Error("LOVABLE_API_KEY is not configured");
    }

    // Build context for AI
    const context = `
Baby is crying. Help analyze possible causes based on:
- Time of day: ${timeOfDay}
- Time since last feed: ${timeSinceLastFeed} minutes
- Last sleep duration: ${lastSleepDuration} minutes
- Recent events: ${JSON.stringify(recentEvents)}

Provide analysis in JSON format with:
- possibleCauses: array of likely causes (hungry, tired, uncomfortable, overstimulated, needs diaper change)
- confidence: 0-100 for each cause
- suggestions: array of actionable suggestions
- reasoning: brief explanation
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
          { role: "system", content: "You are a pediatric sleep and behavior expert assistant. Provide helpful, evidence-based insights about baby crying patterns. Always respond in valid JSON format." },
          { role: "user", content: context }
        ],
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Rate limits exceeded, please try again later." }), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (response.status === 402) {
        return new Response(JSON.stringify({ error: "Payment required, please add funds to your Lovable AI workspace." }), {
          status: 402,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const text = await response.text();
      console.error("AI gateway error:", response.status, text);
      return new Response(JSON.stringify({ error: "AI gateway error" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const aiData = await response.json();
    const content = aiData.choices[0].message.content;
    
    // Parse AI response
    let analysis;
    try {
      analysis = JSON.parse(content);
    } catch (e) {
      // If AI didn't return valid JSON, create a structured response
      analysis = {
        possibleCauses: [
          { cause: "hungry", confidence: 70 },
          { cause: "tired", confidence: 60 },
          { cause: "uncomfortable", confidence: 40 }
        ],
        suggestions: ["Try feeding", "Check if baby is tired", "Check diaper"],
        reasoning: content
      };
    }

    return new Response(JSON.stringify(analysis), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in analyze-cry-pattern:", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});