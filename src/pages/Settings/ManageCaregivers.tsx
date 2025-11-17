import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ChevronLeft, Plus, Trash2, Users } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { EmptyState } from '@/components/common/EmptyState';
import { toast } from 'sonner';

interface Caregiver {
  id: string;
  email: string;
  role: 'admin' | 'member';
  addedAt: string;
}

const STORAGE_KEY = 'nestling-caregivers';

export default function ManageCaregivers() {
  const navigate = useNavigate();
  const [caregivers, setCaregivers] = useState<Caregiver[]>([]);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [newRole, setNewRole] = useState<'admin' | 'member'>('member');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  useEffect(() => {
    loadCaregivers();
  }, []);

  const loadCaregivers = () => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        setCaregivers(JSON.parse(stored));
      } catch (error) {
        console.error('Failed to load caregivers:', error);
      }
    }
  };

  const saveCaregivers = (list: Caregiver[]) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    setCaregivers(list);
  };

  const handleAddCaregiver = () => {
    if (!newEmail || !newEmail.includes('@')) {
      toast.error('Please enter a valid email address');
      return;
    }

    const exists = caregivers.some((c) => c.email === newEmail);
    if (exists) {
      toast.error('This caregiver has already been added');
      return;
    }

    const newCaregiver: Caregiver = {
      id: crypto.randomUUID(),
      email: newEmail,
      role: newRole,
      addedAt: new Date().toISOString(),
    };

    saveCaregivers([...caregivers, newCaregiver]);
    toast.success(`${newEmail} added as ${newRole}`);
    setIsAddDialogOpen(false);
    setNewEmail('');
    setNewRole('member');
  };

  const handleDeleteCaregiver = () => {
    if (!deleteId) return;
    
    const updated = caregivers.filter((c) => c.id !== deleteId);
    saveCaregivers(updated);
    toast.success('Caregiver removed');
    setDeleteId(null);
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={() => navigate('/settings')}>
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-2xl font-bold">Manage Caregivers</h1>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Caregiver Access</CardTitle>
            <CardDescription>
              Manage who can view and log activities. Real-time sync coming soon.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => setIsAddDialogOpen(true)} className="w-full">
              <Plus className="mr-2 h-4 w-4" />
              Add Caregiver
            </Button>
          </CardContent>
        </Card>

        {caregivers.length === 0 ? (
          <EmptyState
            icon={Users}
            title="No Caregivers Added"
            description="Add family members or caregivers to share baby care responsibilities"
            action={{
              label: 'Add First Caregiver',
              onClick: () => setIsAddDialogOpen(true),
            }}
          />
        ) : (
          <Card>
            <CardHeader>
              <CardTitle>Caregivers ({caregivers.length})</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {caregivers.map((caregiver) => (
                <div
                  key={caregiver.id}
                  className="flex items-center justify-between p-3 rounded-lg border"
                >
                  <div className="flex-1 min-w-0">
                    <div className="font-medium truncate">{caregiver.email}</div>
                    <div className="text-sm text-muted-foreground">
                      Added {new Date(caregiver.addedAt).toLocaleDateString()}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <Badge variant={caregiver.role === 'admin' ? 'default' : 'secondary'}>
                      {caregiver.role}
                    </Badge>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setDeleteId(caregiver.id)}
                      aria-label="Remove caregiver"
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>
        )}

        <Card className="bg-muted/50">
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground text-center">
              <strong>Note:</strong> Caregivers are stored locally on this device. Real-time
              collaboration and email invites will be available in a future update.
            </p>
          </CardContent>
        </Card>
      </div>

      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Caregiver</DialogTitle>
            <DialogDescription>
              Add a family member or caregiver to share access to baby care logs.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label htmlFor="email">Email Address</Label>
              <Input
                id="email"
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="caregiver@example.com"
                className="mt-1"
                autoFocus
              />
            </div>
            <div>
              <Label htmlFor="role">Role</Label>
              <Select value={newRole} onValueChange={(v: any) => setNewRole(v)}>
                <SelectTrigger id="role" className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="member">Member - Can view and log</SelectItem>
                  <SelectItem value="admin">Admin - Full access</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleAddCaregiver}>Add Caregiver</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={deleteId !== null}
        onOpenChange={(open) => !open && setDeleteId(null)}
        onConfirm={handleDeleteCaregiver}
        title="Remove Caregiver?"
        description="This caregiver will no longer appear in your local list. You can add them again later."
        confirmText="Remove"
        variant="destructive"
      />
    </div>
  );
}
