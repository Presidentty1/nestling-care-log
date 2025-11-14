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
    const { babyId, shiftStart, shiftEnd } = await req.json();
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Get events during shift
    const { data: events } = await supabaseClient
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', shiftStart)
      .lte('start_time', shiftEnd)
      .order('start_time', { ascending: true });

    if (!events || events.length === 0) {
      return new Response(JSON.stringify({ 
        summary: 'No events logged during this shift',
        eventsSummary: {},
        highlights: [],
        concerns: []
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Aggregate events by type
    const eventsSummary = events.reduce((acc: any, event) => {
      acc[event.type] = (acc[event.type] || 0) + 1;
      return acc;
    }, {});

    // Use AI to generate summary
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    let summary = '';
    let highlights: string[] = [];
    let concerns: string[] = [];

    if (LOVABLE_API_KEY) {
      const context = `
Shift handoff for baby:
Time period: ${new Date(shiftStart).toLocaleString()} to ${new Date(shiftEnd).toLocaleString()}

Events during shift:
${JSON.stringify(eventsSummary, null, 2)}

Recent events detail:
${events.slice(-5).map(e => `- ${e.type} at ${new Date(e.start_time).toLocaleTimeString()}${e.note ? ': ' + e.note : ''}`).join('\n')}

Generate:
1. A brief summary paragraph (2-3 sentences)
2. 2-3 highlights (positive moments)
3. Any concerns (if applicable)

Format as JSON:
{
  "summary": "...",
  "highlights": ["...", "..."],
  "concerns": ["..."]
}
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
            { role: "system", content: "You are a helpful childcare assistant. Be concise and factual." },
            { role: "user", content: context }
          ],
        }),
      });

      if (response.ok) {
        const aiData = await response.json();
        const content = aiData.choices[0].message.content;
        try {
          const parsed = JSON.parse(content);
          summary = parsed.summary || '';
          highlights = parsed.highlights || [];
          concerns = parsed.concerns || [];
        } catch {
          summary = content;
        }
      }
    }

    return new Response(JSON.stringify({
      summary,
      eventsSummary,
      highlights,
      concerns,
      totalEvents: events.length,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error("Error in generate-handoff-report:", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});