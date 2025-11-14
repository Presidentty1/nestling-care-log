import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Baby, Plus, Edit, Trash2 } from 'lucide-react';
import { format, differenceInMonths, differenceInDays } from 'date-fns';
import { Baby as BabyType } from '@/lib/types';

export default function ManageBabies() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [babies, setBabies] = useState<BabyType[]>([]);
  const [familyId, setFamilyId] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingBaby, setEditingBaby] = useState<BabyType | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  
  // Form fields
  const [name, setName] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [sex, setSex] = useState('');
  const [feedingStyle, setFeedingStyle] = useState('');

  useEffect(() => {
    if (!user) {
      navigate('/auth');
      return;
    }
    loadBabies();
  }, [user, navigate]);

  const loadBabies = async () => {
    try {
      const { data: familyMembers, error: fmError } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user!.id);

      if (fmError) throw fmError;
      if (!familyMembers || familyMembers.length === 0) {
        navigate('/onboarding');
        return;
      }

      const famId = familyMembers[0].family_id;
      setFamilyId(famId);

      const { data: babiesData, error: babiesError } = await supabase
        .from('babies')
        .select('*')
        .eq('family_id', famId)
        .order('created_at', { ascending: false });

      if (babiesError) throw babiesError;
      setBabies(babiesData as BabyType[] || []);
    } catch (error) {
      console.error('Error loading babies:', error);
      toast.error('Failed to load babies');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (baby?: BabyType) => {
    if (baby) {
      setEditingBaby(baby);
      setName(baby.name);
      setDateOfBirth(baby.date_of_birth);
      setSex(baby.sex || '');
      setFeedingStyle(baby.primary_feeding_style || '');
    } else {
      setEditingBaby(null);
      setName('');
      setDateOfBirth('');
      setSex('');
      setFeedingStyle('');
    }
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (!name || !dateOfBirth || !familyId) {
      toast.error('Please fill in required fields');
      return;
    }

    setIsSaving(true);
    try {
      if (editingBaby) {
        // Update
        const { error } = await supabase
          .from('babies')
          .update({
            name,
            date_of_birth: dateOfBirth,
            sex: sex || null,
            primary_feeding_style: feedingStyle || null,
          })
          .eq('id', editingBaby.id);

        if (error) throw error;
        toast.success('Baby updated');
      } else {
        // Create
        const { error } = await supabase
          .from('babies')
          .insert({
            family_id: familyId,
            name,
            date_of_birth: dateOfBirth,
            sex: sex || null,
            primary_feeding_style: feedingStyle || null,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          });

        if (error) throw error;
        toast.success('Baby added');
      }

      setDialogOpen(false);
      loadBabies();
    } catch (error) {
      console.error('Error saving baby:', error);
      toast.error('Failed to save baby');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (babyId: string) => {
    if (!confirm('Are you sure you want to delete this baby? All events will also be deleted.')) {
      return;
    }

    try {
      const { error } = await supabase
        .from('babies')
        .delete()
        .eq('id', babyId);

      if (error) throw error;

      toast.success('Baby deleted');
      loadBabies();
    } catch (error) {
      console.error('Error deleting baby:', error);
      toast.error('Failed to delete baby');
    }
  };

  const getAge = (dob: string) => {
    const birthDate = new Date(dob);
    const months = differenceInMonths(new Date(), birthDate);
    
    if (months < 1) {
      const days = differenceInDays(new Date(), birthDate);
      return `${days} day${days !== 1 ? 's' : ''}`;
    } else if (months < 12) {
      return `${months} month${months !== 1 ? 's' : ''}`;
    } else {
      const years = Math.floor(months / 12);
      const remainingMonths = months % 12;
      return remainingMonths > 0 
        ? `${years}y ${remainingMonths}m`
        : `${years} year${years !== 1 ? 's' : ''}`;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface pb-20 flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Baby className="h-6 w-6" />
            Manage Babies
          </h1>
          <Button onClick={() => handleOpenDialog()}>
            <Plus className="h-4 w-4 mr-2" />
            Add Baby
          </Button>
        </div>

        <div className="space-y-3">
          {babies.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <Baby className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-muted-foreground mb-4">No babies added yet</p>
                <Button onClick={() => handleOpenDialog()}>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Your First Baby
                </Button>
              </CardContent>
            </Card>
          ) : (
            babies.map((baby) => (
              <Card key={baby.id}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-12 w-12">
                        <AvatarFallback className="bg-primary text-primary-foreground text-lg">
                          {baby.name[0]}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-bold text-lg">{baby.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {format(new Date(baby.date_of_birth), 'MMM d, yyyy')} · {getAge(baby.date_of_birth)}
                        </p>
                        <div className="flex gap-2 mt-1">
                          {baby.sex && (
                            <Badge variant="secondary" className="text-xs">
                              {baby.sex}
                            </Badge>
                          )}
                          {baby.primary_feeding_style && (
                            <Badge variant="outline" className="text-xs">
                              {baby.primary_feeding_style}
                            </Badge>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleOpenDialog(baby)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(baby.id)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>

        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingBaby ? 'Edit Baby' : 'Add New Baby'}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Name *</Label>
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Baby's name"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="dob">Date of Birth *</Label>
                <Input
                  id="dob"
                  type="date"
                  value={dateOfBirth}
                  onChange={(e) => setDateOfBirth(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sex">Sex</Label>
                <Select value={sex} onValueChange={setSex}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select sex" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="feeding">Primary Feeding Style</Label>
                <Select value={feedingStyle} onValueChange={setFeedingStyle}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select feeding style" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="breastfeeding">Breastfeeding</SelectItem>
                    <SelectItem value="bottle">Bottle</SelectItem>
                    <SelectItem value="mixed">Mixed</SelectItem>
                    <SelectItem value="solids">Solids</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="flex gap-2 pt-2">
                <Button variant="outline" onClick={() => setDialogOpen(false)} className="flex-1">
                  Cancel
                </Button>
                <Button onClick={handleSave} disabled={isSaving} className="flex-1">
                  {isSaving ? 'Saving...' : 'Save'}
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>
      <MobileNav />
    </div>
  );
}
