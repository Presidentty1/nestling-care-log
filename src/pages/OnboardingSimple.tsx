import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Toggle } from '@/components/ui/toggle';
import { CalendarIcon, Baby, Heart, Sparkles } from 'lucide-react';
import { format } from 'date-fns';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import { detectTimeZone, parseLocalDate } from '@/services/time';
import { logger } from '@/lib/logger';
import { sanitizeBabyName } from '@/lib/sanitization';
import { validateBaby } from '@/services/validation';
import { toast } from 'sonner';
import { OnboardingStepView } from '@/components/onboarding/OnboardingStepView';

export default function OnboardingSimple() {
  const navigate = useNavigate();
  const { setActiveBabyId } = useAppStore();
  const [step, setStep] = useState(1);
  const [name, setName] = useState('');
  const [dob, setDob] = useState<Date>();
  const [dobInput, setDobInput] = useState('');
  const [sex, setSex] = useState<'m' | 'f' | 'other'>('m');
  const [timeZone, setTimeZone] = useState(detectTimeZone());
  const [units, setUnits] = useState<'metric' | 'imperial'>('imperial');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isCreating, setIsCreating] = useState(false);

  const handleStep1Next = () => {
    const newErrors: Record<string, string> = {};
    
    if (!name.trim()) {
      newErrors.name = 'Name is required';
    } else if (name.length > 40) {
      newErrors.name = 'Name must be 40 characters or less';
    }
    
    if (!dob) {
      newErrors.dob = 'Date of birth is required';
    } else if (dob > new Date()) {
      newErrors.dob = 'Date of birth cannot be in the future';
    }
    
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }
    
    setErrors({});
    setStep(2);
  };

  const handleCreateBaby = async () => {
    if (!dob) return;
    
    setIsCreating(true);
    try {
      const babyData = {
        name: name.trim(),
        dobISO: format(dob, 'yyyy-MM-dd'),
        sex,
        timeZone,
        units,
      };
      
      const validation = validateBaby(babyData);
      if (!validation.success) {
        toast.error('Please check your input');
        setIsCreating(false);
        return;
      }
      
      const sanitizedName = sanitizeBabyName(babyData.name);
      const baby = await dataService.addBaby({ ...babyData, name: sanitizedName });
      setActiveBabyId(baby.id);
      toast.success(`Welcome, ${baby.name}! Log what you can, when you can. We'll work with whatever you provide.`);
      navigate('/home');
    } catch (error) {
      logger.error('Failed to create baby', error, 'Onboarding');
      toast.error(
        'Could not save baby locally. Your data never leaves your device. Please try again.',
        { duration: 5000 }
      );
      setIsCreating(false);
    }
  };

  const handleCreateDemo = async () => {
    setIsCreating(true);
    try {
      const baby = await dataService.addBaby({
        name: 'Baby',
        dobISO: format(new Date(), 'yyyy-MM-dd'),
        timeZone: detectTimeZone(),
        units: 'imperial',
      });
      setActiveBabyId(baby.id);
      toast.success('Demo profile created!');
      navigate('/home');
    } catch (error) {
      logger.error('Failed to create demo', error, 'Onboarding');
      toast.error('Failed to create demo profile');
    } finally {
      setIsCreating(false);
    }
  };

  if (step === 1) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader>
            <div className="flex items-center gap-2 mb-2">
              <Baby className="h-6 w-6 text-primary" />
              <CardTitle>Welcome to Nuzzle</CardTitle>
            </div>
            <CardDescription>Let's set up your baby's profile</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Baby's Name</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(sanitizeBabyName(e.target.value))}
                placeholder="Enter name"
                maxLength={40}
                aria-invalid={!!errors.name}
                aria-describedby={errors.name ? 'name-error' : undefined}
              />
              {errors.name && (
                <p id="name-error" className="text-sm text-destructive">
                  {errors.name}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="dob">Date of Birth</Label>
              <div className="flex gap-2">
                <Input
                  id="dob"
                  value={dobInput}
                  onChange={(e) => setDobInput(e.target.value)}
                  placeholder="MM/DD/YYYY"
                  onBlur={() => {
                    const parsed = parseLocalDate(dobInput);
                    if (parsed) {
                      setDob(parsed);
                    }
                  }}
                />
                <Popover>
                  <PopoverTrigger asChild>
                    <Button variant="outline" size="icon">
                      <CalendarIcon className="h-4 w-4" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0">
                    <Calendar
                      mode="single"
                      selected={dob}
                      onSelect={(date) => {
                        setDob(date);
                        if (date) {
                          setDobInput(format(date, 'MM/dd/yyyy'));
                        }
                      }}
                      disabled={(date) => date > new Date()}
                    />
                  </PopoverContent>
                </Popover>
                <Button
                  variant="outline"
                  onClick={() => {
                    const today = new Date();
                    setDob(today);
                    setDobInput(format(today, 'MM/dd/yyyy'));
                  }}
                >
                  Today
                </Button>
              </div>
              {errors.dob && (
                <p id="dob-error" className="text-sm text-destructive">
                  {errors.dob}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label>Sex</Label>
              <RadioGroup value={sex} onValueChange={(v) => setSex(v as any)}>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="m" id="male" />
                  <Label htmlFor="male">Male</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="f" id="female" />
                  <Label htmlFor="female">Female</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="other" id="other" />
                  <Label htmlFor="other">Other</Label>
                </div>
              </RadioGroup>
            </div>

            <div className="flex gap-2">
              <Button onClick={handleStep1Next} className="flex-1">
                Next
              </Button>
              <Button onClick={handleCreateDemo} variant="outline">
                Demo
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Preferences</CardTitle>
          <CardDescription>Choose your measurement units</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-2">
            <Label>Measurement Units</Label>
            <div className="flex gap-2">
              <Toggle
                pressed={units === 'metric'}
                onPressedChange={() => setUnits('metric')}
                className="flex-1"
              >
                Metric (ml, cm, kg)
              </Toggle>
              <Toggle
                pressed={units === 'imperial'}
                onPressedChange={() => setUnits('imperial')}
                className="flex-1"
              >
                Imperial (oz, in, lb)
              </Toggle>
            </div>
          </div>

          <div className="space-y-2">
            <Label>Time Zone</Label>
            <Input
              value={timeZone}
              onChange={(e) => setTimeZone(e.target.value)}
              placeholder="America/New_York"
            />
            <p className="text-xs text-muted-foreground">
              Auto-detected: {detectTimeZone()}
            </p>
          </div>

          <div className="flex gap-2">
            <Button onClick={() => setStep(1)} variant="outline">
              Back
            </Button>
            <Button 
              onClick={handleCreateBaby} 
              className="flex-1"
              disabled={isCreating}
            >
              {isCreating ? 'Creating...' : 'Create Profile'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
