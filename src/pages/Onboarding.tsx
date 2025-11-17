import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Baby, ChevronRight } from 'lucide-react';
import { DateInput } from '@/components/DateInput';

export default function Onboarding() {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { user } = useAuth();

  // Baby info
  const [babyName, setBabyName] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [sex, setSex] = useState('');
  const [feedingStyle, setFeedingStyle] = useState('');

  if (!user) {
    navigate('/auth');
    return null;
  }

  const handleComplete = async () => {
    if (!babyName || !dateOfBirth) {
      toast.error('Please fill in required fields');
      return;
    }

    setLoading(true);

    try {
      // Create family
      const { data: family, error: familyError } = await supabase
        .from('families')
        .insert({
          name: `${babyName}'s Family`,
        })
        .select()
        .single();

      if (familyError) throw familyError;

      // Add user as admin
      const { error: memberError } = await supabase
        .from('family_members')
        .insert({
          family_id: family.id,
          user_id: user.id,
          role: 'admin',
        });

      if (memberError) throw memberError;

      // Create baby
      const { error: babyError } = await supabase
        .from('babies')
        .insert({
          family_id: family.id,
          name: babyName,
          date_of_birth: dateOfBirth,
          sex: sex || null,
          primary_feeding_style: feedingStyle || null,
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        });

      if (babyError) throw babyError;

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
    <div className="min-h-screen flex items-center justify-center bg-surface p-4 pb-20">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
              <Baby className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <CardTitle>Welcome to Nestling</CardTitle>
              <CardDescription>Let's set up your baby's profile</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {step === 1 && (
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Baby Information</h3>
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
                  maxDate={new Date()}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sex">Sex (optional)</Label>
                <Select value={sex} onValueChange={setSex}>
                  <SelectTrigger id="sex">
                    <SelectValue placeholder="Select..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                    <SelectItem value="prefer_not_to_say">Prefer not to say</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="feeding">Primary Feeding Style (optional)</Label>
                <Select value={feedingStyle} onValueChange={setFeedingStyle}>
                  <SelectTrigger id="feeding">
                    <SelectValue placeholder="Select..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="breast">Breastfeeding</SelectItem>
                    <SelectItem value="formula">Formula</SelectItem>
                    <SelectItem value="combo">Combination</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button 
                onClick={handleComplete} 
                className="w-full"
                disabled={loading || !babyName || !dateOfBirth}
              >
                {loading ? 'Setting up...' : 'Complete Setup'}
                <ChevronRight className="ml-2 h-4 w-4" />
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
