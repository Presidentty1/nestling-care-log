import { dateUtils } from './dateUtils';

/**
 * Common validation utilities used across the application
 */

export const validationUtils = {
  /**
   * Validates a UUID string
   */
  isValidUUID: (id: string): boolean => {
    if (!id || typeof id !== 'string') return false;
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(id);
  },

  /**
   * Validates email format
   */
  isValidEmail: (email: string): boolean => {
    if (!email || typeof email !== 'string') return false;
    const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
    return emailRegex.test(email.trim());
  },

  /**
   * Validates baby name
   */
  isValidBabyName: (name: string): boolean => {
    if (!name || typeof name !== 'string') return false;
    const trimmed = name.trim();
    return trimmed.length > 0 && trimmed.length <= 50 && /^[a-zA-Z\s\-']+$/.test(trimmed);
  },

  /**
   * Validates event type
   */
  isValidEventType: (type: string): boolean => {
    const validTypes = ['feed', 'sleep', 'diaper', 'tummy_time'];
    return validTypes.includes(type);
  },

  /**
   * Validates diaper subtype
   */
  isValidDiaperSubtype: (subtype: string): boolean => {
    const validSubtypes = ['wet', 'dirty', 'both'];
    return validSubtypes.includes(subtype);
  },

  /**
   * Validates feeding side
   */
  isValidFeedingSide: (side: string): boolean => {
    const validSides = ['left', 'right', 'both'];
    return validSides.includes(side);
  },

  /**
   * Validates feeding style
   */
  isValidFeedingStyle: (style: string): boolean => {
    const validStyles = ['breast', 'bottle', 'both'];
    return validStyles.includes(style);
  },

  /**
   * Validates sex value
   */
  isValidSex: (sex: string): boolean => {
    const validSexes = ['m', 'f', 'other'];
    return validSexes.includes(sex);
  },

  /**
   * Validates amount range
   */
  isValidAmount: (amount: number): boolean => {
    return typeof amount === 'number' && amount > 0 && amount <= 1000;
  },

  /**
   * Validates duration range
   */
  isValidDuration: (duration: number): boolean => {
    return typeof duration === 'number' && duration >= 0 && duration <= 1440; // 24 hours in minutes
  },

  /**
   * Validates age range for babies
   */
  isValidBabyAge: (dateOfBirth: string): boolean => {
    if (!dateUtils.isValidISODate(dateOfBirth)) return false;

    const dob = new Date(dateOfBirth);
    const now = new Date();

    // Cannot be born in the future
    if (dob > now) return false;

    // Cannot be more than 1 year old
    const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
    if (dob < oneYearAgo) return false;

    return true;
  },

  /**
   * Comprehensive event validation
   */
  validateEvent: (event: {
    baby_id?: string;
    family_id?: string;
    type?: string;
    start_time?: string;
    end_time?: string;
    amount?: number;
    subtype?: string;
    side?: string;
  }): { isValid: boolean; errors: string[] } => {
    const errors: string[] = [];

    if (!event.baby_id || !validationUtils.isValidUUID(event.baby_id)) {
      errors.push('Valid baby ID is required');
    }

    if (!event.family_id || !validationUtils.isValidUUID(event.family_id)) {
      errors.push('Valid family ID is required');
    }

    if (!event.type || !validationUtils.isValidEventType(event.type)) {
      errors.push('Valid event type is required');
    }

    if (!event.start_time || !dateUtils.isValidISODate(event.start_time)) {
      errors.push('Valid start time is required');
    } else {
      // Check date constraints
      if (dateUtils.isInFuture(event.start_time)) {
        errors.push('Event time cannot be in the future');
      }

      if (dateUtils.isTooOld(event.start_time)) {
        errors.push('Cannot log events older than one year');
      }
    }

    if (event.end_time) {
      if (!dateUtils.isValidISODate(event.end_time)) {
        errors.push('Invalid end time format');
      } else if (event.start_time && new Date(event.end_time) < new Date(event.start_time)) {
        errors.push('End time cannot be before start time');
      }
    }

    if (event.type === 'feed' && event.amount !== undefined && !validationUtils.isValidAmount(event.amount)) {
      errors.push('Feed amount must be between 0 and 1000 ml');
    }

    if (event.type === 'diaper' && event.subtype && !validationUtils.isValidDiaperSubtype(event.subtype)) {
      errors.push('Invalid diaper subtype');
    }

    if (event.type === 'feed' && event.side && !validationUtils.isValidFeedingSide(event.side)) {
      errors.push('Invalid feeding side');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  },

  /**
   * Comprehensive baby validation
   */
  validateBaby: (baby: {
    name?: string;
    date_of_birth?: string;
    sex?: string;
    primary_feeding_style?: string;
  }): { isValid: boolean; errors: string[] } => {
    const errors: string[] = [];

    if (!baby.name || !validationUtils.isValidBabyName(baby.name)) {
      errors.push('Baby name is required and must be 1-50 characters');
    }

    if (!baby.date_of_birth || !validationUtils.isValidBabyAge(baby.date_of_birth)) {
      errors.push('Valid date of birth is required (cannot be in future or more than 1 year ago)');
    }

    if (baby.sex && !validationUtils.isValidSex(baby.sex)) {
      errors.push('Invalid sex value');
    }

    if (baby.primary_feeding_style && !validationUtils.isValidFeedingStyle(baby.primary_feeding_style)) {
      errors.push('Invalid feeding style');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
};




