import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ArrowLeft, UserPlus, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

interface FamilyMember {
  id: string;
  user_id: string;
  role: 'admin' | 'member' | 'viewer';
  profiles: {
    name: string | null;
    email: string | null;
  } | null;
}

interface Invite {
  id: string;
  email: string;
  role: string;
  status: string;
  created_at: string;
}

export default function CaregiverManagement() {
  const navigate = useNavigate();
  const [familyId, setFamilyId] = useState<string | null>(null);
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [invites, setInvites] = useState<Invite[]>([]);
  const [isInviteModalOpen, setIsInviteModalOpen] = useState(false);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState<'admin' | 'member' | 'viewer'>('member');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        navigate('/auth');
        return;
      }

      // Get user's family
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id, role')
        .eq('user_id', user.id)
        .single();

      if (!familyMembers) {
        toast.error('No family found');
        navigate('/home');
        return;
      }

      setFamilyId(familyMembers.family_id);

      // Load family members with profiles
      const { data: membersData } = await supabase
        .from('family_members')
        .select(`
          id,
          user_id,
          role,
          profiles (
            name,
            email
          )
        `)
        .eq('family_id', familyMembers.family_id);

      // Transform the data to match our interface
      const transformedMembers = (membersData || []).map((m: any) => ({
        id: m.id,
        user_id: m.user_id,
        role: m.role,
        profiles: Array.isArray(m.profiles) && m.profiles.length > 0 ? m.profiles[0] : null,
      }));

      setMembers(transformedMembers as FamilyMember[]);

      // Load pending invites
      const { data: invitesData } = await supabase
        .from('caregiver_invites')
        .select('*')
        .eq('family_id', familyMembers.family_id)
        .eq('status', 'pending');

      setInvites(invitesData || []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const sendInvite = async () => {
    if (!familyId || !inviteEmail) return;

    try {
      const { data, error } = await supabase.functions.invoke('invite-caregiver', {
        body: {
          email: inviteEmail,
          familyId,
          role: inviteRole,
        },
      });

      if (error) throw error;

      toast.success('Invite sent!');
      setIsInviteModalOpen(false);
      setInviteEmail('');
      setInviteRole('member');
      loadData();
    } catch (error: any) {
      console.error('Error sending invite:', error);
      toast.error(error.message || 'Failed to send invite');
    }
  };

  const removeMember = async (memberId: string) => {
    try {
      const { error } = await supabase.from('family_members').delete().eq('id', memberId);

      if (error) throw error;

      toast.success('Caregiver removed');
      loadData();
    } catch (error: any) {
      console.error('Error removing member:', error);
      toast.error(error.message || 'Failed to remove caregiver');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => navigate('/settings')}>
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <h1 className="text-2xl font-bold">Caregivers</h1>
          </div>
          <Button onClick={() => setIsInviteModalOpen(true)}>
            <UserPlus className="h-4 w-4 mr-2" />
            Invite
          </Button>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Current Caregivers</CardTitle>
          </CardHeader>
          <CardContent>
            {members.length === 0 ? (
              <p className="text-muted-foreground text-center py-4">No caregivers yet</p>
            ) : (
              <div className="space-y-3">
                {members.map((member) => (
                  <div key={member.id} className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">
                        {member.profiles?.name || member.profiles?.email || 'Unknown'}
                      </p>
                      {member.profiles?.email && member.profiles?.name && (
                        <p className="text-sm text-muted-foreground">{member.profiles.email}</p>
                      )}
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={member.role === 'admin' ? 'default' : 'secondary'}>
                        {member.role}
                      </Badge>
                      {member.role !== 'admin' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeMember(member.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {invites.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Pending Invites</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {invites.map((invite) => (
                  <div key={invite.id} className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">{invite.email}</p>
                      <p className="text-sm text-muted-foreground">
                        Sent {new Date(invite.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <Badge variant="outline">{invite.role}</Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        <Dialog open={isInviteModalOpen} onOpenChange={setIsInviteModalOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Invite Caregiver</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div>
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="partner@example.com"
                  value={inviteEmail}
                  onChange={(e) => setInviteEmail(e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="role">Role</Label>
                <Select value={inviteRole} onValueChange={(v: any) => setInviteRole(v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">
                      <div>
                        <p className="font-medium">Admin</p>
                        <p className="text-xs text-muted-foreground">
                          Full access, can invite/remove
                        </p>
                      </div>
                    </SelectItem>
                    <SelectItem value="member">
                      <div>
                        <p className="font-medium">Member</p>
                        <p className="text-xs text-muted-foreground">Can log and edit events</p>
                      </div>
                    </SelectItem>
                    <SelectItem value="viewer">
                      <div>
                        <p className="font-medium">Viewer</p>
                        <p className="text-xs text-muted-foreground">Read-only access</p>
                      </div>
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsInviteModalOpen(false)}>
                Cancel
              </Button>
              <Button onClick={sendInvite} disabled={!inviteEmail}>
                Send Invite
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  );
}
