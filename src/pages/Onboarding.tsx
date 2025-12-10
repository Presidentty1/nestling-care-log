import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';
import { CalendarIcon, Baby, Sparkles } from 'lucide-react';
import { format } from 'date-fns';
import { dataService } from '@/services/dataService';
import { useAppStore } from '@/store/appStore';
import { detectTimeZone, parseLocalDate } from '@/services/time';
import { logger } from '@/lib/logger';
import { sanitizeBabyName } from '@/lib/sanitization';
import { validateBaby } from '@/services/validation';
import { toast } from 'sonner';
import { OnboardingStepView } from '@/components/onboarding/OnboardingStepView';
import { cn } from '@/lib/utils';
import { track } from '@/analytics/analytics';
import { analyticsService } from '@/services/analyticsService';
import { MESSAGING } from '@/lib/messaging';

export default function Onboarding() {
  const navigate = useNavigate();
  const { setActiveBabyId } = useAppStore();
  const nameInputRef = useRef<HTMLInputElement>(null);

  // State - Reduced to 3 steps for faster onboarding
  const [step, setStep] = useState(0); // 0: Name, 1: DOB, 2: Preferences
  const [onboardingStartTime] = useState(Date.now());
  const [loading, setLoading] = useState(false);
  const completedRef = useRef(false);

  // Form Data
  const [name, setName] = useState('');
  const [dob, setDob] = useState<Date>();
  const [dobInput, setDobInput] = useState('');
  const [sex, setSex] = useState<'m' | 'f' | 'other'>('m');
  const [timeZone, setTimeZone] = useState(detectTimeZone());
  const [units, setUnits] = useState<'metric' | 'imperial'>('imperial');

  // Errors
  const [errors, setErrors] = useState<Record<string, string>>({});

  const validateStep = useCallback(
    (currentStep: number): boolean => {
      const newErrors: Record<string, string> = {};

      if (currentStep === 0) {
        if (!name.trim()) {
          newErrors.name = 'Name is required';
        } else if (name.length > 40) {
          newErrors.name = 'Name must be 40 characters or less';
        }
      }

      if (currentStep === 1) {
        if (!dob) {
          newErrors.dob = 'Date of birth is required';
        } else if (dob > new Date()) {
          newErrors.dob = 'Date of birth cannot be in the future';
        }
      }

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return false;
      }

      setErrors({});
      return true;
    },
    [name, dob]
  );

  const nextStep = () => {
    if (validateStep(step)) {
      setStep(s => s + 1);
    }
  };

  const prevStep = () => {
    setStep(s => s - 1);
  };

  const handleCreateBaby = async () => {
    if (!validateStep(step)) return;

    setLoading(true);
    try {
      const babyData = {
        name: name.trim(),
        dobISO: dob ? format(dob, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
        sex,
        timeZone,
        units,
      };

      const validation = validateBaby(babyData);
      if (!validation.success) {
        toast.error('Please check your input');
        setLoading(false);
        return;
      }

      const sanitizedName = sanitizeBabyName(babyData.name);
      const baby = await dataService.addBaby({ ...babyData, name: sanitizedName });
      setActiveBabyId(baby.id);

      // Mark as completed to prevent dropoff tracking
      completedRef.current = true;

      // Track onboarding completion
      const timeSpentSeconds = Math.floor((Date.now() - onboardingStartTime) / 1000);
      analyticsService.trackOnboardingComplete(baby.id, timeSpentSeconds, 3);

      // Store onboarding completion time for first log tracking
      localStorage.setItem('onboardingCompletedAt', Date.now().toString());

      // Success & Redirect
      toast.success(`Welcome to Nestling, ${baby.name}!`);
      navigate('/home');
    } catch (error) {
      logger.error('Failed to create baby', error, 'Onboarding');
      toast.error('Could not create profile. Please try again.');
      setLoading(false);
    }
  };

  // Track onboarding started on mount
  useEffect(() => {
    analyticsService.trackOnboardingStarted();
  }, []);

  // Track dropoff if user navigates away before completing
  useEffect(() => {
    const handleBeforeUnload = () => {
      if (!completedRef.current) {
        const timeSpent = Math.floor((Date.now() - onboardingStartTime) / 1000);
        const stepId = step === 0 ? 'name' : step === 1 ? 'dob' : 'preferences';
        if (timeSpent > 0) {
          analyticsService.trackOnboardingDropoff(stepId, timeSpent);
        }
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
      // Track dropoff on unmount if not completed (e.g., browser back button)
      if (!completedRef.current) {
        const timeSpent = Math.floor((Date.now() - onboardingStartTime) / 1000);
        const stepId = step === 0 ? 'name' : step === 1 ? 'dob' : 'preferences';
        if (timeSpent > 0) {
          // Use sendBeacon for reliable tracking on page unload
          analyticsService.trackOnboardingDropoff(stepId, timeSpent);
        }
      }
    };
  }, [step, onboardingStartTime]);

  // Focus input after mount to prevent keyboard lag
  useEffect(() => {
    if (step === 0 && nameInputRef.current) {
      // Small delay to ensure component is fully rendered
      const timer = setTimeout(() => {
        nameInputRef.current?.focus();
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [step]);

  // Handle name input - sanitize only on blur
  const handleNameChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setName(e.target.value);
      if (errors.name) {
        setErrors(prev => ({ ...prev, name: '' }));
      }
    },
    [errors.name]
  );

  const handleNameBlur = useCallback(() => {
    const sanitized = sanitizeBabyName(name);
    if (sanitized !== name) {
      setName(sanitized);
    }
  }, [name]);

  // Memoize radio button handlers
  const handleSexChange = useCallback((value: string) => {
    setSex(value as 'm' | 'f' | 'other');
  }, []);

  const handleUnitsChange = useCallback((value: 'metric' | 'imperial') => {
    setUnits(value);
  }, []);

  // Step 0: Name (with inline value messaging)
  if (step === 0) {
    return (
      <OnboardingStepView
        stepNumber={1}
        totalSteps={3}
        icon={<Baby className='h-12 w-12' />}
        title={MESSAGING.onboarding.babyName.title}
        description="Track feeds, sleep & diapers in 2 taps. We'll personalize everything for your baby."
        primaryAction={{
          label: 'Next',
          onClick: nextStep,
          disabled: !name.trim(),
        }}
        secondaryAction={{
          label: 'Back',
          onClick: prevStep,
        }}
      >
        <div className='space-y-4 pt-4'>
          <div className='space-y-2'>
            <Label htmlFor='name' className='text-base font-semibold'>
              Baby's Name
            </Label>
            <Input
              ref={nameInputRef}
              id='name'
              value={name}
              onChange={handleNameChange}
              onBlur={handleNameBlur}
              placeholder='Enter name'
              className='h-16 text-lg px-4 bg-surface border-2 border-border focus-visible:border-primary transition-colors'
              autoComplete='off'
              inputMode='text'
              maxLength={40}
            />
            {errors.name && (
              <p className='text-sm text-destructive font-medium animate-in slide-in-from-top-1'>
                {errors.name}
              </p>
            )}
          </div>
        </div>
      </OnboardingStepView>
    );
  }

  // Step 1: DOB
  if (step === 1) {
    return (
      <OnboardingStepView
        stepNumber={2}
        totalSteps={3}
        icon={<CalendarIcon className='h-12 w-12' />}
        title={MESSAGING.onboarding.dateOfBirth.title}
        description="We'll use this to provide age-appropriate insights and smart nap predictions."
        primaryAction={{
          label: 'Next',
          onClick: nextStep,
          disabled: !dob,
        }}
        secondaryAction={{
          label: 'Back',
          onClick: prevStep,
        }}
      >
        <div className='space-y-6 pt-4'>
          <div className='space-y-2'>
            <Label className='text-base font-semibold'>Date of Birth</Label>
            <div className='flex gap-3'>
              <Input
                value={dobInput}
                onChange={e => setDobInput(e.target.value)}
                placeholder='MM/DD/YYYY'
                className='h-16 text-lg flex-1 px-4 bg-surface border-2 border-border focus-visible:border-primary transition-colors'
                autoComplete='off'
                onBlur={() => {
                  const parsed = parseLocalDate(dobInput);
                  if (parsed) {
                    setDob(parsed);
                    setErrors({ ...errors, dob: '' });
                  }
                }}
              />
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant='outline' className='h-16 w-16 p-0 shrink-0 border-2'>
                    <CalendarIcon className='h-7 w-7 text-muted-foreground' />
                  </Button>
                </PopoverTrigger>
                <PopoverContent className='w-auto p-0' align='end'>
                  <Calendar
                    mode='single'
                    selected={dob}
                    onSelect={date => {
                      setDob(date);
                      if (date) {
                        setDobInput(format(date, 'MM/dd/yyyy'));
                        setErrors({ ...errors, dob: '' });
                      }
                    }}
                    disabled={date => date > new Date()}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
            {errors.dob && (
              <p className='text-sm text-destructive font-medium animate-in slide-in-from-top-1'>
                {errors.dob}
              </p>
            )}
          </div>

          <Button
            variant='outline'
            onClick={() => {
              const today = new Date();
              setDob(today);
              setDobInput(format(today, 'MM/dd/yyyy'));
              setErrors({ ...errors, dob: '' });
            }}
            className='w-full h-14 font-semibold text-base border-2'
          >
            Just Born Today
          </Button>
        </div>
      </OnboardingStepView>
    );
  }

  // Step 2: Preferences (final step)
  return (
    <OnboardingStepView
      stepNumber={3}
      totalSteps={3}
      icon={<Sparkles className='h-12 w-12' />}
      title='Almost done!'
      description='Quick preferences to personalize your experience.'
      primaryAction={{
        label: 'Start Tracking',
        onClick: handleCreateBaby,
        loading,
      }}
      secondaryAction={{
        label: 'Back',
        onClick: prevStep,
      }}
    >
      <div className='space-y-8 pt-4'>
        <div className='space-y-3'>
          <Label className='text-base font-semibold'>Measurement Units</Label>
          <div className='grid grid-cols-2 gap-4'>
            <button
              type='button'
              className={cn(
                'cursor-pointer rounded-2xl border-2 p-5 transition-all duration-200 text-left min-h-[88px]',
                'active:scale-[0.98]',
                units === 'imperial'
                  ? 'border-primary bg-primary/10 shadow-sm'
                  : 'border-border bg-surface hover:border-primary/40'
              )}
              onClick={() => handleUnitsChange('imperial')}
            >
              <div className='font-semibold text-base mb-1.5'>Imperial</div>
              <div className='text-sm text-muted-foreground'>lb, oz, in</div>
            </button>
            <button
              type='button'
              className={cn(
                'cursor-pointer rounded-2xl border-2 p-5 transition-all duration-200 text-left min-h-[88px]',
                'active:scale-[0.98]',
                units === 'metric'
                  ? 'border-primary bg-primary/10 shadow-sm'
                  : 'border-border bg-surface hover:border-primary/40'
              )}
              onClick={() => handleUnitsChange('metric')}
            >
              <div className='font-semibold text-base mb-1.5'>Metric</div>
              <div className='text-sm text-muted-foreground'>kg, g, cm</div>
            </button>
          </div>
        </div>

        <div className='space-y-3'>
          <Label className='text-base font-semibold'>Sex (Optional)</Label>
          <RadioGroup
            value={sex}
            onValueChange={handleSexChange}
            className='grid grid-cols-3 gap-3'
          >
            <div>
              <RadioGroupItem value='m' id='male' className='peer sr-only' />
              <Label
                htmlFor='male'
                className='flex flex-col items-center justify-center rounded-2xl border-2 border-border bg-surface p-5 hover:border-primary/40 peer-data-[state=checked]:border-primary peer-data-[state=checked]:bg-primary/10 cursor-pointer transition-all h-[88px] active:scale-[0.98]'
              >
                <span className='font-semibold text-base'>Boy</span>
              </Label>
            </div>
            <div>
              <RadioGroupItem value='f' id='female' className='peer sr-only' />
              <Label
                htmlFor='female'
                className='flex flex-col items-center justify-center rounded-2xl border-2 border-border bg-surface p-5 hover:border-primary/40 peer-data-[state=checked]:border-primary peer-data-[state=checked]:bg-primary/10 cursor-pointer transition-all h-[88px] active:scale-[0.98]'
              >
                <span className='font-semibold text-base'>Girl</span>
              </Label>
            </div>
            <div>
              <RadioGroupItem value='other' id='other' className='peer sr-only' />
              <Label
                htmlFor='other'
                className='flex flex-col items-center justify-center rounded-2xl border-2 border-border bg-surface p-5 hover:border-primary/40 peer-data-[state=checked]:border-primary peer-data-[state=checked]:bg-primary/10 cursor-pointer transition-all h-[88px] active:scale-[0.98]'
              >
                <span className='font-semibold text-base'>Other</span>
              </Label>
            </div>
          </RadioGroup>
        </div>

        <div className='space-y-2'>
          <Label className='text-base font-semibold'>Time Zone</Label>
          <Input
            value={timeZone}
            onChange={e => setTimeZone(e.target.value)}
            placeholder='America/New_York'
            className='h-14 bg-surface border-2 border-border px-4 text-base'
            readOnly
          />
          <p className='text-xs text-muted-foreground flex items-center gap-1.5 px-1'>
            <Sparkles className='h-3.5 w-3.5' /> Auto-detected from your device
          </p>
        </div>
      </div>
    </OnboardingStepView>
  );
}
