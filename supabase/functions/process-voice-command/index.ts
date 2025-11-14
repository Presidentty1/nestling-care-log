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
    const { transcript, babyId, userId } = await req.json();
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const lowerTranscript = transcript.toLowerCase();
    
    let parsedCommand: any = { action: 'unknown' };
    let wasSuccessful = false;
    let errorMessage = '';

    try {
      // Parse feed commands
      if (lowerTranscript.includes('feed') || lowerTranscript.includes('feeding')) {
        parsedCommand.action = 'feed';
        
        if (lowerTranscript.includes('start')) {
          parsedCommand.operation = 'start';
        } else if (lowerTranscript.includes('stop') || lowerTranscript.includes('end')) {
          parsedCommand.operation = 'stop';
        } else {
          parsedCommand.operation = 'log';
        }

        if (lowerTranscript.includes('bottle')) {
          parsedCommand.subtype = 'bottle';
        } else if (lowerTranscript.includes('breast')) {
          parsedCommand.subtype = 'breast';
        } else if (lowerTranscript.includes('solid')) {
          parsedCommand.subtype = 'solids';
        }

        // Extract amount
        const amountMatch = lowerTranscript.match(/(\d+)\s*(ml|milliliters?|oz|ounces?)/i);
        if (amountMatch) {
          parsedCommand.amount = parseFloat(amountMatch[1]);
          parsedCommand.unit = amountMatch[2].toLowerCase().includes('ml') ? 'ml' : 'oz';
        }

        wasSuccessful = true;
      }
      
      // Parse sleep commands
      else if (lowerTranscript.includes('sleep') || lowerTranscript.includes('nap')) {
        parsedCommand.action = 'sleep';
        
        if (lowerTranscript.includes('start') || lowerTranscript.includes('begin')) {
          parsedCommand.operation = 'start';
        } else if (lowerTranscript.includes('stop') || lowerTranscript.includes('end') || lowerTranscript.includes('wake')) {
          parsedCommand.operation = 'stop';
        } else {
          parsedCommand.operation = 'log';
        }

        // Extract duration
        const durationMatch = lowerTranscript.match(/(\d+)\s*(hour|hr|minute|min)/i);
        if (durationMatch) {
          const value = parseInt(durationMatch[1]);
          const unit = durationMatch[2].toLowerCase();
          parsedCommand.duration = unit.includes('hour') || unit.includes('hr') ? value * 60 : value;
        }

        wasSuccessful = true;
      }
      
      // Parse diaper commands
      else if (lowerTranscript.includes('diaper') || lowerTranscript.includes('nappy')) {
        parsedCommand.action = 'diaper';
        parsedCommand.operation = 'log';
        
        const isWet = lowerTranscript.includes('wet') || lowerTranscript.includes('pee');
        const isDirty = lowerTranscript.includes('dirty') || lowerTranscript.includes('poop') || lowerTranscript.includes('soiled');
        
        if (isWet && isDirty) {
          parsedCommand.subtype = 'both';
        } else if (isWet) {
          parsedCommand.subtype = 'wet';
        } else if (isDirty) {
          parsedCommand.subtype = 'dirty';
        } else {
          parsedCommand.subtype = 'wet'; // default
        }

        wasSuccessful = true;
      }
      
      // Parse tummy time commands
      else if (lowerTranscript.includes('tummy time')) {
        parsedCommand.action = 'tummy_time';
        
        if (lowerTranscript.includes('start')) {
          parsedCommand.operation = 'start';
        } else if (lowerTranscript.includes('stop') || lowerTranscript.includes('end')) {
          parsedCommand.operation = 'stop';
        } else {
          parsedCommand.operation = 'log';
        }

        const durationMatch = lowerTranscript.match(/(\d+)\s*(minute|min)/i);
        if (durationMatch) {
          parsedCommand.duration = parseInt(durationMatch[1]);
        }

        wasSuccessful = true;
      } else {
        errorMessage = 'Command not recognized. Try saying "Start feeding", "Log wet diaper", or "Begin nap".';
      }
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Unknown error';
    }

    // Log the command
    await supabase.from('voice_commands').insert({
      user_id: userId,
      baby_id: babyId,
      transcript,
      parsed_command: parsedCommand,
      was_successful: wasSuccessful,
      error_message: errorMessage || null,
    });

    return new Response(
      JSON.stringify({
        success: wasSuccessful,
        command: parsedCommand,
        error: errorMessage || null,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error processing voice command:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});