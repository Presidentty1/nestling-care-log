import React, { useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { motion } from 'framer-motion';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { cn } from '@/lib/utils';

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
  children?: React.ReactNode;
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
  
  const handlePrimaryClick = async () => {
    if (!primaryAction.disabled && !primaryAction.loading) {
      await Haptics.impact({ style: ImpactStyle.Light });
      primaryAction.onClick();
    }
  };

  const handleSecondaryClick = async () => {
    await Haptics.impact({ style: ImpactStyle.Light });
    secondaryAction?.onClick();
  };

  return (
    <div className="min-h-screen bg-background flex flex-col overflow-hidden">
      {/* Header zone */}
      <div className="pt-4 pb-4 px-6">
        {/* Progress dots */}
        {totalSteps > 1 && (
          <div className="flex justify-center mb-6">
            <div className="flex gap-2">
              {Array.from({ length: totalSteps }, (_, i) => (
                <div
                  key={i}
                  className={cn(
                    "w-2 h-2 rounded-full transition-all duration-300",
                    i + 1 === stepNumber 
                      ? "bg-primary w-4" 
                      : i + 1 < stepNumber 
                        ? "bg-primary/40" 
                        : "bg-muted"
                  )}
                />
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Content zone */}
      <div className="flex-1 flex flex-col px-6 pb-8 overflow-y-auto no-scrollbar">
        <motion.div
          initial={{ opacity: 0, y: 20, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          className="flex-1 flex flex-col"
        >
          <div className="max-w-md mx-auto w-full text-center flex-1 flex flex-col">
            {/* Icon */}
            <motion.div 
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.1, duration: 0.4 }}
              className="mb-8 flex justify-center"
            >
              <div className="p-4 rounded-full bg-primary/10 text-primary">
                {icon}
              </div>
            </motion.div>

            {/* Title */}
            <h1 className="text-[32px] leading-[1.1] font-bold tracking-tight text-foreground mb-3">
              {title}
            </h1>

            {/* Description */}
            <div className="text-[17px] leading-relaxed text-muted-foreground/90 mb-8">
              {description}
            </div>

            {/* Additional content (forms, etc.) */}
            <div className="flex-1 w-full text-left">
              {children}
            </div>
          </div>
        </motion.div>
      </div>

      {/* CTA zone - pinned to bottom with safe area */}
      <div className="px-6 pb-6 pt-4 bg-background/80 backdrop-blur-xl border-t border-border/10 sticky bottom-0 z-10 safe-area-inset-bottom">
        <div className="max-w-md mx-auto space-y-3">
          {/* Primary action */}
          <Button
            onClick={handlePrimaryClick}
            disabled={primaryAction.disabled || primaryAction.loading}
            className={cn(
              "w-full btn-pill text-[17px] font-semibold shadow-lg shadow-primary/20",
              "active:scale-[0.98] transition-transform duration-100"
            )}
            size="lg"
          >
            {primaryAction.loading ? 'Loading...' : primaryAction.label}
          </Button>

          {/* Secondary action */}
          {secondaryAction && (
            <Button
              variant="ghost"
              onClick={handleSecondaryClick}
              className="w-full h-auto py-3 text-[17px] font-medium text-muted-foreground hover:text-foreground hover:bg-transparent active:opacity-70 transition-opacity"
            >
              {secondaryAction.label}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
