/**
 * Centralized unit conversion service
 * 
 * CRITICAL RULES:
 * - Database ALWAYS stores metric (ml, g, cm)
 * - Convert for display based on user preference
 * - Convert on input before saving to database
 */

const ML_PER_OZ = 29.5735;
const G_PER_LB = 453.592;
const G_PER_OZ = 28.3495;
const CM_PER_INCH = 2.54;

export const unitConversion = {
  // ============= Volume Conversions =============
  
  mlToOz: (ml: number): number => {
    return Math.round((ml / ML_PER_OZ) * 10) / 10;
  },

  ozToMl: (oz: number): number => {
    return Math.round(oz * ML_PER_OZ);
  },

  // ============= Weight Conversions =============
  
  gToLb: (g: number): number => {
    return Math.round((g / G_PER_LB) * 100) / 100;
  },

  lbToG: (lb: number): number => {
    return Math.round(lb * G_PER_LB);
  },

  gToOz: (g: number): number => {
    return Math.round((g / G_PER_OZ) * 10) / 10;
  },

  ozToG: (oz: number): number => {
    return Math.round(oz * G_PER_OZ);
  },

  // ============= Length Conversions =============
  
  cmToIn: (cm: number): number => {
    return Math.round((cm / CM_PER_INCH) * 10) / 10;
  },

  inToCm: (inches: number): number => {
    return Math.round(inches * CM_PER_INCH * 10) / 10;
  },

  // ============= Display Formatters =============
  
  formatVolume: (amount: number, unit: 'ml' | 'oz'): string => {
    return `${amount}${unit}`;
  },

  formatWeight: (amount: number, unit: 'g' | 'lb' | 'oz'): string => {
    if (unit === 'lb') return `${amount} lb`;
    return `${amount}${unit}`;
  },

  formatLength: (amount: number, unit: 'cm' | 'in'): string => {
    return `${amount}${unit}`;
  },

  // ============= Storage Converters (to metric) =============
  
  toStorageVolume: (amount: number, unit: 'ml' | 'oz'): number => {
    return unit === 'oz' ? unitConversion.ozToMl(amount) : amount;
  },

  toStorageWeight: (amount: number, unit: 'g' | 'lb' | 'oz'): number => {
    if (unit === 'lb') return unitConversion.lbToG(amount);
    if (unit === 'oz') return unitConversion.ozToG(amount);
    return amount;
  },

  toStorageLength: (amount: number, unit: 'cm' | 'in'): number => {
    return unit === 'in' ? unitConversion.inToCm(amount) : amount;
  },

  // ============= Display Converters (from metric) =============
  
  fromStorageVolume: (ml: number, targetUnit: 'ml' | 'oz'): number => {
    return targetUnit === 'oz' ? unitConversion.mlToOz(ml) : ml;
  },

  fromStorageWeight: (g: number, targetUnit: 'g' | 'lb' | 'oz'): number => {
    if (targetUnit === 'lb') return unitConversion.gToLb(g);
    if (targetUnit === 'oz') return unitConversion.gToOz(g);
    return g;
  },

  fromStorageLength: (cm: number, targetUnit: 'cm' | 'in'): number => {
    return targetUnit === 'in' ? unitConversion.cmToIn(cm) : cm;
  },
};
