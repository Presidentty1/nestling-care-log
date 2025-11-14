export interface VaccineScheduleItem {
  name: string;
  description: string;
  recommendedAgeWeeks: number;
  windowStartWeeks: number;
  windowEndWeeks: number;
  doseNumber?: number;
  required: boolean;
}

export const CDCVaccineSchedule: VaccineScheduleItem[] = [
  {
    name: 'Hepatitis B',
    description: 'HepB - First dose',
    recommendedAgeWeeks: 0,
    windowStartWeeks: 0,
    windowEndWeeks: 1,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'Hepatitis B',
    description: 'HepB - Second dose',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 4,
    windowEndWeeks: 12,
    doseNumber: 2,
    required: true,
  },
  {
    name: 'DTaP',
    description: 'Diphtheria, Tetanus, Pertussis',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 6,
    windowEndWeeks: 10,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'DTaP',
    description: 'Diphtheria, Tetanus, Pertussis',
    recommendedAgeWeeks: 16,
    windowStartWeeks: 14,
    windowEndWeeks: 18,
    doseNumber: 2,
    required: true,
  },
  {
    name: 'DTaP',
    description: 'Diphtheria, Tetanus, Pertussis',
    recommendedAgeWeeks: 24,
    windowStartWeeks: 22,
    windowEndWeeks: 26,
    doseNumber: 3,
    required: true,
  },
  {
    name: 'Hib',
    description: 'Haemophilus influenzae type b',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 6,
    windowEndWeeks: 10,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'Hib',
    description: 'Haemophilus influenzae type b',
    recommendedAgeWeeks: 16,
    windowStartWeeks: 14,
    windowEndWeeks: 18,
    doseNumber: 2,
    required: true,
  },
  {
    name: 'Hib',
    description: 'Haemophilus influenzae type b',
    recommendedAgeWeeks: 24,
    windowStartWeeks: 22,
    windowEndWeeks: 26,
    doseNumber: 3,
    required: true,
  },
  {
    name: 'Pneumococcal',
    description: 'PCV - Pneumococcal conjugate',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 6,
    windowEndWeeks: 10,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'Pneumococcal',
    description: 'PCV - Pneumococcal conjugate',
    recommendedAgeWeeks: 16,
    windowStartWeeks: 14,
    windowEndWeeks: 18,
    doseNumber: 2,
    required: true,
  },
  {
    name: 'Pneumococcal',
    description: 'PCV - Pneumococcal conjugate',
    recommendedAgeWeeks: 24,
    windowStartWeeks: 22,
    windowEndWeeks: 26,
    doseNumber: 3,
    required: true,
  },
  {
    name: 'Polio',
    description: 'IPV - Inactivated poliovirus',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 6,
    windowEndWeeks: 10,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'Polio',
    description: 'IPV - Inactivated poliovirus',
    recommendedAgeWeeks: 16,
    windowStartWeeks: 14,
    windowEndWeeks: 18,
    doseNumber: 2,
    required: true,
  },
  {
    name: 'Rotavirus',
    description: 'RV - Rotavirus vaccine',
    recommendedAgeWeeks: 8,
    windowStartWeeks: 6,
    windowEndWeeks: 15,
    doseNumber: 1,
    required: true,
  },
  {
    name: 'Rotavirus',
    description: 'RV - Rotavirus vaccine',
    recommendedAgeWeeks: 16,
    windowStartWeeks: 14,
    windowEndWeeks: 32,
    doseNumber: 2,
    required: true,
  },
];

export function getUpcomingVaccines(
  dateOfBirth: string,
  completedVaccines: Array<{ vaccine_name: string; vaccine_dose?: string }>
): VaccineScheduleItem[] {
  const birthDate = new Date(dateOfBirth);
  const now = new Date();
  const ageInWeeks = Math.floor((now.getTime() - birthDate.getTime()) / (7 * 24 * 60 * 60 * 1000));

  return CDCVaccineSchedule.filter(vaccine => {
    // Check if already completed
    const isCompleted = completedVaccines.some(
      cv => cv.vaccine_name === vaccine.name && 
      (vaccine.doseNumber ? cv.vaccine_dose?.includes(`${vaccine.doseNumber}`) : true)
    );

    if (isCompleted) return false;

    // Show if within window or upcoming soon (within 4 weeks)
    return vaccine.recommendedAgeWeeks <= ageInWeeks + 4;
  }).sort((a, b) => a.recommendedAgeWeeks - b.recommendedAgeWeeks);
}
