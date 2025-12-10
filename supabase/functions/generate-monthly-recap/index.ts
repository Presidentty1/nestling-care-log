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
    const { babyId, year, month } = await req.json();

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Get data for the month
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    // Get milestones
    const { data: milestones } = await supabaseClient
      .from('milestones')
      .select('*')
      .eq('baby_id', babyId)
      .gte('achieved_date', startDate.toISOString())
      .lte('achieved_date', endDate.toISOString())
      .order('achieved_date', { ascending: false });

    // Get growth records
    const { data: growthRecords } = await supabaseClient
      .from('growth_records')
      .select('*')
      .eq('baby_id', babyId)
      .gte('recorded_at', startDate.toISOString())
      .lte('recorded_at', endDate.toISOString())
      .order('recorded_at', { ascending: false });

    // Get events summary
    const { data: events } = await supabaseClient
      .from('events')
      .select('type')
      .eq('baby_id', babyId)
      .gte('start_time', startDate.toISOString())
      .lte('start_time', endDate.toISOString());

    const eventsSummary =
      events?.reduce((acc: any, event) => {
        acc[event.type] = (acc[event.type] || 0) + 1;
        return acc;
      }, {}) || {};

    // Get journal entries
    const { data: journalEntries } = await supabaseClient
      .from('journal_entries')
      .select('*')
      .eq('baby_id', babyId)
      .gte('entry_date', startDate.toISOString().split('T')[0])
      .lte('entry_date', endDate.toISOString().split('T')[0])
      .order('entry_date', { ascending: false })
      .limit(5);

    // Extract funny moments and firsts
    const funnyMoments = journalEntries?.flatMap(e => e.funny_moments || []).slice(0, 5) || [];
    const firsts = journalEntries?.flatMap(e => e.firsts || []).slice(0, 5) || [];

    const highlights = {
      milestones: milestones?.slice(0, 5) || [],
      growthRecords: growthRecords?.slice(0, 1) || [],
      eventsSummary,
      funnyMoments,
      firsts,
      totalJournalEntries: journalEntries?.length || 0,
    };

    // Check if recap already exists
    const { data: existingRecap } = await supabaseClient
      .from('monthly_recaps')
      .select('id')
      .eq('baby_id', babyId)
      .eq('year', year)
      .eq('month', month)
      .single();

    if (existingRecap) {
      // Update existing
      await supabaseClient
        .from('monthly_recaps')
        .update({
          highlights,
          generated_at: new Date().toISOString(),
        })
        .eq('id', existingRecap.id);
    } else {
      // Create new
      await supabaseClient.from('monthly_recaps').insert({
        baby_id: babyId,
        year,
        month,
        highlights,
        generated_at: new Date().toISOString(),
      });
    }

    return new Response(
      JSON.stringify({
        highlights,
        message: 'Monthly recap generated successfully',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error in generate-monthly-recap:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
