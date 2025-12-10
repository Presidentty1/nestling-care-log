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

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    const token = authHeader.replace('Bearer ', '');
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check AI consent
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('ai_data_sharing_enabled')
      .eq('id', user.id)
      .single();

    if (!profile?.ai_data_sharing_enabled) {
      return new Response(
        JSON.stringify({
          error: 'AI Assistant is disabled. Enable AI features in Settings → AI & Data Sharing.',
        }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Check subscription status
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
      // Check usage limit for free users (5 per day)
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const { count: usageCount } = await supabaseClient
        .from('ai_conversations')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .gte('created_at', today.toISOString());

      if (usageCount >= 5) {
        return new Response(
          JSON.stringify({
            error: 'Free tier limit reached. Upgrade to Premium for unlimited AI Assistant access.',
            upgradeRequired: true,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    }

    // SECURITY: Validate input
    const body = await req.json();
    const { conversationId, messages, babyContext } = body;

    if (!messages || !Array.isArray(messages)) {
      return new Response(JSON.stringify({ error: 'Invalid messages format' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // SECURITY: Verify user has access to baby if babyContext provided
    if (babyContext?.babyId) {
      const { data: baby } = await supabaseClient
        .from('babies')
        .select('family_id')
        .eq('id', babyContext.babyId)
        .single();

      if (!baby) {
        return new Response(JSON.stringify({ error: 'Baby not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const { data: member } = await supabaseClient
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
    }

    const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');
    if (!LOVABLE_API_KEY) {
      throw new Error('LOVABLE_API_KEY is not configured');
    }

    // Build system prompt with baby context
    let systemPrompt = `You are Nestling AI, a helpful baby care assistant. You provide evidence-based guidance on infant care, sleep, feeding, and development.

IMPORTANT DISCLAIMERS:
- You are NOT a replacement for medical advice
- Always recommend consulting with pediatricians for health concerns
- Never diagnose medical conditions
- Focus on general guidance and pattern recognition

Be concise, empathetic, and practical in your responses.`;

    if (babyContext) {
      systemPrompt += `\n\nCurrent Baby Context:
- Name: ${babyContext.name}
- Age: ${babyContext.ageInMonths} months old
- Recent stats: ${JSON.stringify(babyContext.recentStats)}`;
    }

    const response = await fetch('https://ai.gateway.lovable.dev/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'google/gemini-2.5-flash',
        messages: [{ role: 'system', content: systemPrompt }, ...messages],
      }),
    });

    if (!response.ok) {
      if (response.status === 429) {
        return new Response(
          JSON.stringify({ error: 'Rate limits exceeded, please try again later.' }),
          {
            status: 429,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
      if (response.status === 402) {
        return new Response(
          JSON.stringify({
            error: 'Payment required, please add funds to your Lovable AI workspace.',
          }),
          {
            status: 402,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
      const text = await response.text();
      console.error('AI gateway error:', response.status, text);
      return new Response(JSON.stringify({ error: 'AI gateway error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const aiData = await response.json();
    const assistantMessage = aiData.choices[0].message.content;

    return new Response(JSON.stringify({ message: assistantMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error in ai-assistant:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
