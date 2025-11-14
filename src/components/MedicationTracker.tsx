import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Medication, Baby } from '@/lib/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Plus, Pill, Clock } from 'lucide-react';
import { format, isAfter } from 'date-fns';
import { toast } from 'sonner';
import { notificationManager } from '@/lib/notificationManager';

interface MedicationTrackerProps {
  baby: Baby;
}

export function MedicationTracker({ baby }: MedicationTrackerProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMed, setEditingMed] = useState<Medication | null>(null);
  const queryClient = useQueryClient();

  const { data: medications = [] } = useQuery({
    queryKey: ['medications', baby.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('medications')
        .select('*')
        .eq('baby_id', baby.id)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data as Medication[];
    },
  });

  const activeMedications = medications.filter(
    m => !m.end_date || isAfter(new Date(m.end_date), new Date())
  );

  const markAsGivenMutation = useMutation({
    mutationFn: async (medication: Medication) => {
      // Create an event for this medication dose
      const { error } = await supabase.from('events').insert({
        baby_id: baby.id,
        family_id: baby.family_id,
        type: 'medication',
        subtype: medication.name,
        start_time: new Date().toISOString(),
        note: `${medication.dose || 'Dose'} given`,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success('Medication logged');
      queryClient.invalidateQueries({ queryKey: ['events'] });
    },
  });

  const stopMedicationMutation = useMutation({
    mutationFn: async (medicationId: string) => {
      const { error } = await supabase
        .from('medications')
        .update({ end_date: format(new Date(), 'yyyy-MM-dd') })
        .eq('id', medicationId);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success('Medication stopped');
      queryClient.invalidateQueries({ queryKey: ['medications'] });
    },
  });

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Pill className="h-5 w-5" />
              Active Medications
            </CardTitle>
            <Button
              size="sm"
              onClick={() => {
                setEditingMed(null);
                setIsModalOpen(true);
              }}
            >
              <Plus className="h-4 w-4 mr-2" />
              Add
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {activeMedications.length === 0 ? (
            <p className="text-muted-foreground text-center py-4">
              No active medications
            </p>
          ) : (
            <div className="space-y-3">
              {activeMedications.map(med => (
                <div key={med.id} className="p-3 bg-muted/50 rounded-lg">
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <h4 className="font-medium">{med.name}</h4>
                      {med.dose && (
                        <p className="text-sm text-muted-foreground">{med.dose}</p>
                      )}
                      {med.frequency && (
                        <p className="text-xs text-muted-foreground">{med.frequency}</p>
                      )}
                    </div>
                    {med.reminder_enabled && (
                      <Badge variant="outline">
                        <Clock className="h-3 w-3 mr-1" />
                        Reminders on
                      </Badge>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      onClick={() => markAsGivenMutation.mutate(med)}
                      disabled={markAsGivenMutation.isPending}
                    >
                      Mark as Given
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditingMed(med);
                        setIsModalOpen(true);
                      }}
                    >
                      Edit
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => stopMedicationMutation.mutate(med.id)}
                    >
                      Stop
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <MedicationModal
        open={isModalOpen}
        onOpenChange={setIsModalOpen}
        baby={baby}
        medication={editingMed}
      />
    </>
  );
}

function MedicationModal({
  open,
  onOpenChange,
  baby,
  medication,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  baby: Baby;
  medication: Medication | null;
}) {
  const [name, setName] = useState(medication?.name || '');
  const [dose, setDose] = useState(medication?.dose || '');
  const [frequency, setFrequency] = useState(medication?.frequency || '');
  const [startDate, setStartDate] = useState(
    medication?.start_date || format(new Date(), 'yyyy-MM-dd')
  );
  const [note, setNote] = useState(medication?.note || '');
  const [reminderEnabled, setReminderEnabled] = useState(medication?.reminder_enabled || false);
  const queryClient = useQueryClient();

  const saveMutation = useMutation({
    mutationFn: async () => {
      const data = {
        baby_id: baby.id,
        name,
        dose: dose || null,
        frequency: frequency || null,
        start_date: startDate,
        note: note || null,
        reminder_enabled: reminderEnabled,
      };

      if (medication?.id) {
        const { error } = await supabase
          .from('medications')
          .update(data)
          .eq('id', medication.id);
        if (error) throw error;
      } else {
        const { data: newMed, error } = await supabase
          .from('medications')
          .insert(data)
          .select()
          .single();
        if (error) throw error;

        if (reminderEnabled && newMed) {
          await notificationManager.scheduleMedicationReminder(newMed as Medication);
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['medications'] });
      toast.success(medication ? 'Medication updated' : 'Medication added');
      onOpenChange(false);
    },
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {medication ? 'Edit Medication' : 'Add Medication'}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Medication Name</Label>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Tylenol"
            />
          </div>

          <div className="space-y-2">
            <Label>Dose (optional)</Label>
            <Input
              value={dose}
              onChange={(e) => setDose(e.target.value)}
              placeholder="e.g., 2.5ml"
            />
          </div>

          <div className="space-y-2">
            <Label>Frequency (optional)</Label>
            <Input
              value={frequency}
              onChange={(e) => setFrequency(e.target.value)}
              placeholder="e.g., Every 6 hours"
            />
          </div>

          <div className="space-y-2">
            <Label>Start Date</Label>
            <Input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label>Notes (optional)</Label>
            <Textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Any additional information..."
              rows={2}
            />
          </div>

          <div className="flex items-center justify-between">
            <Label>Enable Reminders</Label>
            <Switch checked={reminderEnabled} onCheckedChange={setReminderEnabled} />
          </div>

          <Button
            onClick={() => saveMutation.mutate()}
            disabled={!name || saveMutation.isPending}
            className="w-full"
          >
            {saveMutation.isPending ? 'Saving...' : 'Save Medication'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
