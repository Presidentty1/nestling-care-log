import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';
import { Pencil, Trash2, Plus, ChevronLeft } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import type { Baby } from '@/types/events';
import { getAgeDisplay } from '@/services/time';
import { toast } from 'sonner';

export default function ManageBabies() {
  const navigate = useNavigate();
  const { activeBabyId, setActiveBabyId } = useAppStore();
  const [babies, setBabies] = useState<Baby[]>([]);
  const [editingBaby, setEditingBaby] = useState<Baby | null>(null);
  const [deletingBabyId, setDeletingBabyId] = useState<string | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  useEffect(() => {
    loadBabies();
  }, []);

  const loadBabies = async () => {
    const babyList = await dataService.listBabies();
    setBabies(babyList);
  };

  const handleEdit = (baby: Baby) => {
    setEditingBaby(baby);
    setIsDialogOpen(true);
  };

  const handleDelete = async (babyId: string) => {
    await dataService.deleteBaby(babyId);
    
    if (babyId === activeBabyId) {
      const remaining = babies.filter(b => b.id !== babyId);
      if (remaining.length > 0) {
        setActiveBabyId(remaining[0].id);
      } else {
        setActiveBabyId(null);
        navigate('/onboarding-simple');
      }
    }
    
    toast.success('Baby profile deleted');
    loadBabies();
    setDeletingBabyId(null);
  };

  const handleSave = async (updates: Partial<Baby>) => {
    if (!editingBaby) return;
    
    await dataService.updateBaby(editingBaby.id, updates);
    toast.success('Profile updated');
    loadBabies();
    setIsDialogOpen(false);
    setEditingBaby(null);
  };

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={() => navigate('/settings')}>
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-2xl font-bold">Manage Babies</h1>
        </div>

        <div className="space-y-3">
          {babies.map((baby) => (
            <Card key={baby.id}>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <Avatar className="h-12 w-12">
                    <AvatarFallback>{getInitials(baby.name)}</AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <div className="font-medium">{baby.name}</div>
                    <div className="text-sm text-muted-foreground">
                      {getAgeDisplay(baby.dobISO)}
                      {baby.id === activeBabyId && (
                        <span className="ml-2 text-primary">(Active)</span>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleEdit(baby)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setDeletingBabyId(baby.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <Button
          className="w-full"
          onClick={() => navigate('/onboarding-simple')}
        >
          <Plus className="mr-2 h-4 w-4" />
          Add New Baby
        </Button>
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Profile</DialogTitle>
          </DialogHeader>
          {editingBaby && (
            <BabyEditForm
              baby={editingBaby}
              onSave={handleSave}
              onCancel={() => setIsDialogOpen(false)}
            />
          )}
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deletingBabyId} onOpenChange={() => setDeletingBabyId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Baby Profile?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete all data for this baby, including events. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deletingBabyId && handleDelete(deletingBabyId)}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

function BabyEditForm({ baby, onSave, onCancel }: any) {
  const [name, setName] = useState(baby.name);

  return (
    <div className="space-y-4">
      <div>
        <Label>Name</Label>
        <Input value={name} onChange={(e) => setName(e.target.value)} />
      </div>
      <DialogFooter>
        <Button variant="outline" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave({ name })}>Save</Button>
      </DialogFooter>
    </div>
  );
}
