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

    const { email, familyId, role } = await req.json();

    // Verify user is admin of this family
    const { data: membership, error: memberError } = await supabase
      .from('family_members')
      .select('role')
      .eq('family_id', familyId)
      .eq('user_id', user.id)
      .single();

    if (memberError || membership.role !== 'admin') {
      throw new Error('Only admins can invite caregivers');
    }

    // Check if email already in family
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (profiles) {
      const { data: existingMember } = await supabase
        .from('family_members')
        .select('id')
        .eq('family_id', familyId)
        .eq('user_id', profiles.id)
        .maybeSingle();

      if (existingMember) {
        throw new Error('User is already a member of this family');
      }
    }

    // Check for existing pending invite
    const { data: existingInvite } = await supabase
      .from('caregiver_invites')
      .select('id, status')
      .eq('family_id', familyId)
      .eq('email', email)
      .eq('status', 'pending')
      .maybeSingle();

    if (existingInvite) {
      throw new Error('An invite is already pending for this email');
    }

    // Create invite
    const { data: invite, error: inviteError } = await supabase
      .from('caregiver_invites')
      .insert({
        family_id: familyId,
        email,
        role,
        invited_by: user.id,
      })
      .select()
      .single();

    if (inviteError) throw inviteError;

    // Send invite email using Supabase Auth
    const inviteUrl = `${req.headers.get('origin')}/invite/${invite.token}`;
    
    try {
      const { error: emailError } = await supabase.auth.admin.inviteUserByEmail(
        email,
        {
          data: {
            invite_token: invite.token,
            family_id: familyId,
            role,
          },
          redirectTo: inviteUrl,
        }
      );

      if (emailError) {
        console.error('Email error:', emailError);
      }
    } catch (emailErr) {
      console.error('Failed to send email:', emailErr);
      // Don't fail the request if email fails
    }

    return new Response(
      JSON.stringify({ success: true, invite }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Unknown error occurred' }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
