import React from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

interface OnboardingStepViewProps {
  stepNumber: number;
  totalSteps: number;
  icon: React.ReactNode;
  title: string;
  description: string | React.ReactNode;
  primaryAction: {
    label: string;
    onClick: () => void;
    disabled?: boolean;
    loading?: boolean;
  };
  secondaryAction?: {
    label: string;
    onClick: () => void;
  };
  children?: React.ReactNode; // For additional content like forms
}

export function OnboardingStepView({
  stepNumber,
  totalSteps,
  icon,
  title,
  description,
  primaryAction,
  secondaryAction,
  children
}: OnboardingStepViewProps) {
  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header zone */}
      <div className="pt-4 pb-8">
        {/* Progress dots */}
        <div className="flex justify-center mb-4">
          <div className="flex gap-2">
            {Array.from({ length: totalSteps }, (_, i) => (
              <div
                key={i}
                className={`w-2 h-2 rounded-full transition-colors ${
                  i + 1 <= stepNumber ? 'bg-primary' : 'bg-muted'
                }`}
              />
            ))}
          </div>
        </div>

        {/* Step indicator */}
        <div className="text-center">
          <p className="font-caption text-muted-foreground">
            Step {stepNumber} of {totalSteps}
          </p>
        </div>
      </div>

      {/* Content zone */}
      <div className="flex-1 px-6 pb-8">
        <div className="max-w-md mx-auto text-center">
          {/* Icon */}
          <div className="mb-6 flex justify-center">
            {icon}
          </div>

          {/* Title */}
          <h1 className="font-title text-foreground mb-4">
            {title}
          </h1>

          {/* Description */}
          <div className="font-body text-muted-foreground mb-8 leading-relaxed">
            {description}
          </div>

          {/* Additional content (forms, etc.) */}
          {children}
        </div>
      </div>

      {/* CTA zone - pinned to bottom */}
      <div className="px-6 pb-6 safe-area-inset-bottom">
        <div className="max-w-md mx-auto space-y-4">
          {/* Primary action */}
          <Button
            onClick={primaryAction.onClick}
            disabled={primaryAction.disabled || primaryAction.loading}
            className="w-full btn-pill"
            size="lg"
          >
            {primaryAction.loading ? 'Loading...' : primaryAction.label}
          </Button>

          {/* Secondary action */}
          {secondaryAction && (
            <Button
              variant="ghost"
              onClick={secondaryAction.onClick}
              className="w-full font-caption text-muted-foreground hover:text-foreground"
            >
              {secondaryAction.label}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

