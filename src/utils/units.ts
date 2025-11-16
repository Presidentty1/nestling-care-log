const ML_PER_OZ = 29.5735;

export function mlToOz(ml: number): number {
  return Math.round((ml / ML_PER_OZ) * 10) / 10;
}

export function ozToMl(oz: number): number {
  return Math.round(oz * ML_PER_OZ * 10) / 10;
}

export function convertAmount(amount: number, fromUnit: 'ml' | 'oz', toUnit: 'ml' | 'oz'): number {
  if (fromUnit === toUnit) return amount;
  return fromUnit === 'ml' ? mlToOz(amount) : ozToMl(amount);
}

export function formatAmount(amount: number, unit: 'ml' | 'oz'): string {
  return `${amount}${unit}`;
}
