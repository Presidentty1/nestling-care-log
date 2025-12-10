// =============================================================================
// EDGE FUNCTION MIGRATION TEMPLATE
// =============================================================================
// This template shows how to migrate from Lovable AI to direct AI provider APIs
//
// BEFORE: Using Lovable AI (current implementation)
// AFTER: Using OpenAI direct (for production outside Lovable)
// =============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// =============================================================================
// OPTION 1: LOVABLE AI (Current - works in Lovable environment)
// =============================================================================

const lovableAIHandler = async (prompt: string) => {
  const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');

  const response = await fetch('https://api.lovable.app/v1/ai/generate', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LOVABLE_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'google/gemini-2.5-flash',
      prompt,
      max_tokens: 500,
    }),
  });

  const data = await response.json();
  return data.text;
};

// =============================================================================
// OPTION 2: OPENAI DIRECT (For production deployment)
// =============================================================================

const openAIHandler = async (prompt: string) => {
  const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4-turbo',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful baby care assistant.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 500,
    }),
  });

  const data = await response.json();
  return data.choices[0].message.content;
};

// =============================================================================
// OPTION 3: GOOGLE AI DIRECT (Alternative to OpenAI)
// =============================================================================

const googleAIHandler = async (prompt: string) => {
  const GOOGLE_AI_API_KEY = Deno.env.get('GOOGLE_AI_API_KEY');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${GOOGLE_AI_API_KEY}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: prompt,
              },
            ],
          },
        ],
      }),
    }
  );

  const data = await response.json();
  return data.candidates[0].content.parts[0].text;
};

// =============================================================================
// MAIN HANDLER (Switch between providers)
// =============================================================================

serve(async req => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const { prompt } = await req.json();

    // Choose AI provider based on environment
    let response: string;

    if (Deno.env.get('LOVABLE_API_KEY')) {
      // Use Lovable AI (current)
      response = await lovableAIHandler(prompt);
    } else if (Deno.env.get('OPENAI_API_KEY')) {
      // Use OpenAI (production)
      response = await openAIHandler(prompt);
    } else if (Deno.env.get('GOOGLE_AI_API_KEY')) {
      // Use Google AI (alternative)
      response = await googleAIHandler(prompt);
    } else {
      throw new Error('No AI provider configured');
    }

    return new Response(JSON.stringify({ response }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    console.error('Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});

// =============================================================================
// MIGRATION STEPS
// =============================================================================
// 1. Set new API key in Supabase secrets:
//    supabase secrets set OPENAI_API_KEY=sk-...
//
// 2. Update function code to use openAIHandler instead of lovableAIHandler
//
// 3. Test locally:
//    supabase functions serve your-function --env-file .env
//
// 4. Deploy:
//    supabase functions deploy your-function
//
// 5. Monitor usage and costs in AI provider dashboard
// =============================================================================
