/**
 * Input sanitization utilities for preventing XSS and ensuring data integrity
 */

export interface SanitizationOptions {
  maxLength?: number;
  allowHtml?: boolean;
  allowNewlines?: boolean;
  trimWhitespace?: boolean;
  customPattern?: RegExp;
}

/**
 * Sanitizes text input by removing potentially dangerous characters
 */
export function sanitizeTextInput(
  input: string,
  options: SanitizationOptions = {}
): string {
  if (typeof input !== 'string') {
    return '';
  }

  let sanitized = input;

  // Trim whitespace if requested
  if (options.trimWhitespace !== false) {
    sanitized = sanitized.trim();
  }

  // Limit length
  if (options.maxLength && options.maxLength > 0) {
    sanitized = sanitized.substring(0, options.maxLength);
  }

  // Remove HTML tags if not allowed
  if (!options.allowHtml) {
    sanitized = sanitized.replace(/<[^>]*>/g, '');
  }

  // Remove script tags and javascript: protocols
  sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  sanitized = sanitized.replace(/javascript:/gi, '');
  sanitized = sanitized.replace(/on\w+\s*=/gi, '');

  // Remove null bytes and other control characters
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');

  return sanitized;
}

/**
 * Sanitizes numeric input
 */
export function sanitizeNumericInput(
  input: string | number,
  options: { min?: number; max?: number; allowDecimals?: boolean } = {}
): number | null {
  let num: number;

  if (typeof input === 'number') {
    num = input;
  } else if (typeof input === 'string') {
    // Remove non-numeric characters except decimal point and minus sign
    const cleaned = input.replace(/[^0-9.-]/g, '');
    num = parseFloat(cleaned);
  } else {
    return null;
  }

  if (isNaN(num)) {
    return null;
  }

  // Check range
  if (options.min !== undefined && num < options.min) {
    return options.min;
  }
  if (options.max !== undefined && num > options.max) {
    return options.max;
  }

  // Remove decimals if not allowed
  if (!options.allowDecimals) {
    num = Math.round(num);
  }

  return num;
}

/**
 * Validates email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim());
}

/**
 * Sanitizes and validates baby name
 */
export function sanitizeBabyName(name: string): string {
  return sanitizeTextInput(name, {
    maxLength: 50,
    allowHtml: false,
    trimWhitespace: true,
  });
}

/**
 * Sanitizes event notes
 */
export function sanitizeEventNote(note: string): string {
  return sanitizeTextInput(note, {
    maxLength: 500,
    allowHtml: false,
    allowNewlines: true,
    trimWhitespace: true,
  });
}

/**
 * Sanitizes amount values for feeds, etc.
 */
export function sanitizeAmount(amount: string | number): number | null {
  return sanitizeNumericInput(amount, {
    min: 0,
    max: 1000,
    allowDecimals: true,
  });
}

/**
 * Sanitizes duration values (in seconds)
 */
export function sanitizeDuration(duration: string | number): number | null {
  return sanitizeNumericInput(duration, {
    min: 0,
    max: 86400, // 24 hours max
    allowDecimals: false,
  });
}

/**
 * Sanitizes time zone identifiers
 */
export function sanitizeTimeZone(timeZone: string): string {
  // Only allow valid IANA time zone identifiers
  const validTimeZones = [
    'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/London', 'Europe/Paris', 'Europe/Berlin', 'Asia/Tokyo',
    'Australia/Sydney', 'Pacific/Auckland', 'UTC', 'GMT'
  ];

  if (validTimeZones.includes(timeZone)) {
    return timeZone;
  }

  // Default to system time zone
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

/**
 * Sanitizes URLs
 */
export function sanitizeUrl(url: string): string {
  try {
    const urlObj = new URL(url);
    // Only allow http and https protocols
    if (urlObj.protocol !== 'http:' && urlObj.protocol !== 'https:') {
      return '';
    }
    return urlObj.href;
  } catch {
    return '';
  }
}

/**
 * Sanitizes file names
 */
export function sanitizeFileName(fileName: string): string {
  return sanitizeTextInput(fileName, {
    maxLength: 255,
    allowHtml: false,
    trimWhitespace: true,
  }).replace(/[<>:"/\\|?*]/g, '_'); // Replace invalid file name characters
}

/**
 * Validates and sanitizes form data
 */
export function validateFormData<T extends Record<string, any>>(
  data: T,
  validators: Partial<Record<keyof T, (value: any) => boolean>>
): { isValid: boolean; errors: Partial<Record<keyof T, string>>; sanitizedData: T } {
  const errors: Partial<Record<keyof T, string>> = {};
  const sanitizedData = { ...data };

  for (const [key, validator] of Object.entries(validators)) {
    const fieldKey = key as keyof T;
    const value = data[fieldKey];

    if (!validator(value)) {
      errors[fieldKey] = `${String(fieldKey)} is invalid`;
    } else {
      // Apply basic sanitization
      if (typeof value === 'string') {
        sanitizedData[fieldKey] = sanitizeTextInput(value) as T[keyof T];
      }
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
    sanitizedData,
  };
}




