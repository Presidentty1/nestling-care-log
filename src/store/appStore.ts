import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  activeBabyId: string | null;
  caregiverMode: boolean;
  setActiveBabyId: (id: string | null) => void;
  setCaregiverMode: (enabled: boolean) => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      activeBabyId: null,
      caregiverMode: false,
      setActiveBabyId: (id) => set({ activeBabyId: id }),
      setCaregiverMode: (enabled) => set({ caregiverMode: enabled }),
    }),
    {
      name: 'nestling-app-store',
    }
  )
);
