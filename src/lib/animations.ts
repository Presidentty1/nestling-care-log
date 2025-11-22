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

