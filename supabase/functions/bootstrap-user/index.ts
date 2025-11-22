import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { format, subDays } from "https://esm.sh/date-fns@3.6.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      throw new Error('Unauthorized');
    }

    console.log('Bootstrap request for user:', user.id);

    // Parse request body for optional customization
    const body = await req.json().catch(() => ({}));
    const babyName = body.babyName || 'Demo Baby';
    const dateOfBirth = body.dateOfBirth || format(subDays(new Date(), 60), 'yyyy-MM-dd');
    const timezone = body.timezone || 'America/New_York';

    // Check if user already has at least one family membership (idempotent)
    const { data: memberships, error: membershipError } = await supabase
      .from('family_members')
      .select('family_id, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: true });

    // If any memberships exist, pick the earliest family and ensure a baby exists

    const hasMembership = memberships && memberships.length > 0;

    if (hasMembership) {
      const familyId = memberships![0].family_id;
      console.log('User already has family:', familyId);
      
      // Get the first baby in this family
      const { data: babies } = await supabase
        .from('babies')
        .select('id')
        .eq('family_id', familyId)
        .limit(1);

      if (babies && babies.length > 0) {
        return new Response(
          JSON.stringify({ 
            familyId, 
            babyId: babies[0].id,
            existed: true 
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // User has family but no babies - create just the baby
      console.log('Creating baby for existing family');
      const { data: baby, error: babyError } = await supabase
        .from('babies')
        .insert({
          family_id: familyId,
          name: babyName,
          date_of_birth: dateOfBirth,
          timezone
        })
        .select()
        .single();

      if (babyError) {
        console.error('Baby creation error:', babyError);
        throw new Error(`Failed to create baby: ${  babyError.message}`);
      }

      console.log('Created baby:', baby.id);

      return new Response(
        JSON.stringify({ 
          familyId, 
          babyId: baby.id,
          existed: false
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('Creating new family and baby for user:', user.id);

    // 1. Create family
    const { data: family, error: familyError } = await supabase
      .from('families')
      .insert({ name: 'My Family' })
      .select()
      .single();

    if (familyError) {
      console.error('Family creation error:', familyError);
      throw new Error(`Failed to create family: ${  familyError.message}`);
    }

    console.log('Created family:', family.id);

    // 2. Create family member
    const { error: memberError } = await supabase
      .from('family_members')
      .insert({
        family_id: family.id,
        user_id: user.id,
        role: 'admin'
      });

    if (memberError) {
      console.error('Family member creation error:', memberError);
      throw new Error(`Failed to create family member: ${  memberError.message}`);
    }

    console.log('Created family member');

    // 3. Ensure user role (idempotent)
    const { error: roleError } = await supabase
      .from('user_roles')
      .upsert({
        user_id: user.id,
        family_id: family.id,
        role: 'admin'
      }, { onConflict: 'user_id,family_id' });

    if (roleError) {
      console.error('User role upsert error:', roleError);
      throw new Error(`Failed to upsert user role: ${  roleError.message}`);
    }

    console.log('Created user role');

    // 4. Create baby
    const { data: baby, error: babyError } = await supabase
      .from('babies')
      .insert({
        family_id: family.id,
        name: babyName,
        date_of_birth: dateOfBirth,
        timezone
      })
      .select()
      .single();

    if (babyError) {
      console.error('Baby creation error:', babyError);
      throw new Error(`Failed to create baby: ${  babyError.message}`);
    }

    console.log('Created baby:', baby.id);

    return new Response(
      JSON.stringify({ 
        familyId: family.id, 
        babyId: baby.id,
        existed: false
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    console.error('Bootstrap error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Unknown error occurred' }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
