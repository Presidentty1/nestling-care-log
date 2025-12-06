import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import type { Baby, HealthRecord, HealthRecordType } from '@/lib/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { MedicationTracker } from '@/components/MedicationTracker';
import { VaccineScheduleView } from '@/components/VaccineScheduleView';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { Plus, Thermometer, Stethoscope, Syringe, AlertCircle } from 'lucide-react';
import { validateHealthRecord } from '@/services/validation';
import { babyService } from '@/services/babyService';
import { healthRecordsService } from '@/services/healthRecordsService';
import { useAppStore } from '@/store/appStore';

export default function HealthRecords() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { activeBabyId } = useAppStore();
  const [baby, setBaby] = useState<Baby | null>(null);
  const [records, setRecords] = useState<HealthRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [showDialog, setShowDialog] = useState(false);
  const [filterType, setFilterType] = useState<HealthRecordType | 'all'>('all');
  const [formData, setFormData] = useState({
    record_type: 'temperature' as HealthRecordType,
    title: '',
    recorded_at: new Date().toISOString().slice(0, 16),
    temperature: '',
    vaccine_name: '',
    vaccine_dose: '',
    doctor_name: '',
    diagnosis: '',
    treatment: '',
    note: '',
  });

  useEffect(() => {
    if (!user) {
      navigate('/auth');
      return;
    }
    loadBabyAndRecords();
  }, [user, navigate, activeBabyId]);

  const loadBabyAndRecords = async () => {
    try {
      const babyId = activeBabyId || localStorage.getItem('selectedBabyId') || localStorage.getItem('activeBabyId');
      if (!babyId) {
        navigate('/home');
        return;
      }

      const babyData = await babyService.getBaby(babyId);
      if (babyData) {
        setBaby(babyData);
        const healthData = await healthRecordsService.getHealthRecords(babyId);
        setRecords(healthData);
      }
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load health records');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!baby) return;

    try {
      const recordData: any = {
        baby_id: baby.id,
        record_type: formData.record_type,
        title: formData.title,
        recorded_at: formData.recorded_at,
        note: formData.note || null,
      };

      if (formData.record_type === 'temperature' && formData.temperature) {
        recordData.temperature = parseFloat(formData.temperature);
      }
      if (formData.record_type === 'vaccine') {
        recordData.vaccine_name = formData.vaccine_name || null;
        recordData.vaccine_dose = formData.vaccine_dose || null;
      }
      if (formData.record_type === 'doctor_visit') {
        recordData.doctor_name = formData.doctor_name || null;
        recordData.diagnosis = formData.diagnosis || null;
        recordData.treatment = formData.treatment || null;
      }

      const validationResult = validateHealthRecord(recordData);
      if (!validationResult.success) {
        toast.error(validationResult.error.issues[0].message);
        return;
      }

      await healthRecordsService.createHealthRecord(validationResult.data);

      toast.success('Health record saved!');
      setShowDialog(false);
      resetForm();
      loadBabyAndRecords();
    } catch (error) {
      console.error('Error saving record:', error);
      toast.error('Failed to save health record');
    }
  };

  const resetForm = () => {
    setFormData({
      record_type: 'temperature',
      title: '',
      recorded_at: new Date().toISOString().slice(0, 16),
      temperature: '',
      vaccine_name: '',
      vaccine_dose: '',
      doctor_name: '',
      diagnosis: '',
      treatment: '',
      note: '',
    });
  };

  const getRecordIcon = (type: HealthRecordType) => {
    switch (type) {
      case 'temperature': return <Thermometer className="w-5 h-5" />;
      case 'doctor_visit': return <Stethoscope className="w-5 h-5" />;
      case 'vaccine': return <Syringe className="w-5 h-5" />;
      case 'allergy': return <AlertCircle className="w-5 h-5" />;
      default: return <Stethoscope className="w-5 h-5" />;
    }
  };

  const filteredRecords = filterType === 'all' 
    ? records 
    : records.filter(r => r.record_type === filterType);

  if (loading) {
    return <div className="flex items-center justify-center min-h-screen">Loading...</div>;
  }

  if (!baby) return null;

  return (
    <div className="container mx-auto p-4 pb-20 max-w-2xl">
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Health Records</h1>
        <p className="text-muted-foreground">{baby.name}</p>
      </div>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          <Dialog open={showDialog} onOpenChange={setShowDialog}>
            <DialogTrigger asChild>
              <Button onClick={() => setFormData({ ...formData, record_type: 'temperature' })}>
                <Thermometer className="w-4 h-4 mr-2" />
                Log Temperature
              </Button>
            </DialogTrigger>
          </Dialog>

          <Dialog open={showDialog} onOpenChange={setShowDialog}>
            <DialogTrigger asChild>
              <Button variant="outline" onClick={() => setFormData({ ...formData, record_type: 'doctor_visit' })}>
                <Stethoscope className="w-4 h-4 mr-2" />
                Doctor Visit
              </Button>
            </DialogTrigger>
          </Dialog>

          <Dialog open={showDialog} onOpenChange={setShowDialog}>
            <DialogTrigger asChild>
              <Button variant="outline" onClick={() => setFormData({ ...formData, record_type: 'vaccine' })}>
                <Syringe className="w-4 h-4 mr-2" />
                Record Vaccine
              </Button>
            </DialogTrigger>
            <DialogContent className="max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>New Health Record</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <Label htmlFor="type">Record Type</Label>
                  <Select 
                    value={formData.record_type} 
                    onValueChange={(value: HealthRecordType) => setFormData({ ...formData, record_type: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="temperature">Temperature</SelectItem>
                      <SelectItem value="doctor_visit">Doctor Visit</SelectItem>
                      <SelectItem value="vaccine">Vaccine</SelectItem>
                      <SelectItem value="allergy">Allergy</SelectItem>
                      <SelectItem value="illness">Illness</SelectItem>
                      <SelectItem value="other">Other</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="title">Title</Label>
                  <Input
                    id="title"
                    placeholder="Brief description"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="recorded_at">Date & Time</Label>
                  <Input
                    id="recorded_at"
                    type="datetime-local"
                    value={formData.recorded_at}
                    onChange={(e) => setFormData({ ...formData, recorded_at: e.target.value })}
                    required
                  />
                </div>

                {formData.record_type === 'temperature' && (
                  <div>
                    <Label htmlFor="temperature">Temperature (°C)</Label>
                    <Input
                      id="temperature"
                      type="number"
                      step="0.1"
                      placeholder="37.5"
                      value={formData.temperature}
                      onChange={(e) => setFormData({ ...formData, temperature: e.target.value })}
                    />
                  </div>
                )}

                {formData.record_type === 'vaccine' && (
                  <>
                    <div>
                      <Label htmlFor="vaccine_name">Vaccine Name</Label>
                      <Input
                        id="vaccine_name"
                        placeholder="DTaP"
                        value={formData.vaccine_name}
                        onChange={(e) => setFormData({ ...formData, vaccine_name: e.target.value })}
                      />
                    </div>
                    <div>
                      <Label htmlFor="vaccine_dose">Dose</Label>
                      <Input
                        id="vaccine_dose"
                        placeholder="Dose 1"
                        value={formData.vaccine_dose}
                        onChange={(e) => setFormData({ ...formData, vaccine_dose: e.target.value })}
                      />
                    </div>
                  </>
                )}

                {formData.record_type === 'doctor_visit' && (
                  <>
                    <div>
                      <Label htmlFor="doctor_name">Doctor Name</Label>
                      <Input
                        id="doctor_name"
                        placeholder="Dr. Smith"
                        value={formData.doctor_name}
                        onChange={(e) => setFormData({ ...formData, doctor_name: e.target.value })}
                      />
                    </div>
                    <div>
                      <Label htmlFor="diagnosis">Diagnosis</Label>
                      <Textarea
                        id="diagnosis"
                        placeholder="Diagnosis or reason for visit"
                        value={formData.diagnosis}
                        onChange={(e) => setFormData({ ...formData, diagnosis: e.target.value })}
                      />
                    </div>
                    <div>
                      <Label htmlFor="treatment">Treatment</Label>
                      <Textarea
                        id="treatment"
                        placeholder="Treatment or recommendations"
                        value={formData.treatment}
                        onChange={(e) => setFormData({ ...formData, treatment: e.target.value })}
                      />
                    </div>
                  </>
                )}

                <div>
                  <Label htmlFor="note">Notes</Label>
                  <Textarea
                    id="note"
                    placeholder="Additional notes..."
                    value={formData.note}
                    onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                  />
                </div>

                <Button type="submit" className="w-full">Save Record</Button>
              </form>
            </DialogContent>
          </Dialog>
        </CardContent>
      </Card>

      {baby && <MedicationTracker baby={baby} />}

      {baby && (
        <VaccineScheduleView 
          baby={baby} 
          completedVaccines={records
            .filter(r => r.record_type === 'vaccine' && r.vaccine_name)
            .map(r => r.vaccine_name!)
          } 
        />
      )}

      <Tabs value={filterType} onValueChange={(v) => setFilterType(v as any)}>
        <TabsList className="w-full">
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="temperature">Temp</TabsTrigger>
          <TabsTrigger value="doctor_visit">Visits</TabsTrigger>
          <TabsTrigger value="vaccine">Vaccines</TabsTrigger>
        </TabsList>

        <TabsContent value={filterType} className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Recent Records</CardTitle>
            </CardHeader>
            <CardContent>
              {filteredRecords.length > 0 ? (
                <div className="space-y-4">
                  {filteredRecords.map((record) => (
                    <div key={record.id} className="border-b pb-4 last:border-0">
                      <div className="flex items-start gap-3">
                        <div className="text-primary mt-1">
                          {getRecordIcon(record.record_type)}
                        </div>
                        <div className="flex-1">
                          <p className="font-medium">{record.title}</p>
                          <p className="text-sm text-muted-foreground">
                            {format(new Date(record.recorded_at), 'MMM dd, yyyy HH:mm')}
                          </p>
                          {record.temperature && (
                            <p className="text-sm mt-1">{record.temperature}°C</p>
                          )}
                          {record.vaccine_name && (
                            <p className="text-sm mt-1">{record.vaccine_name} - {record.vaccine_dose}</p>
                          )}
                          {record.note && (
                            <p className="text-sm mt-2 text-muted-foreground">{record.note}</p>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-muted-foreground text-center py-4">No records found</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
