import { useState, useEffect } from 'react';

export function useDismissibleBanner(key: string) {
  const [isDismissed, setIsDismissed] = useState(() => {
    try {
      return localStorage.getItem(`banner_dismissed_${key}`) === 'true';
    } catch {
      return false;
    }
  });

  const dismiss = () => {
    setIsDismissed(true);
    try {
      localStorage.setItem(`banner_dismissed_${key}`, 'true');
    } catch (error) {
      console.error('Failed to save banner state:', error);
    }
  };

  return { isDismissed, dismiss };
}
