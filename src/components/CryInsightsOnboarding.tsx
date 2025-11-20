import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Mic, Shield, AlertTriangle, CheckCircle, Clock, Heart, Thermometer, Frown } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

interface CryInsightsOnboardingProps {
  onComplete: () => void;
}

export function CryInsightsOnboarding({ onComplete }: CryInsightsOnboardingProps) {
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    {
      title: "What Cry Insights Does",
      icon: <Mic className="h-8 w-8 text-primary" />,
      content: (
        <div className="space-y-4">
          <div className="text-center">
            <p className="text-lg font-medium mb-4">Analyze your baby's cry patterns</p>
            <div className="grid gap-3 text-left">
              <div className="flex items-start gap-3">
                <CheckCircle className="h-5 w-5 text-green-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium">What you'll get:</p>
                  <p className="text-sm text-muted-foreground">Likely reason for the cry, confidence level, and a short tip</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-amber-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium">What we don't do:</p>
                  <p className="text-sm text-muted-foreground">Diagnose medical conditions or replace professional advice</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <Shield className="h-5 w-5 text-blue-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium">Privacy:</p>
                  <p className="text-sm text-muted-foreground">Recordings are processed in real-time and not stored</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Example Results",
      icon: <Heart className="h-8 w-8 text-primary" />,
      content: (
        <div className="space-y-4">
          <p className="text-center text-muted-foreground mb-4">Here's what a typical analysis might show:</p>
          <div className="space-y-3">
            <Card className="border-green-200 bg-green-50 dark:bg-green-950/20">
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  <Clock className="h-5 w-5 text-green-600 mt-0.5" />
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium">Tired</span>
                      <Badge variant="secondary" className="text-xs">85% confidence</Badge>
                    </div>
                    <p className="text-sm text-muted-foreground">Try a quiet, dim space and a short wind-down routine.</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-blue-200 bg-blue-50 dark:bg-blue-950/20">
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  <Heart className="h-5 w-5 text-blue-600 mt-0.5" />
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium">Hungry</span>
                      <Badge variant="secondary" className="text-xs">72% confidence</Badge>
                    </div>
                    <p className="text-sm text-muted-foreground">Check if it's been 2-3 hours since the last feed.</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-purple-200 bg-purple-50 dark:bg-purple-950/20">
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  <Thermometer className="h-5 w-5 text-purple-600 mt-0.5" />
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium">Uncomfortable</span>
                      <Badge variant="secondary" className="text-xs">68% confidence</Badge>
                    </div>
                    <p className="text-sm text-muted-foreground">Check diaper, temperature, or clothing comfort.</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )
    },
    {
      title: "Important Safety Information",
      icon: <AlertTriangle className="h-8 w-8 text-amber-500" />,
      content: (
        <div className="space-y-4">
          <Alert className="border-amber-200 bg-amber-50 dark:bg-amber-950/20">
            <AlertTriangle className="h-4 w-4 text-amber-600" />
            <AlertDescription className="text-amber-800 dark:text-amber-200">
              <strong>Medical Disclaimer:</strong> This feature is for informational purposes only.
              It does not replace professional medical advice, diagnosis, or treatment.
            </AlertDescription>
          </Alert>

          <div className="space-y-3">
            <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
              <Frown className="h-5 w-5 text-muted-foreground mt-0.5" />
              <div>
                <p className="font-medium">When to seek professional help:</p>
                <ul className="text-sm text-muted-foreground mt-1 space-y-1">
                  <li>• If your baby seems very unwell or in pain</li>
                  <li>• If crying persists for more than 3 hours</li>
                  <li>• If accompanied by fever, rash, or unusual symptoms</li>
                  <li>• If you're worried about your baby's health</li>
                </ul>
              </div>
            </div>

            <div className="text-center p-4 bg-primary/5 rounded-lg">
              <p className="font-medium text-primary mb-1">Always consult your pediatrician</p>
              <p className="text-sm text-muted-foreground">
                If your baby seems very unwell or you're worried, contact a pediatric professional immediately.
              </p>
            </div>
          </div>
        </div>
      )
    }
  ];

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // Mark as seen and complete
      localStorage.setItem('has_seen_cry_explainer', 'true');
      onComplete();
    }
  };

  const handleSkip = () => {
    localStorage.setItem('has_seen_cry_explainer', 'true');
    onComplete();
  };

  const currentStepData = steps[currentStep];

  return (
    <Dialog open={true} onOpenChange={() => {}}>
      <DialogContent className="sm:max-w-lg" hideCloseButton>
        <DialogHeader className="text-center">
          <div className="flex justify-center mb-4">
            {currentStepData.icon}
          </div>
          <DialogTitle className="text-xl">{currentStepData.title}</DialogTitle>
        </DialogHeader>

        <div className="py-4">
          {currentStepData.content}
        </div>

        {/* Progress indicators */}
        <div className="flex justify-center gap-2 mb-6">
          {steps.map((_, index) => (
            <div
              key={index}
              className={`w-2 h-2 rounded-full transition-colors ${
                index === currentStep ? 'bg-primary' : 'bg-muted'
              }`}
            />
          ))}
        </div>

        <div className="flex gap-3">
          <Button
            variant="ghost"
            onClick={handleSkip}
            className="flex-1"
          >
            Skip
          </Button>
          <Button
            onClick={handleNext}
            className="flex-1"
          >
            {currentStep === steps.length - 1 ? 'Get Started' : 'Next'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
