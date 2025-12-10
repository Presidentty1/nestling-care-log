/**
 * Gentle animation utilities for sleep-deprived parents
 * Subtle, non-distracting animations that provide feedback without being flashy
 */

/**
 * Gentle scale animation for successful actions
 * Returns a className string for subtle feedback
 */
export function gentleSuccessAnimation(): string {
  return 'animate-in fade-in zoom-in-95 duration-200';
}

/**
 * Gentle page transition animation
 */
export function pageTransitionAnimation(): string {
  return 'animate-in fade-in slide-in-from-bottom-2 duration-300';
}

/**
 * Subtle pulse for active timers (not distracting)
 */
export function subtlePulse(): string {
  return 'animate-pulse duration-2000';
}

// Additional animation utilities for UX overhaul

// Animation durations (in ms)
export const DURATIONS = {
  fast: 150, // Micro-interactions
  normal: 300, // Standard transitions
  slow: 500, // Complex animations
} as const;

// Micro-interaction utilities
export const microInteractions = {
  press: {
    active: 'active:scale-[0.98]',
    transition: 'transition-transform duration-100',
  },
  hoverScale: {
    hover: 'hover:scale-105',
    transition: 'transition-transform duration-200',
  },
} as const;

// Get press effect classes
export function getPressEffect(): string {
  return `${microInteractions.press.active} ${microInteractions.press.transition}`;
}

// Confetti effect utility
export function triggerConfetti(
  options: {
    count?: number;
    colors?: string[];
    duration?: number;
  } = {}
) {
  const {
    count = 50,
    colors = ['#2E7D6A', '#6A7DFF', '#0BA5EC', '#8B5CF6', '#FB923C'],
    duration = 3000,
  } = options;

  for (let i = 0; i < count; i++) {
    const confetti = document.createElement('div');
    confetti.style.position = 'fixed';
    confetti.style.width = '10px';
    confetti.style.height = '10px';
    confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
    confetti.style.left = `${Math.random() * 100}%`;
    confetti.style.top = '-10px';
    confetti.style.borderRadius = Math.random() > 0.5 ? '50%' : '0';
    confetti.style.opacity = '1';
    confetti.style.pointerEvents = 'none';
    confetti.style.zIndex = '9999';
    confetti.style.transition = `all ${duration}ms cubic-bezier(0.25, 0.46, 0.45, 0.94)`;

    document.body.appendChild(confetti);

    // Animate
    setTimeout(() => {
      confetti.style.top = '100vh';
      confetti.style.left = `${parseInt(confetti.style.left) + (Math.random() * 40 - 20)}%`;
      confetti.style.opacity = '0';
    }, 10);

    // Remove after animation
    setTimeout(() => {
      confetti.remove();
    }, duration);
  }
}
