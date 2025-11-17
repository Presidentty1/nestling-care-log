import { Haptics, ImpactStyle } from '@capacitor/haptics';

/**
 * Haptic feedback utilities for mobile devices
 * Gracefully fails on web/desktop platforms
 */
export const hapticFeedback = {
  /**
   * Light haptic feedback for subtle interactions
   * Use for: button taps, toggles, selections
   */
  light: async () => {
    try {
      await Haptics.impact({ style: ImpactStyle.Light });
    } catch (e) {
      // Haptics not available on web
    }
  },

  /**
   * Medium haptic feedback for standard interactions
   * Use for: quick actions, sheet open/close, confirmations
   */
  medium: async () => {
    try {
      await Haptics.impact({ style: ImpactStyle.Medium });
    } catch (e) {
      // Haptics not available on web
    }
  },

  /**
   * Heavy haptic feedback for important interactions
   * Use for: delete actions, errors, critical confirmations
   */
  heavy: async () => {
    try {
      await Haptics.impact({ style: ImpactStyle.Heavy });
    } catch (e) {
      // Haptics not available on web
    }
  },

  /**
   * Selection changed haptic for picker/slider interactions
   */
  selection: async () => {
    try {
      await Haptics.selectionStart();
      await Haptics.selectionChanged();
      await Haptics.selectionEnd();
    } catch (e) {
      // Haptics not available on web
    }
  },
};
