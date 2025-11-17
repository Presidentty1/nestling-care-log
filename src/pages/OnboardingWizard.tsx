import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Toggle } from '@/components/ui/toggle';
import { CalendarIcon, Baby, ArrowRight, ArrowLeft } from 'lucide-react';
import { format } from 'date-fns';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import { detectTimeZone } from '@/services/time';
import { validateBaby } from '@/services/validation';
import { toast } from 'sonner';
import { NotificationPermissionCard } from '@/components/NotificationPermissionCard';
import { hapticFeedback } from '@/lib/haptics';

export default function OnboardingWizard() {
  const navigate = useNavigate();
  const { setActiveBabyId } = useAppStore();
  const [step, setStep] = useState(1);
  const [name, setName] = useState('');
  const [dob, setDob] = useState<Date>();
  const [sex, setSex] = useState<'m' | 'f' | 'other'>('m');
  const [feedingStyle, setFeedingStyle] = useState<'breast' | 'bottle' | 'both'>('both');
  const [timeZone] = useState(detectTimeZone());
  const [units, setUnits] = useState<'metric' | 'imperial'>('imperial');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isCreating, setIsCreating] = useState(false);

  const handleStep1Next = () => {
    hapticFeedback.light();
    const newErrors: Record<string, string> = {};
    
    if (!name.trim()) {
      newErrors.name = 'Let\'s add a name for your baby';
    } else if (name.length > 40) {
      newErrors.name = 'Name must be 40 characters or less';
    }
    
    if (!dob) {
      newErrors.dob = 'We need a date of birth';
    } else if (dob > new Date()) {
      newErrors.dob = 'Date cannot be in the future';
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
    
    hapticFeedback.medium();
    setIsCreating(true);
    try {
      const babyData = {
        name: name.trim(),
        dobISO: format(dob, 'yyyy-MM-dd'),
        sex,
        timeZone,
        units,
        primary_feeding_style: feedingStyle,
      };
      
      const validation = validateBaby(babyData);
      if (!validation.success) {
        toast.error('Please check your input');
        setIsCreating(false);
        return;
      }
      
      const baby = await dataService.addBaby(babyData);
      setActiveBabyId(baby.id);
      toast.success(`Welcome, ${baby.name}! 🎉`);
      navigate('/home');
    } catch (error) {
      console.error('Failed to create baby:', error);
      toast.error('Could not create profile. Please try again.');
      setIsCreating(false);
    }
  };

  const handleCreateDemo = async () => {
    hapticFeedback.medium();
    setIsCreating(true);
    try {
      const baby = await dataService.addBaby({
        name: 'Demo Baby',
        dobISO: format(new Date(), 'yyyy-MM-dd'),
        timeZone: detectTimeZone(),
        units: 'imperial',
      });
      setActiveBabyId(baby.id);
      toast.success('Demo profile created! 🎉');
      navigate('/home');
    } catch (error) {
      console.error('Failed to create demo:', error);
      toast.error('Failed to create demo profile');
    } finally {
      setIsCreating(false);
    }
  };

  const ProgressDots = () => (
    <div className="flex justify-center gap-2 mb-6">
      {[1, 2, 3].map((i) => (
        <div
          key={i}
          className={`h-2 rounded-full transition-all ${
            i === step
              ? 'w-8 bg-primary'
              : i < step
              ? 'w-2 bg-primary/50'
              : 'w-2 bg-muted'
          }`}
        />
      ))}
    </div>
  );

  if (step === 1) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader>
            <div className="flex items-center gap-2 mb-2">
              <Baby className="h-6 w-6 text-primary" />
              <CardTitle className="text-headline">Let's set up your baby's profile</CardTitle>
            </div>
            <CardDescription>Start tracking your little one's journey</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <ProgressDots />
            
            <div>
              <Label htmlFor="name">Baby's Name</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => {
                  setName(e.target.value);
                  if (errors.name) setErrors({ ...errors, name: '' });
                }}
                placeholder="Enter name"
                className={errors.name ? 'border-destructive' : ''}
                autoFocus
              />
              {errors.name && (
                <p className="text-sm text-destructive mt-1">{errors.name}</p>
              )}
            </div>

            <div>
              <Label>Date of Birth</Label>
              <div className="flex gap-2">
                <Popover>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={`flex-1 justify-start text-left font-normal ${
                        !dob && 'text-muted-foreground'
                      } ${errors.dob ? 'border-destructive' : ''}`}
                    >
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {dob ? format(dob, 'PPP') : 'Pick a date'}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0">
                    <Calendar
                      mode="single"
                      selected={dob}
                      onSelect={(date) => {
                        hapticFeedback.light();
                        setDob(date);
                        if (errors.dob) setErrors({ ...errors, dob: '' });
                      }}
                      initialFocus
                      disabled={(date) => date > new Date()}
                    />
                  </PopoverContent>
                </Popover>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    hapticFeedback.light();
                    setDob(new Date());
                    if (errors.dob) setErrors({ ...errors, dob: '' });
                  }}
                >
                  Today
                </Button>
              </div>
              {errors.dob && (
                <p className="text-sm text-destructive mt-1">{errors.dob}</p>
              )}
            </div>

            <div className="text-sm text-muted-foreground">
              Timezone: {timeZone} (detected)
            </div>

            <div className="flex gap-2">
              <Button onClick={handleStep1Next} className="flex-1">
                Next
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </div>

            <Button
              type="button"
              variant="ghost"
              onClick={handleCreateDemo}
              disabled={isCreating}
              className="w-full"
            >
              Create Demo Baby
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (step === 2) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle className="text-headline">A few more details (optional)</CardTitle>
            <CardDescription>This helps us provide better insights</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <ProgressDots />

            <div>
              <Label>Sex</Label>
              <RadioGroup value={sex} onValueChange={(v: any) => {
                hapticFeedback.light();
                setSex(v);
              }}>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="m" id="male" />
                  <Label htmlFor="male" className="font-normal">Male</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="f" id="female" />
                  <Label htmlFor="female" className="font-normal">Female</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="other" id="other" />
                  <Label htmlFor="other" className="font-normal">Other</Label>
                </div>
              </RadioGroup>
            </div>

            <div>
              <Label>Primary Feeding Style</Label>
              <RadioGroup value={feedingStyle} onValueChange={(v: any) => {
                hapticFeedback.light();
                setFeedingStyle(v);
              }}>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="breast" id="breast" />
                  <Label htmlFor="breast" className="font-normal">Breastfeeding</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="bottle" id="bottle" />
                  <Label htmlFor="bottle" className="font-normal">Bottle</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="both" id="both" />
                  <Label htmlFor="both" className="font-normal">Both</Label>
                </div>
              </RadioGroup>
            </div>

            <div>
              <Label>Measurement Units</Label>
              <div className="flex gap-2 mt-2">
                <Toggle
                  pressed={units === 'metric'}
                  onPressedChange={(pressed) => {
                    hapticFeedback.light();
                    if (pressed) setUnits('metric');
                  }}
                  className="flex-1"
                >
                  Metric (ml, cm, kg)
                </Toggle>
                <Toggle
                  pressed={units === 'imperial'}
                  onPressedChange={(pressed) => {
                    hapticFeedback.light();
                    if (pressed) setUnits('imperial');
                  }}
                  className="flex-1"
                >
                  Imperial (oz, in, lb)
                </Toggle>
              </div>
            </div>

            <div className="flex gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  hapticFeedback.light();
                  setStep(1);
                }}
              >
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back
              </Button>
              <Button onClick={() => {
                hapticFeedback.light();
                setStep(3);
              }} className="flex-1">
                Next
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </div>

            <Button
              type="button"
              variant="ghost"
              onClick={() => {
                hapticFeedback.light();
                setStep(3);
              }}
              className="w-full"
            >
              Skip
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (step === 3) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle className="text-headline">Stay informed</CardTitle>
            <CardDescription>
              We can remind you when it's time to feed or check diapers. You can always change this later.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <ProgressDots />

            <NotificationPermissionCard onDismiss={() => {}} />

            <div className="flex gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  hapticFeedback.light();
                  setStep(2);
                }}
              >
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back
              </Button>
              <Button
                onClick={handleCreateBaby}
                disabled={isCreating}
                className="flex-1"
              >
                {isCreating ? 'Creating...' : 'Get Started'}
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return null;
}
