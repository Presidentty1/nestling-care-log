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
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
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

    // Use service role client for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    console.log(`[Delete Account] Starting deletion for user: ${user.id}`);

    // Delete user data in order (respecting foreign key constraints)
    // 1. Delete AI conversations
    const { error: conversationsError } = await supabaseAdmin
      .from('ai_conversations')
      .delete()
      .eq('user_id', user.id);

    if (conversationsError) {
      console.error('[Delete Account] Error deleting conversations:', conversationsError);
    }

    // 2. Delete babies (this will cascade to events via foreign keys if configured)
    const { data: babies } = await supabaseAdmin
      .from('babies')
      .select('id')
      .eq('user_id', user.id);

    if (babies && babies.length > 0) {
      // Delete events for each baby
      for (const baby of babies) {
        const { error: eventsError } = await supabaseAdmin
          .from('events')
          .delete()
          .eq('baby_id', baby.id);

        if (eventsError) {
          console.error(`[Delete Account] Error deleting events for baby ${baby.id}:`, eventsError);
        }
      }

      // Delete babies
      const { error: babiesError } = await supabaseAdmin
        .from('babies')
        .delete()
        .eq('user_id', user.id);

      if (babiesError) {
        console.error('[Delete Account] Error deleting babies:', babiesError);
      }
    }

    // 3. Delete profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .delete()
      .eq('id', user.id);

    if (profileError) {
      console.error('[Delete Account] Error deleting profile:', profileError);
    }

    // 4. Delete auth user (requires service role)
    const { error: deleteUserError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

    if (deleteUserError) {
      console.error('[Delete Account] Error deleting auth user:', deleteUserError);
      return new Response(
        JSON.stringify({ error: 'Failed to delete user account', details: deleteUserError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    console.log(`[Delete Account] Successfully deleted account for user: ${user.id}`);

    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted successfully' }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('[Delete Account] Unexpected error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});


