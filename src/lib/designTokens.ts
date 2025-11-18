/**
 * Design Tokens - Centralized access to theme values
 * These match the CSS variables in src/index.css
 */

export const colors = {
  // Primary brand
  primary: 'hsl(168, 46%, 34%)',
  primarySoft: 'hsl(168, 46%, 94%)',
  
  // Event types
  eventFeed: 'hsl(199, 89%, 48%)',
  eventSleep: 'hsl(262, 52%, 47%)',
  eventDiaper: 'hsl(43, 96%, 56%)',
  eventGrowth: 'hsl(142, 71%, 45%)',
  eventHealth: 'hsl(0, 84%, 60%)',
  
  // UI states
  success: 'hsl(142, 71%, 45%)',
  warning: 'hsl(43, 96%, 56%)',
  danger: 'hsl(0, 84%, 60%)',
  
  // Neutrals
  background: 'hsl(0, 0%, 100%)',
  foreground: 'hsl(240, 10%, 3.9%)',
  muted: 'hsl(240, 4.8%, 95.9%)',
  mutedForeground: 'hsl(240, 3.8%, 46.1%)',
  
  // Borders and accents
  border: 'hsl(240, 5.9%, 90%)',
  accent: 'hsl(168, 46%, 94%)',
} as const;

export const spacing = {
  xs: '4px',
  sm: '8px',
  md: '12px',
  lg: '16px',
  xl: '24px',
  '2xl': '32px',
  '3xl': '48px',
} as const;

export const borderRadius = {
  sm: '0.375rem', // 6px
  md: '0.5rem',   // 8px
  lg: '0.75rem',  // 12px
  xl: '1rem',     // 16px
  pill: '9999px',
} as const;

export const shadows = {
  soft: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
  medium: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
  large: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
  glow: '0 0 20px rgba(108, 185, 168, 0.3)',
} as const;

export const typography = {
  h1: 'text-2xl font-bold',
  h2: 'text-xl font-semibold',
  h3: 'text-lg font-medium',
  body: 'text-base',
  small: 'text-sm text-muted-foreground',
  tiny: 'text-xs text-muted-foreground',
  headline: 'text-[28px] leading-[34px] font-semibold tabular-nums',
} as const;

export const transitions = {
  fast: '150ms cubic-bezier(0.4, 0, 0.2, 1)',
  base: '300ms cubic-bezier(0.4, 0, 0.2, 1)',
  slow: '500ms cubic-bezier(0.4, 0, 0.2, 1)',
} as const;

/**
 * iOS-specific dimensions
 */
export const ios = {
  minTouchTarget: '44px', // Apple Human Interface Guidelines
  safeAreaTop: '44px',    // Standard iPhone notch
  safeAreaBottom: '34px', // Home indicator area
  tabBarHeight: '49px',   // Standard iOS tab bar
} as const;
