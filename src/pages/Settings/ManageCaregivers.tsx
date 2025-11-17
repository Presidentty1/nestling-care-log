import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerFooter, DrawerClose } from '@/components/ui/drawer';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ChevronLeft, UserPlus, Trash2, Mail, Clock } from 'lucide-react';
import { toast } from 'sonner';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';

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

export default function ManageCaregivers() {
  const navigate = useNavigate();
  const [familyId, setFamilyId] = useState<string | null>(null);
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [invites, setInvites] = useState<Invite[]>([]);
  const [isInviteSheetOpen, setIsInviteSheetOpen] = useState(false);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState<'admin' | 'member' | 'viewer'>('member');
  const [loading, setLoading] = useState(true);
  const [inviting, setInviting] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<{ open: boolean; memberId: string | null }>({
    open: false,
    memberId: null,
  });

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

      // Transform the data
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

    setInviting(true);
    try {
      const { error } = await supabase.functions.invoke('invite-caregiver', {
        body: {
          email: inviteEmail,
          familyId,
          role: inviteRole,
        },
      });

      if (error) throw error;

      toast.success('Invite sent!');
      setIsInviteSheetOpen(false);
      setInviteEmail('');
      setInviteRole('member');
      loadData();
    } catch (error: any) {
      console.error('Error sending invite:', error);
      toast.error(error.message || 'Failed to send invite');
    } finally {
      setInviting(false);
    }
  };

  const removeMember = async (memberId: string) => {
    try {
      const { error } = await supabase
        .from('family_members')
        .delete()
        .eq('id', memberId);

      if (error) throw error;

      toast.success('Caregiver removed');
      loadData();
    } catch (error) {
      console.error('Error removing member:', error);
      toast.error('Failed to remove caregiver');
    }
  };

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case 'admin':
        return 'bg-primary/10 text-primary border-primary/20';
      case 'member':
        return 'bg-accent/10 text-accent-foreground border-accent/20';
      case 'viewer':
        return 'bg-muted text-muted-foreground border-border';
      default:
        return 'bg-muted text-muted-foreground border-border';
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) return 'Today';
    if (days === 1) return 'Yesterday';
    if (days < 7) return `${days} days ago`;
    return date.toLocaleDateString();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-6">
        {/* Header */}
        <div className="flex items-center gap-3">
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={() => navigate('/settings')}
            className="h-11 w-11"
          >
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <div className="flex-1">
            <h1 className="text-[28px] leading-[34px] font-semibold">Caregivers</h1>
          </div>
          <Button
            onClick={() => setIsInviteSheetOpen(true)}
            className="gap-2 h-11 px-4 rounded-[14px]"
          >
            <UserPlus className="h-4 w-4" />
            Invite
          </Button>
        </div>

        {/* Current Caregivers */}
        <Card className="shadow-soft">
          <CardHeader>
            <CardTitle className="text-[17px] font-semibold">Current Caregivers</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {members.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <p className="text-[15px]">No caregivers yet</p>
              </div>
            ) : (
              members.map((member) => (
                <div
                  key={member.id}
                  className="flex items-center gap-4 p-4 rounded-[12px] bg-surface border border-border hover:bg-accent/5 transition-colors min-h-[64px]"
                >
                  <div className="h-11 w-11 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                    <span className="text-primary font-semibold text-[15px]">
                      {(member.profiles?.name || member.profiles?.email || 'U')[0].toUpperCase()}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-[17px] text-foreground truncate">
                      {member.profiles?.name || 'User'}
                    </p>
                    <div className="flex items-center gap-2 mt-1">
                      <Mail className="h-3.5 w-3.5 text-muted-foreground flex-shrink-0" />
                      <p className="text-[15px] text-muted-foreground truncate">
                        {member.profiles?.email || 'No email'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <Badge className={`${getRoleBadgeColor(member.role)} text-[13px] capitalize`}>
                      {member.role}
                    </Badge>
                    {member.role !== 'admin' && (
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-11 w-11 text-danger hover:text-danger hover:bg-danger/10"
                        onClick={() => setDeleteConfirm({ open: true, memberId: member.id })}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Pending Invites */}
        {invites.length > 0 && (
          <Card className="shadow-soft">
            <CardHeader>
              <CardTitle className="text-[17px] font-semibold">Pending Invites</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {invites.map((invite) => (
                <div
                  key={invite.id}
                  className="flex items-center gap-4 p-4 rounded-[12px] bg-surface border border-border min-h-[64px]"
                >
                  <div className="h-11 w-11 rounded-full bg-warning/10 flex items-center justify-center flex-shrink-0">
                    <Clock className="h-5 w-5 text-warning" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-[17px] text-foreground truncate">{invite.email}</p>
                    <p className="text-[15px] text-muted-foreground">Sent {formatDate(invite.created_at)}</p>
                  </div>
                  <Badge className="bg-warning/10 text-warning border-warning/20 text-[13px]">
                    Pending
                  </Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        )}

        {/* Info */}
        <Alert>
          <AlertDescription className="text-[15px] text-muted-foreground">
            Caregivers can view and log events for your baby. Admins can also manage caregivers and settings.
          </AlertDescription>
        </Alert>
      </div>

      {/* Invite Sheet */}
      <Drawer open={isInviteSheetOpen} onOpenChange={setIsInviteSheetOpen}>
        <DrawerContent>
          <DrawerHeader>
            <DrawerTitle className="text-[22px] font-semibold">Invite Caregiver</DrawerTitle>
          </DrawerHeader>
          <div className="px-4 py-6 space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-[15px] font-semibold">Email Address</Label>
              <Input
                id="email"
                type="email"
                placeholder="caregiver@example.com"
                value={inviteEmail}
                onChange={(e) => setInviteEmail(e.target.value)}
                className="h-12 text-[17px] rounded-[12px]"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="role" className="text-[15px] font-semibold">Role</Label>
              <Select value={inviteRole} onValueChange={(v) => setInviteRole(v as any)}>
                <SelectTrigger id="role" className="h-12 text-[17px] rounded-[12px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="admin" className="text-[17px]">Admin (full access)</SelectItem>
                  <SelectItem value="member" className="text-[17px]">Member (can log)</SelectItem>
                  <SelectItem value="viewer" className="text-[17px]">Viewer (read only)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DrawerFooter>
            <div className="flex gap-3">
              <DrawerClose asChild>
                <Button variant="outline" className="flex-1 h-12 text-[17px] rounded-[14px]">
                  Cancel
                </Button>
              </DrawerClose>
              <Button
                onClick={sendInvite}
                disabled={!inviteEmail || inviting}
                className="flex-1 h-12 text-[17px] rounded-[14px]"
              >
                {inviting ? 'Sending...' : 'Send Invite'}
              </Button>
            </div>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>

      {/* Delete Confirmation */}
      <ConfirmDialog
        open={deleteConfirm.open}
        onOpenChange={(open) => setDeleteConfirm({ open, memberId: null })}
        onConfirm={() => {
          if (deleteConfirm.memberId) {
            removeMember(deleteConfirm.memberId);
            setDeleteConfirm({ open: false, memberId: null });
          }
        }}
        title="Remove Caregiver"
        description="Are you sure you want to remove this caregiver? They will no longer have access to your family's data."
        confirmText="Remove"
        variant="destructive"
      />
    </div>
  );
}
