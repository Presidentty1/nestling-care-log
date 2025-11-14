import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';

export default function AcceptInvite() {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();
  const [invite, setInvite] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [accepting, setAccepting] = useState(false);

  useEffect(() => {
    loadInvite();
  }, [token]);

  const loadInvite = async () => {
    if (!token) {
      navigate('/home');
      return;
    }

    try {
      const { data, error } = await supabase
        .from('caregiver_invites')
        .select('*, families(name)')
        .eq('token', token)
        .eq('status', 'pending')
        .single();

      if (error || !data) {
        toast.error('Invalid or expired invite');
        navigate('/home');
        return;
      }

      // Check if invite expired
      if (new Date(data.expires_at) < new Date()) {
        toast.error('This invite has expired');
        navigate('/home');
        return;
      }

      setInvite(data);
    } catch (error) {
      console.error('Error loading invite:', error);
      toast.error('Failed to load invite');
      navigate('/home');
    } finally {
      setLoading(false);
    }
  };

  const acceptInvite = async () => {
    if (!invite) return;

    setAccepting(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        // Redirect to auth with return URL
        localStorage.setItem('invite_token', token!);
        navigate('/auth');
        return;
      }

      // Add user to family
      const { error: memberError } = await supabase.from('family_members').insert({
        family_id: invite.family_id,
        user_id: user.id,
        role: invite.role,
      });

      if (memberError) throw memberError;

      // Mark invite as accepted
      await supabase
        .from('caregiver_invites')
        .update({ status: 'accepted' })
        .eq('id', invite.id);

      toast.success('Successfully joined the family!');
      navigate('/home');
    } catch (error: any) {
      console.error('Error accepting invite:', error);
      toast.error(error.message || 'Failed to accept invite');
    } finally {
      setAccepting(false);
    }
  };

  const declineInvite = async () => {
    if (!invite) return;

    try {
      await supabase
        .from('caregiver_invites')
        .update({ status: 'declined' })
        .eq('id', invite.id);

      toast.success('Invite declined');
      navigate('/home');
    } catch (error) {
      console.error('Error declining invite:', error);
      toast.error('Failed to decline invite');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center">
        <p>Loading invite...</p>
      </div>
    );
  }

  if (!invite) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center">
        <p>Invite not found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader>
          <CardTitle className="text-center">You've been invited!</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="text-center">
            <p className="text-4xl mb-4">👪</p>
            <p className="text-lg font-medium mb-2">
              Join {invite.families?.name || 'the family'}
            </p>
            <p className="text-muted-foreground">
              You've been invited to help care for the baby as a{' '}
              <span className="font-medium">{invite.role}</span>.
            </p>
          </div>

          <div className="space-y-2">
            <div className="text-sm">
              <span className="text-muted-foreground">Role: </span>
              <span className="font-medium capitalize">{invite.role}</span>
            </div>
            {invite.role === 'admin' && (
              <p className="text-xs text-muted-foreground">
                Full access - Can log activities, invite others, and manage settings
              </p>
            )}
            {invite.role === 'member' && (
              <p className="text-xs text-muted-foreground">
                Can log and view all activities
              </p>
            )}
            {invite.role === 'viewer' && (
              <p className="text-xs text-muted-foreground">Read-only access to view activities</p>
            )}
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={declineInvite}
              disabled={accepting}
            >
              Decline
            </Button>
            <Button className="flex-1" onClick={acceptInvite} disabled={accepting}>
              {accepting ? 'Accepting...' : 'Accept Invite'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
