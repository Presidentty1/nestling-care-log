import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Baby, GrowthRecord } from '@/lib/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { Plus, TrendingUp, Ruler, Weight, Circle, Download } from 'lucide-react';
import { calculateWeightPercentile, calculateLengthPercentile, calculateHeadPercentile } from '@/lib/whoPercentiles';
import { generateDoctorReport, downloadDoctorReport } from '@/lib/doctorReportPDF';
import { validateGrowthRecord } from '@/services/validation';

export default function GrowthTracker() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [baby, setBaby] = useState<Baby | null>(null);
  const [records, setRecords] = useState<GrowthRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [showDialog, setShowDialog] = useState(false);
  const [formData, setFormData] = useState({
    weight: '',
    length: '',
    head_circumference: '',
    note: '',
    recorded_at: new Date().toISOString().split('T')[0],
  });

  useEffect(() => {
    if (!user) {
      navigate('/auth');
      return;
    }
    loadBabyAndRecords();
  }, [user, navigate]);

  const loadBabyAndRecords = async () => {
    try {
      const selectedBabyId = localStorage.getItem('selectedBabyId');
      if (!selectedBabyId) {
        navigate('/home');
        return;
      }

      const { data: babyData } = await supabase
        .from('babies')
        .select('*')
        .eq('id', selectedBabyId)
        .single();

      if (babyData) {
        setBaby(babyData);
        
        const { data: growthData } = await supabase
          .from('growth_records')
          .select('*')
          .eq('baby_id', selectedBabyId)
          .order('recorded_at', { ascending: false });

        if (growthData) {
          setRecords(growthData);
        }
      }
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load growth data');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!baby) return;

    try {
      const weight = formData.weight ? parseFloat(formData.weight) : null;
      const length = formData.length ? parseFloat(formData.length) : null;
      const headCirc = formData.head_circumference ? parseFloat(formData.head_circumference) : null;

      const birthDate = new Date(baby.date_of_birth);
      const recordDate = new Date(formData.recorded_at);
      const ageInDays = Math.floor((recordDate.getTime() - birthDate.getTime()) / (1000 * 60 * 60 * 24));

      const recordData: any = {
        baby_id: baby.id,
        recorded_at: formData.recorded_at,
        weight,
        length,
        head_circumference: headCirc,
        unit_system: 'metric',
        note: formData.note || null,
        recorded_by: user?.id,
      };

      if (weight && baby.sex && (baby.sex === 'male' || baby.sex === 'female')) {
        recordData.percentile_weight = calculateWeightPercentile(ageInDays, baby.sex, weight);
      }
      if (length && baby.sex && (baby.sex === 'male' || baby.sex === 'female')) {
        recordData.percentile_length = calculateLengthPercentile(ageInDays, baby.sex, length);
      }
      if (headCirc && baby.sex && (baby.sex === 'male' || baby.sex === 'female')) {
        recordData.percentile_head = calculateHeadPercentile(ageInDays, baby.sex, headCirc);
      }

      const validationResult = validateGrowthRecord(recordData);
      if (!validationResult.success) {
        toast.error(validationResult.error.issues[0].message);
        return;
      }

      const { error } = await supabase.from('growth_records').insert(validationResult.data);

      if (error) throw error;

      toast.success('Growth measurement saved!');
      setShowDialog(false);
      setFormData({
        weight: '',
        length: '',
        head_circumference: '',
        note: '',
        recorded_at: new Date().toISOString().split('T')[0],
      });
      loadBabyAndRecords();
    } catch (error) {
      console.error('Error saving record:', error);
      toast.error('Failed to save measurement');
    }
  };

  const handleExportPDF = async () => {
    if (!baby) return;
    
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 30);
      
      const { data: recentEvents } = await supabase
        .from('events')
        .select('*')
        .eq('baby_id', baby.id)
        .gte('start_time', startDate.toISOString());
      
      const { data: healthRecords } = await supabase
        .from('health_records')
        .select('*')
        .eq('baby_id', baby.id)
        .order('recorded_at', { ascending: false });
      
      const doc = await generateDoctorReport(
        baby,
        records,
        recentEvents || [],
        healthRecords || [],
        [startDate, new Date()]
      );
      
      downloadDoctorReport(doc, baby.name);
      toast.success('Report exported successfully!');
    } catch (error) {
      console.error('PDF export error:', error);
      toast.error('Failed to export report');
    }
  };

  const latestRecord = records[0];

  if (loading) {
    return <div className="flex items-center justify-center min-h-screen">Loading...</div>;
  }

  if (!baby) return null;

  return (
    <div className="container mx-auto p-4 pb-20 max-w-2xl">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Growth Tracker</h1>
          <p className="text-muted-foreground">{baby.name}</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" size="sm">
          <Download className="mr-2 h-4 w-4" />
          Export PDF
        </Button>
      </div>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Latest Measurements</CardTitle>
        </CardHeader>
        <CardContent>
          {latestRecord ? (
            <div className="space-y-4">
              {latestRecord.weight && (
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Weight className="w-5 h-5 text-primary" />
                    <div>
                      <p className="font-medium">Weight</p>
                      <p className="text-2xl">{latestRecord.weight} kg</p>
                    </div>
                  </div>
                  {latestRecord.percentile_weight && (
                    <span className="text-sm text-muted-foreground">
                      {latestRecord.percentile_weight}th percentile
                    </span>
                  )}
                </div>
              )}
              
              {latestRecord.length && (
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Ruler className="w-5 h-5 text-primary" />
                    <div>
                      <p className="font-medium">Length</p>
                      <p className="text-2xl">{latestRecord.length} cm</p>
                    </div>
                  </div>
                  {latestRecord.percentile_length && (
                    <span className="text-sm text-muted-foreground">
                      {latestRecord.percentile_length}th percentile
                    </span>
                  )}
                </div>
              )}
              
              {latestRecord.head_circumference && (
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Circle className="w-5 h-5 text-primary" />
                    <div>
                      <p className="font-medium">Head Circumference</p>
                      <p className="text-2xl">{latestRecord.head_circumference} cm</p>
                    </div>
                  </div>
                  {latestRecord.percentile_head && (
                    <span className="text-sm text-muted-foreground">
                      {latestRecord.percentile_head}th percentile
                    </span>
                  )}
                </div>
              )}

              <p className="text-sm text-muted-foreground">
                Last measured: {format(new Date(latestRecord.recorded_at), 'MMM dd, yyyy')}
              </p>
            </div>
          ) : (
            <p className="text-muted-foreground">No measurements yet</p>
          )}

          <Dialog open={showDialog} onOpenChange={setShowDialog}>
            <DialogTrigger asChild>
              <Button className="w-full mt-4">
                <Plus className="w-4 h-4 mr-2" />
                Log New Measurement
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>New Growth Measurement</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <Label htmlFor="recorded_at">Date</Label>
                  <Input
                    id="recorded_at"
                    type="date"
                    value={formData.recorded_at}
                    onChange={(e) => setFormData({ ...formData, recorded_at: e.target.value })}
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="weight">Weight (kg)</Label>
                  <Input
                    id="weight"
                    type="number"
                    step="0.01"
                    placeholder="5.2"
                    value={formData.weight}
                    onChange={(e) => setFormData({ ...formData, weight: e.target.value })}
                  />
                </div>

                <div>
                  <Label htmlFor="length">Length (cm)</Label>
                  <Input
                    id="length"
                    type="number"
                    step="0.1"
                    placeholder="58.5"
                    value={formData.length}
                    onChange={(e) => setFormData({ ...formData, length: e.target.value })}
                  />
                </div>

                <div>
                  <Label htmlFor="head">Head Circumference (cm)</Label>
                  <Input
                    id="head"
                    type="number"
                    step="0.1"
                    placeholder="39.0"
                    value={formData.head_circumference}
                    onChange={(e) => setFormData({ ...formData, head_circumference: e.target.value })}
                  />
                </div>

                <div>
                  <Label htmlFor="note">Notes (optional)</Label>
                  <Textarea
                    id="note"
                    placeholder="Any observations..."
                    value={formData.note}
                    onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                  />
                </div>

                <Button type="submit" className="w-full">Save Measurement</Button>
              </form>
            </DialogContent>
          </Dialog>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Measurement History</CardTitle>
        </CardHeader>
        <CardContent>
          {records.length > 0 ? (
            <div className="space-y-4">
              {records.map((record) => (
                <div key={record.id} className="border-b pb-4 last:border-0">
                  <p className="font-medium">{format(new Date(record.recorded_at), 'MMM dd, yyyy')}</p>
                  <div className="mt-2 text-sm space-y-1">
                    {record.weight && <p>Weight: {record.weight} kg</p>}
                    {record.length && <p>Length: {record.length} cm</p>}
                    {record.head_circumference && <p>Head: {record.head_circumference} cm</p>}
                    {record.note && <p className="text-muted-foreground mt-2">{record.note}</p>}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-muted-foreground text-center py-4">No measurement history</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
