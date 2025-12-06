import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { sleepTrainingService } from '@/services/sleepTrainingService';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { ArrowLeft, Moon } from 'lucide-react';

const sleepMethods = [
  {
    name: 'Ferber Method',
    description: 'Graduated extinction with timed check-ins (3, 5, 10, 15 minutes)',
    intervals: [3, 5, 10, 15, 20],
  },
  {
    name: 'Chair Method',
    description: 'Gradually move chair further from crib each night',
    intervals: null,
  },
  {
    name: 'Pick Up / Put Down',
    description: 'Pick up when crying, put down when calm, repeat as needed',
    intervals: null,
  },
  {
    name: 'Cry It Out',
    description: 'Allow baby to self-soothe without intervention',
    intervals: null,
  },
];

export default function NewSleepTrainingSession() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedMethod, setSelectedMethod] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    start_date: new Date().toISOString().split('T')[0],
    target_bedtime: '19:00',
    target_wake_time: '07:00',
    notes: '',
  });

  const createSessionMutation = useMutation({
    mutationFn: async () => {
      if (!selectedMethod) throw new Error('Please select a method');

      const selectedBabyId = localStorage.getItem('selectedBabyId');
      if (!selectedBabyId) throw new Error('No baby selected');

      const method = sleepMethods.find(m => m.name === selectedMethod);
      if (!method) throw new Error('Invalid method');

      await sleepTrainingService.createSession({
        baby_id: selectedBabyId,
        method: method.name,
        start_date: formData.start_date,
        target_bedtime: formData.target_bedtime,
        target_wake_time: formData.target_wake_time,
        check_intervals: method.intervals,
        notes: formData.notes,
        status: 'active',
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sleep-training-sessions'] });
      toast({ title: 'Sleep training session started!' });
      navigate('/sleep-training');
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to create session',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center gap-4">
            <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">New Sleep Training</h1>
              <p className="text-sm text-muted-foreground">Choose a method to get started</p>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto p-4 max-w-2xl space-y-6">
        <MedicalDisclaimer variant="sleep" />

        <div className="space-y-3">
          <Label className="text-lg font-semibold">Select Method</Label>
          {sleepMethods.map((method) => (
            <Card
              key={method.name}
              className={`cursor-pointer transition-colors ${
                selectedMethod === method.name ? 'border-primary bg-primary/5' : ''
              }`}
              onClick={() => setSelectedMethod(method.name)}
            >
              <CardHeader>
                <div className="flex items-start gap-3">
                  <Moon className="h-6 w-6 mt-1 flex-shrink-0" />
                  <div>
                    <CardTitle className="text-lg">{method.name}</CardTitle>
                    <CardDescription className="mt-1">{method.description}</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          ))}
        </div>

        {selectedMethod && (
          <Card className="p-6 space-y-4">
            <h3 className="font-semibold">Session Details</h3>
            
            <div>
              <Label>Start Date</Label>
              <Input
                type="date"
                value={formData.start_date}
                onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Target Bedtime</Label>
                <Input
                  type="time"
                  value={formData.target_bedtime}
                  onChange={(e) => setFormData({ ...formData, target_bedtime: e.target.value })}
                />
              </div>
              <div>
                <Label>Target Wake Time</Label>
                <Input
                  type="time"
                  value={formData.target_wake_time}
                  onChange={(e) => setFormData({ ...formData, target_wake_time: e.target.value })}
                />
              </div>
            </div>

            <div>
              <Label>Notes (Optional)</Label>
              <Textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                placeholder="Any specific goals or concerns..."
                rows={3}
              />
            </div>

            <Button
              onClick={() => createSessionMutation.mutate()}
              disabled={createSessionMutation.isPending}
              className="w-full"
              size="lg"
            >
              Start Sleep Training
            </Button>
          </Card>
        )}
      </div>
    </div>
  );
}
