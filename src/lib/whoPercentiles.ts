// Simplified WHO percentile calculator
// In production, would use full LMS tables or WHO API

interface PercentileData {
  p3: number;
  p15: number;
  p50: number;
  p85: number;
  p97: number;
}

// Simplified weight percentiles (kg) for first 12 months - boys
const boyWeightPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.3 },
  30: { p3: 3.6, p15: 4.3, p50: 4.9, p85: 5.7, p97: 6.3 },
  60: { p3: 4.8, p15: 5.6, p50: 6.4, p85: 7.4, p97: 8.2 },
  90: { p3: 5.7, p15: 6.6, p50: 7.5, p85: 8.6, p97: 9.6 },
  180: { p3: 7.4, p15: 8.4, p50: 9.6, p85: 11.0, p97: 12.2 },
  270: { p3: 8.4, p15: 9.6, p50: 10.9, p85: 12.5, p97: 13.9 },
  365: { p3: 9.0, p15: 10.3, p50: 11.8, p85: 13.5, p97: 15.0 },
};

// Simplified length percentiles (cm) for first 12 months - boys
const boyLengthPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 46.3, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.4 },
  30: { p3: 51.1, p15: 53.0, p50: 55.0, p85: 57.1, p97: 58.9 },
  60: { p3: 55.3, p15: 57.4, p50: 59.6, p85: 61.8, p97: 63.8 },
  90: { p3: 58.5, p15: 60.7, p50: 63.0, p85: 65.3, p97: 67.4 },
  180: { p3: 66.5, p15: 68.9, p50: 71.3, p85: 73.9, p97: 76.1 },
  270: { p3: 71.3, p15: 73.9, p50: 76.5, p85: 79.2, p97: 81.7 },
  365: { p3: 74.5, p15: 77.1, p50: 79.9, p85: 82.7, p97: 85.3 },
};

function interpolate(age: number, data: { [key: number]: PercentileData }): PercentileData {
  const ages = Object.keys(data).map(Number).sort((a, b) => a - b);
  
  // Find surrounding ages
  let lowerAge = ages[0];
  let upperAge = ages[ages.length - 1];
  
  for (let i = 0; i < ages.length - 1; i++) {
    if (age >= ages[i] && age <= ages[i + 1]) {
      lowerAge = ages[i];
      upperAge = ages[i + 1];
      break;
    }
  }
  
  if (age <= lowerAge) return data[lowerAge];
  if (age >= upperAge) return data[upperAge];
  
  const ratio = (age - lowerAge) / (upperAge - lowerAge);
  const lower = data[lowerAge];
  const upper = data[upperAge];
  
  return {
    p3: lower.p3 + (upper.p3 - lower.p3) * ratio,
    p15: lower.p15 + (upper.p15 - lower.p15) * ratio,
    p50: lower.p50 + (upper.p50 - lower.p50) * ratio,
    p85: lower.p85 + (upper.p85 - lower.p85) * ratio,
    p97: lower.p97 + (upper.p97 - lower.p97) * ratio,
  };
}

function calculatePercentile(value: number, percentiles: PercentileData): number {
  if (value <= percentiles.p3) return 3;
  if (value <= percentiles.p15) {
    return 3 + ((value - percentiles.p3) / (percentiles.p15 - percentiles.p3)) * 12;
  }
  if (value <= percentiles.p50) {
    return 15 + ((value - percentiles.p15) / (percentiles.p50 - percentiles.p15)) * 35;
  }
  if (value <= percentiles.p85) {
    return 50 + ((value - percentiles.p50) / (percentiles.p85 - percentiles.p50)) * 35;
  }
  if (value <= percentiles.p97) {
    return 85 + ((value - percentiles.p85) / (percentiles.p97 - percentiles.p85)) * 12;
  }
  return 97;
}

export function calculateWeightPercentile(
  ageInDays: number,
  sex: 'male' | 'female',
  weight: number
): number {
  // For now, only boys data - in production would have both
  const percentiles = interpolate(ageInDays, boyWeightPercentiles);
  return Math.round(calculatePercentile(weight, percentiles));
}

export function calculateLengthPercentile(
  ageInDays: number,
  sex: 'male' | 'female',
  length: number
): number {
  const percentiles = interpolate(ageInDays, boyLengthPercentiles);
  return Math.round(calculatePercentile(length, percentiles));
}

export function calculateHeadPercentile(
  ageInDays: number,
  sex: 'male' | 'female',
  headCirc: number
): number {
  // Simplified - return 50th percentile for now
  return 50;
}

export function getExpectedWeight(
  ageInDays: number,
  sex: 'male' | 'female',
  percentile: number
): number {
  const percentiles = interpolate(ageInDays, boyWeightPercentiles);
  
  if (percentile <= 3) return percentiles.p3;
  if (percentile <= 15) return percentiles.p15;
  if (percentile <= 50) return percentiles.p50;
  if (percentile <= 85) return percentiles.p85;
  return percentiles.p97;
}
