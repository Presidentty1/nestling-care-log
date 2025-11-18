// Simplified WHO growth percentiles for boys and girls
// In production, use complete WHO datasets or API

interface PercentileData {
  p3: number;
  p15: number;
  p50: number;
  p85: number;
  p97: number;
}

// Sample boy weight percentiles (kg) by age in days
const boyWeightPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.4 },
  30: { p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.1, p97: 5.8 },
  60: { p3: 4.3, p15: 4.9, p50: 5.6, p85: 6.3, p97: 7.1 },
  90: { p3: 5.0, p15: 5.7, p50: 6.4, p85: 7.2, p97: 8.0 },
  180: { p3: 6.4, p15: 7.1, p50: 7.9, p85: 8.8, p97: 9.8 },
  365: { p3: 7.7, p15: 8.6, p50: 9.6, p85: 10.8, p97: 11.9 },
};

// Sample girl weight percentiles (kg) by age in days
const girlWeightPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 2.4, p15: 2.8, p50: 3.2, p85: 3.7, p97: 4.2 },
  30: { p3: 3.2, p15: 3.6, p50: 4.2, p85: 4.8, p97: 5.5 },
  60: { p3: 3.9, p15: 4.5, p50: 5.1, p85: 5.8, p97: 6.6 },
  90: { p3: 4.5, p15: 5.1, p50: 5.8, p85: 6.6, p97: 7.5 },
  180: { p3: 5.7, p15: 6.5, p50: 7.3, p85: 8.2, p97: 9.3 },
  365: { p3: 7.0, p15: 7.9, p50: 8.9, p85: 10.1, p97: 11.2 },
};

// Sample boy length percentiles (cm) by age in days
const boyLengthPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 46.1, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.7 },
  30: { p3: 50.8, p15: 52.8, p50: 54.7, p85: 56.7, p97: 58.6 },
  60: { p3: 54.4, p15: 56.4, p50: 58.4, p85: 60.4, p97: 62.4 },
  90: { p3: 57.3, p15: 59.4, p50: 61.4, p85: 63.5, p97: 65.5 },
  180: { p3: 63.3, p15: 65.5, p50: 67.6, p85: 69.8, p97: 71.9 },
  365: { p3: 71.0, p15: 73.4, p50: 75.7, p85: 78.1, p97: 80.5 },
};

// Sample girl length percentiles (cm) by age in days
const girlLengthPercentiles: { [key: number]: PercentileData } = {
  0: { p3: 45.4, p15: 47.3, p50: 49.1, p85: 51.0, p97: 52.9 },
  30: { p3: 49.8, p15: 51.7, p50: 53.7, p85: 55.6, p97: 57.6 },
  60: { p3: 53.0, p15: 55.0, p50: 57.1, p85: 59.1, p97: 61.1 },
  90: { p3: 55.6, p15: 57.8, p50: 59.8, p85: 61.9, p97: 64.0 },
  180: { p3: 61.8, p15: 64.0, p50: 66.1, p85: 68.3, p97: 70.4 },
  365: { p3: 68.9, p15: 71.4, p50: 73.7, p85: 76.0, p97: 78.4 },
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
  const data = sex === 'male' ? boyWeightPercentiles : girlWeightPercentiles;
  const percentiles = interpolate(ageInDays, data);
  return Math.round(calculatePercentile(weight, percentiles));
}

export function calculateLengthPercentile(
  ageInDays: number,
  sex: 'male' | 'female',
  length: number
): number {
  const data = sex === 'male' ? boyLengthPercentiles : girlLengthPercentiles;
  const percentiles = interpolate(ageInDays, data);
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
  const data = sex === 'male' ? boyWeightPercentiles : girlWeightPercentiles;
  const percentiles = interpolate(ageInDays, data);
  
  if (percentile <= 3) return percentiles.p3;
  if (percentile <= 15) return percentiles.p15;
  if (percentile <= 50) return percentiles.p50;
  if (percentile <= 85) return percentiles.p85;
  return percentiles.p97;
}
