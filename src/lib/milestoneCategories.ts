export interface MilestoneTemplate {
  title: string;
  description: string;
  typicalAgeMonths: number;
  ageRangeMonths: [number, number];
}

export interface MilestoneCategory {
  type: string;
  label: string;
  icon: string;
  milestones: MilestoneTemplate[];
}

export const milestoneCategories: MilestoneCategory[] = [
  {
    type: 'motor',
    label: 'Physical & Motor',
    icon: '🏃',
    milestones: [
      {
        title: 'Holds head up',
        description: 'Can lift head during tummy time',
        typicalAgeMonths: 1,
        ageRangeMonths: [0.5, 3],
      },
      {
        title: 'Rolls over',
        description: 'Rolls from tummy to back or vice versa',
        typicalAgeMonths: 4,
        ageRangeMonths: [3, 6],
      },
      {
        title: 'Sits without support',
        description: 'Can sit independently',
        typicalAgeMonths: 6,
        ageRangeMonths: [4, 8],
      },
      {
        title: 'Crawls',
        description: 'Moves forward on hands and knees',
        typicalAgeMonths: 8,
        ageRangeMonths: [6, 10],
      },
      {
        title: 'Stands holding on',
        description: 'Pulls to stand using furniture',
        typicalAgeMonths: 9,
        ageRangeMonths: [7, 12],
      },
      {
        title: 'First steps',
        description: 'Takes first independent steps',
        typicalAgeMonths: 12,
        ageRangeMonths: [9, 18],
      },
    ],
  },
  {
    type: 'communication',
    label: 'Communication',
    icon: '💬',
    milestones: [
      {
        title: 'First smile',
        description: 'Social smile in response to others',
        typicalAgeMonths: 2,
        ageRangeMonths: [1, 3],
      },
      {
        title: 'Laughs',
        description: 'Laughs out loud',
        typicalAgeMonths: 4,
        ageRangeMonths: [3, 6],
      },
      {
        title: 'Babbles',
        description: 'Makes babbling sounds (ba-ba, da-da)',
        typicalAgeMonths: 6,
        ageRangeMonths: [4, 8],
      },
      {
        title: 'Says "mama" or "dada"',
        description: 'First meaningful words',
        typicalAgeMonths: 10,
        ageRangeMonths: [8, 14],
      },
      {
        title: 'First word',
        description: 'Says a word with meaning',
        typicalAgeMonths: 12,
        ageRangeMonths: [9, 15],
      },
    ],
  },
  {
    type: 'social',
    label: 'Social & Emotional',
    icon: '❤️',
    milestones: [
      {
        title: 'Recognizes parents',
        description: 'Shows recognition of familiar faces',
        typicalAgeMonths: 3,
        ageRangeMonths: [2, 4],
      },
      {
        title: 'Stranger anxiety',
        description: 'Shows wariness of strangers',
        typicalAgeMonths: 8,
        ageRangeMonths: [6, 12],
      },
      {
        title: 'Plays peek-a-boo',
        description: 'Engages in simple games',
        typicalAgeMonths: 9,
        ageRangeMonths: [7, 12],
      },
    ],
  },
  {
    type: 'feeding',
    label: 'Eating & Feeding',
    icon: '🍼',
    milestones: [
      {
        title: 'First solid food',
        description: 'Tries first puree or baby food',
        typicalAgeMonths: 6,
        ageRangeMonths: [4, 7],
      },
      {
        title: 'Finger foods',
        description: 'Picks up food with fingers',
        typicalAgeMonths: 9,
        ageRangeMonths: [7, 11],
      },
      {
        title: 'Uses spoon',
        description: 'Attempts to use spoon independently',
        typicalAgeMonths: 15,
        ageRangeMonths: [12, 18],
      },
    ],
  },
  {
    type: 'other',
    label: 'Other',
    icon: '⭐',
    milestones: [],
  },
];
