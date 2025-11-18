import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Pill, Plus, Trash2 } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { useAuth } from '@/hooks/useAuth';

interface ParentMedicationTrackerProps {
  medications: any[];
  onRefresh: () => void;
}

export function ParentMedicationTracker({ medications, onRefresh }: ParentMedicationTrackerProps) {
  const { user } = useAuth();
  const [showDialog, setShowDialog] = useState(false);
  const [formData, setFormData] = useState({
    medication_name: '',
    dosage: '',
    frequency: '',
    start_date: new Date().toISOString().split('T')[0],
    note: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const { error } = await supabase
        .from('parent_medications')
        .insert({
          user_id: user.id,
          ...formData,
        });

      if (error) throw error;

      toast.success('Medication added!');
      setShowDialog(false);
      setFormData({
        medication_name: '',
        dosage: '',
        frequency: '',
        start_date: new Date().toISOString().split('T')[0],
        note: '',
      });
      onRefresh();
    } catch (error) {
      console.error('Error adding medication:', error);
      toast.error('Failed to add medication');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from('parent_medications')
        .update({ is_active: false })
        .eq('id', id);

      if (error) throw error;

      toast.success('Medication removed');
      onRefresh();
    } catch (error) {
      console.error('Error removing medication:', error);
      toast.error('Failed to remove medication');
    }
  };

  return (
    <div className="space-y-3">
      {medications.length === 0 ? (
        <div className="text-center py-6 text-muted-foreground">
          <Pill className="h-8 w-8 mx-auto mb-2 opacity-50" />
          <p className="text-sm">No medications tracked yet</p>
        </div>
      ) : (
        <div className="space-y-2">
          {medications.map((med) => (
            <div
              key={med.id}
              className="flex items-center justify-between p-3 border rounded-lg"
            >
              <div className="flex-1">
                <p className="font-medium">{med.medication_name}</p>
                <p className="text-sm text-muted-foreground">
                  {med.dosage} • {med.frequency}
                </p>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleDelete(med.id)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          ))}
        </div>
      )}

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogTrigger asChild>
          <Button variant="outline" className="w-full">
            <Plus className="h-4 w-4 mr-2" />
            Add Medication/Supplement
          </Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Medication/Supplement</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label htmlFor="medication_name">Name *</Label>
              <Input
                id="medication_name"
                value={formData.medication_name}
                onChange={(e) =>
                  setFormData({ ...formData, medication_name: e.target.value })
                }
                placeholder="e.g., Prenatal vitamin"
                required
              />
            </div>
            <div>
              <Label htmlFor="dosage">Dosage</Label>
              <Input
                id="dosage"
                value={formData.dosage}
                onChange={(e) =>
                  setFormData({ ...formData, dosage: e.target.value })
                }
                placeholder="e.g., 1 tablet"
              />
            </div>
            <div>
              <Label htmlFor="frequency">Frequency</Label>
              <Input
                id="frequency"
                value={formData.frequency}
                onChange={(e) =>
                  setFormData({ ...formData, frequency: e.target.value })
                }
                placeholder="e.g., Once daily"
              />
            </div>
            <div>
              <Label htmlFor="start_date">Start Date</Label>
              <Input
                id="start_date"
                type="date"
                value={formData.start_date}
                onChange={(e) =>
                  setFormData({ ...formData, start_date: e.target.value })
                }
              />
            </div>
            <div>
              <Label htmlFor="note">Note</Label>
              <Input
                id="note"
                value={formData.note}
                onChange={(e) =>
                  setFormData({ ...formData, note: e.target.value })
                }
                placeholder="Any additional notes"
              />
            </div>
            <Button type="submit" className="w-full">
              Add Medication
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
