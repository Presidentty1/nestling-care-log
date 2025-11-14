import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby, Milestone } from '@/lib/types';
import { milestoneCategories } from '@/lib/milestoneCategories';
import { uploadPhoto, compressImage } from '@/lib/photoUtils';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Camera, X } from 'lucide-react';
import { toast } from 'sonner';

interface MilestoneModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  baby: Baby;
  milestone: Milestone | null;
  onSaved: () => void;
}

export function MilestoneModal({ open, onOpenChange, baby, milestone, onSaved }: MilestoneModalProps) {
  const [category, setCategory] = useState(milestone?.milestone_type || 'motor');
  const [title, setTitle] = useState(milestone?.title || '');
  const [description, setDescription] = useState(milestone?.description || '');
  const [date, setDate] = useState(milestone?.achieved_date || new Date().toISOString().split('T')[0]);
  const [note, setNote] = useState(milestone?.note || '');
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState(milestone?.photo_url || '');
  const [uploading, setUploading] = useState(false);

  const queryClient = useQueryClient();

  const saveMutation = useMutation({
    mutationFn: async () => {
      let photoUrl = milestone?.photo_url || null;

      // Upload photo if new file selected
      if (photoFile) {
        setUploading(true);
        const compressed = await compressImage(photoFile, 1200, 0.8);
        photoUrl = await uploadPhoto(baby.id, 'milestones', new File([compressed], photoFile.name));
        setUploading(false);
      }

      const data = {
        baby_id: baby.id,
        milestone_type: category,
        title,
        description: description || null,
        achieved_date: date,
        note: note || null,
        photo_url: photoUrl,
      };

      if (milestone?.id) {
        const { error } = await supabase
          .from('milestones')
          .update(data)
          .eq('id', milestone.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('milestones')
          .insert(data);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['milestones'] });
      toast.success(milestone ? 'Milestone updated' : 'Milestone added');
      onSaved();
    },
    onError: (error) => {
      toast.error('Failed to save milestone');
      console.error(error);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async () => {
      if (!milestone?.id) return;
      const { error } = await supabase
        .from('milestones')
        .delete()
        .eq('id', milestone.id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['milestones'] });
      toast.success('Milestone deleted');
      onSaved();
    },
  });

  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setPhotoFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const selectedCategory = milestoneCategories.find(c => c.type === category);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {milestone?.id ? 'Edit Milestone' : 'Add Milestone'}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Category</Label>
            <Select value={category} onValueChange={setCategory}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {milestoneCategories.map(cat => (
                  <SelectItem key={cat.type} value={cat.type}>
                    {cat.icon} {cat.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>Milestone</Label>
            {selectedCategory && selectedCategory.milestones.length > 0 ? (
              <Select value={title} onValueChange={(value) => {
                setTitle(value);
                const template = selectedCategory.milestones.find(m => m.title === value);
                if (template) {
                  setDescription(template.description);
                }
              }}>
                <SelectTrigger>
                  <SelectValue placeholder="Select or type custom..." />
                </SelectTrigger>
                <SelectContent>
                  {selectedCategory.milestones.map(m => (
                    <SelectItem key={m.title} value={m.title}>
                      {m.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            ) : null}
            <Input
              placeholder="Or enter custom milestone"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label>Description (optional)</Label>
            <Input
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label>Date Achieved</Label>
            <Input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label>Photo (optional)</Label>
            {photoPreview ? (
              <div className="relative">
                <img
                  src={photoPreview}
                  alt="Preview"
                  className="w-full rounded-lg"
                />
                <Button
                  size="icon"
                  variant="destructive"
                  className="absolute top-2 right-2"
                  onClick={() => {
                    setPhotoFile(null);
                    setPhotoPreview('');
                  }}
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            ) : (
              <label className="flex items-center justify-center w-full h-32 border-2 border-dashed rounded-lg cursor-pointer hover:bg-muted/50 transition-colors">
                <div className="text-center">
                  <Camera className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground">Add Photo</p>
                </div>
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={handlePhotoSelect}
                />
              </label>
            )}
          </div>

          <div className="space-y-2">
            <Label>Notes (optional)</Label>
            <Textarea
              placeholder="Share your thoughts about this milestone..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={3}
            />
          </div>

          <div className="flex gap-2">
            <Button
              onClick={() => saveMutation.mutate()}
              disabled={!title || saveMutation.isPending || uploading}
              className="flex-1"
            >
              {uploading ? 'Uploading...' : saveMutation.isPending ? 'Saving...' : 'Save Milestone'}
            </Button>
            {milestone?.id && (
              <Button
                variant="destructive"
                onClick={() => deleteMutation.mutate()}
                disabled={deleteMutation.isPending}
              >
                Delete
              </Button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
