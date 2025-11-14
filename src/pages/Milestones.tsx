import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby, Milestone } from '@/lib/types';
import { milestoneCategories } from '@/lib/milestoneCategories';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Plus, Calendar, Camera } from 'lucide-react';
import { format, differenceInMonths } from 'date-fns';
import { MilestoneModal } from '@/components/MilestoneModal';

export default function Milestones() {
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMilestone, setEditingMilestone] = useState<Milestone | null>(null);
  const [activeCategory, setActiveCategory] = useState('all');

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data, error } = await supabase.from('babies').select('*');
      if (error) throw error;
      if (data && data.length > 0 && !selectedBaby) {
        setSelectedBaby(data[0]);
      }
      return data as Baby[];
    },
  });

  const { data: milestones = [] } = useQuery({
    queryKey: ['milestones', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return [];
      const { data, error } = await supabase
        .from('milestones')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .order('achieved_date', { ascending: false });
      if (error) throw error;
      return data as Milestone[];
    },
    enabled: !!selectedBaby,
  });

  const babyAgeMonths = selectedBaby
    ? differenceInMonths(new Date(), new Date(selectedBaby.date_of_birth))
    : 0;

  const getUpcomingMilestones = () => {
    if (!selectedBaby) return [];
    const achievedTitles = new Set(milestones.map(m => m.title));
    
    return milestoneCategories
      .flatMap(cat => 
        cat.milestones.map(m => ({ ...m, category: cat }))
      )
      .filter(m => 
        !achievedTitles.has(m.title) &&
        babyAgeMonths >= m.ageRangeMonths[0] - 1 &&
        babyAgeMonths <= m.ageRangeMonths[1] + 2
      )
      .sort((a, b) => a.typicalAgeMonths - b.typicalAgeMonths);
  };

  const filteredMilestones = activeCategory === 'all'
    ? milestones
    : milestones.filter(m => m.milestone_type === activeCategory);

  const upcomingMilestones = getUpcomingMilestones();

  if (!selectedBaby) {
    return (
      <div className="container max-w-4xl mx-auto p-4">
        <p className="text-muted-foreground text-center py-8">
          No babies found. Add a baby to start tracking milestones.
        </p>
      </div>
    );
  }

  return (
    <div className="container max-w-4xl mx-auto p-4 pb-20">
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Milestones</h1>
        <p className="text-muted-foreground">
          {selectedBaby.name} • {babyAgeMonths} months old
        </p>
      </div>

      <Tabs value={activeCategory} onValueChange={setActiveCategory} className="mb-6">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="all">All</TabsTrigger>
          {milestoneCategories.slice(0, 5).map(cat => (
            <TabsTrigger key={cat.type} value={cat.type}>
              {cat.icon}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      {upcomingMilestones.length > 0 && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="text-lg">Upcoming Milestones</CardTitle>
            <p className="text-sm text-muted-foreground">
              Based on {selectedBaby.name}'s age
            </p>
          </CardHeader>
          <CardContent className="space-y-3">
            {upcomingMilestones.slice(0, 3).map((milestone, idx) => (
              <div key={idx} className="flex items-start justify-between p-3 bg-muted/50 rounded-lg">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-lg">{milestone.category.icon}</span>
                    <h4 className="font-medium">{milestone.title}</h4>
                  </div>
                  <p className="text-sm text-muted-foreground mb-1">
                    {milestone.description}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Typical: {milestone.typicalAgeMonths} months
                  </p>
                </div>
                <Button
                  size="sm"
                  onClick={() => {
                    setEditingMilestone({
                      id: '',
                      baby_id: selectedBaby.id,
                      milestone_type: milestone.category.type,
                      title: milestone.title,
                      description: milestone.description,
                      achieved_date: format(new Date(), 'yyyy-MM-dd'),
                      created_at: new Date().toISOString(),
                      updated_at: new Date().toISOString(),
                    } as Milestone);
                    setIsModalOpen(true);
                  }}
                >
                  Mark Achieved
                </Button>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card className="mb-6">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Recently Achieved ✨</CardTitle>
            <Button onClick={() => {
              setEditingMilestone(null);
              setIsModalOpen(true);
            }}>
              <Plus className="h-4 w-4 mr-2" />
              Add Custom
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {filteredMilestones.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">
              No milestones recorded yet. Start tracking your baby's achievements!
            </p>
          ) : (
            <div className="space-y-4">
              {filteredMilestones.map(milestone => {
                const category = milestoneCategories.find(c => c.type === milestone.milestone_type);
                return (
                  <div
                    key={milestone.id}
                    className="flex items-start gap-4 p-4 bg-muted/50 rounded-lg cursor-pointer hover:bg-muted transition-colors"
                    onClick={() => {
                      setEditingMilestone(milestone);
                      setIsModalOpen(true);
                    }}
                  >
                    <div className="text-2xl">{category?.icon || '⭐'}</div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h4 className="font-medium">{milestone.title}</h4>
                        <Badge variant="secondary">
                          <Calendar className="h-3 w-3 mr-1" />
                          {format(new Date(milestone.achieved_date), 'MMM d, yyyy')}
                        </Badge>
                      </div>
                      {milestone.description && (
                        <p className="text-sm text-muted-foreground mb-2">
                          {milestone.description}
                        </p>
                      )}
                      {milestone.note && (
                        <p className="text-sm italic">"{milestone.note}"</p>
                      )}
                      {milestone.photo_url && (
                        <div className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                          <Camera className="h-3 w-3" />
                          Photo attached
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      <MilestoneModal
        open={isModalOpen}
        onOpenChange={setIsModalOpen}
        baby={selectedBaby}
        milestone={editingMilestone}
        onSaved={() => setIsModalOpen(false)}
      />
    </div>
  );
}
