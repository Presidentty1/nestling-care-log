import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { BabySwitcher } from '@/components/BabySwitcher';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Progress } from '@/components/ui/progress';
import { useToast } from '@/hooks/use-toast';
import { Target, Plus, CheckCircle2, TrendingUp } from 'lucide-react';
import { Baby } from '@/lib/types';
import { format } from 'date-fns';

export default function Goals() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);
  const [newGoal, setNewGoal] = useState({
    goal_type: 'feeding',
    title: '',
    target_value: '',
    target_unit: '',
    target_date: '',
    notes: '',
  });

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return [];
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id);
      if (!familyMembers || familyMembers.length === 0) return [];
      const { data } = await supabase
        .from('babies')
        .select('*')
        .eq('family_id', familyMembers[0].family_id);
      return data || [];
    },
  });

  const { data: goals } = useQuery({
    queryKey: ['goals', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      const { data } = await supabase
        .from('goals')
        .select('*')
        .eq('baby_id', selectedBabyId)
        .order('created_at', { ascending: false });
      return data || [];
    },
    enabled: !!selectedBabyId,
  });

  const createGoalMutation = useMutation({
    mutationFn: async () => {
      if (!selectedBabyId) return;

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error } = await supabase.from('goals').insert({
        baby_id: selectedBabyId,
        goal_type: newGoal.goal_type,
        title: newGoal.title,
        target_value: parseFloat(newGoal.target_value) || null,
        target_unit: newGoal.target_unit || null,
        target_date: newGoal.target_date || null,
        notes: newGoal.notes || null,
        created_by: user.id,
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['goals'] });
      toast({ title: 'Goal created!' });
      setIsDialogOpen(false);
      setNewGoal({
        goal_type: 'feeding',
        title: '',
        target_value: '',
        target_unit: '',
        target_date: '',
        notes: '',
      });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to create goal',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const activeGoals = goals?.filter(g => !g.is_achieved) || [];
  const achievedGoals = goals?.filter(g => g.is_achieved) || [];

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Goals & Milestones</h1>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsSwitcherOpen(true)}
            className="flex items-center gap-2"
          >
            <span>👶</span>
            <span>{babies?.find(b => b.id === selectedBabyId)?.name || 'Select Baby'}</span>
          </Button>
        </div>

        {selectedBabyId && (
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="w-4 h-4 mr-2" />
                New Goal
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Create New Goal</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div>
                  <Label>Goal Type</Label>
                  <Select
                    value={newGoal.goal_type}
                    onValueChange={(value) => setNewGoal({ ...newGoal, goal_type: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="feeding">Feeding</SelectItem>
                      <SelectItem value="sleep">Sleep</SelectItem>
                      <SelectItem value="tummy_time">Tummy Time</SelectItem>
                      <SelectItem value="development">Development</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Title</Label>
                  <Input
                    value={newGoal.title}
                    onChange={(e) => setNewGoal({ ...newGoal, title: e.target.value })}
                    placeholder="e.g., Sleep through the night"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Target Value</Label>
                    <Input
                      type="number"
                      value={newGoal.target_value}
                      onChange={(e) => setNewGoal({ ...newGoal, target_value: e.target.value })}
                      placeholder="e.g., 12"
                    />
                  </div>
                  <div>
                    <Label>Unit</Label>
                    <Input
                      value={newGoal.target_unit}
                      onChange={(e) => setNewGoal({ ...newGoal, target_unit: e.target.value })}
                      placeholder="e.g., hours"
                    />
                  </div>
                </div>

                <div>
                  <Label>Target Date</Label>
                  <Input
                    type="date"
                    value={newGoal.target_date}
                    onChange={(e) => setNewGoal({ ...newGoal, target_date: e.target.value })}
                  />
                </div>

                <div>
                  <Label>Notes</Label>
                  <Textarea
                    value={newGoal.notes}
                    onChange={(e) => setNewGoal({ ...newGoal, notes: e.target.value })}
                    placeholder="Additional details..."
                  />
                </div>

                <Button
                  className="w-full"
                  onClick={() => createGoalMutation.mutate()}
                  disabled={createGoalMutation.isPending || !newGoal.title}
                >
                  Create Goal
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        )}

        {selectedBabyId && (
          <>
            <div className="space-y-4">
              <h2 className="text-xl font-semibold flex items-center gap-2">
                <Target className="w-5 h-5" />
                Active Goals
              </h2>

              {activeGoals.length > 0 ? (
                activeGoals.map((goal) => (
                  <Card key={goal.id} className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <h3 className="font-semibold text-lg">{goal.title}</h3>
                        <p className="text-sm text-muted-foreground capitalize">
                          {goal.goal_type.replace('_', ' ')}
                        </p>
                      </div>
                      {goal.target_value && (
                        <div className="text-right">
                          <p className="text-2xl font-bold">
                            {goal.current_progress}/{goal.target_value}
                          </p>
                          <p className="text-xs text-muted-foreground">{goal.target_unit}</p>
                        </div>
                      )}
                    </div>

                    {goal.target_value && (
                      <Progress
                        value={(goal.current_progress / goal.target_value) * 100}
                        className="mb-4"
                      />
                    )}

                    {goal.target_date && (
                      <p className="text-sm text-muted-foreground">
                        Target: {format(new Date(goal.target_date), 'MMM d, yyyy')}
                      </p>
                    )}

                    {goal.notes && (
                      <p className="text-sm text-muted-foreground mt-2">{goal.notes}</p>
                    )}
                  </Card>
                ))
              ) : (
                <Card className="p-6 text-center text-muted-foreground">
                  <TrendingUp className="w-12 h-12 mx-auto mb-2 opacity-50" />
                  <p>No active goals yet. Create one to start tracking progress!</p>
                </Card>
              )}
            </div>

            {achievedGoals.length > 0 && (
              <div className="space-y-4">
                <h2 className="text-xl font-semibold flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-green-600" />
                  Achieved Goals
                </h2>

                {achievedGoals.map((goal) => (
                  <Card key={goal.id} className="p-6 opacity-75">
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="font-semibold">{goal.title}</h3>
                        <p className="text-sm text-muted-foreground">
                          Achieved {format(new Date(goal.achieved_at), 'MMM d, yyyy')}
                        </p>
                      </div>
                      <CheckCircle2 className="w-6 h-6 text-green-600" />
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}