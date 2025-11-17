import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { useAuth } from '@/hooks/useAuth';
import { useOnboarding } from '@/hooks/useOnboarding';
import { familyService } from '@/services/familyService';
import { babyService } from '@/services/babyService';
import { useAppStore } from '@/store/appStore';
import { Baby, ChevronRight } from 'lucide-react';
import { DateInput } from '@/components/DateInput';

export default function Onboarding() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { user } = useAuth();
  const { checking } = useOnboarding();
  const { setActiveBabyId } = useAppStore();

  const [babyName, setBabyName] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [sex, setSex] = useState('');
  const [feedingStyle, setFeedingStyle] = useState('');

  if (checking) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-surface">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        </div>
      </div>
    );
  }

  if (!user) return null;

  const handleComplete = async () => {
    if (!babyName || !dateOfBirth) {
      toast.error('Please fill in required fields');
      return;
    }

    setLoading(true);

    try {
      const { baby } = await familyService.createFamilyWithBaby(
        `${babyName}'s Family`,
        babyName,
        dateOfBirth
      );

      if (sex || feedingStyle) {
        await babyService.updateBaby(baby.id, {
          sex: sex as any,
          primary_feeding_style: feedingStyle as any,
        });
      }

      setActiveBabyId(baby.id);
      localStorage.setItem('activeBabyId', baby.id);
      
      toast.success('Setup complete! Welcome to Nestling');
      navigate('/home');
    } catch (error) {
      console.error('Onboarding error:', error);
      toast.error('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
              <Baby className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <CardTitle>Add Your Baby</CardTitle>
              <CardDescription>Tell us about your little one</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="baby-name">Baby's Name *</Label>
              <Input
                id="baby-name"
                placeholder="Enter baby's name"
                value={babyName}
                onChange={(e) => setBabyName(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="dob">Date of Birth *</Label>
              <DateInput
                value={dateOfBirth}
                onChange={setDateOfBirth}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="sex">Sex (optional)</Label>
              <Select value={sex} onValueChange={setSex}>
                <SelectTrigger id="sex">
                  <SelectValue placeholder="Select sex" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="m">Male</SelectItem>
                  <SelectItem value="f">Female</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="feeding">Primary Feeding Style (optional)</Label>
              <Select value={feedingStyle} onValueChange={setFeedingStyle}>
                <SelectTrigger id="feeding">
                  <SelectValue placeholder="Select feeding style" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="breast">Breast</SelectItem>
                  <SelectItem value="bottle">Bottle</SelectItem>
                  <SelectItem value="both">Both</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <Button 
            className="w-full" 
            onClick={handleComplete}
            disabled={loading || !babyName || !dateOfBirth}
          >
            {loading ? 'Setting up...' : (
              <>
                Get Started
                <ChevronRight className="ml-2 h-4 w-4" />
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
