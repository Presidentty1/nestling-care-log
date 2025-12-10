import { useEffect } from 'react';

export function useKeyboardShortcuts(shortcuts: Record<string, () => void>) {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Ignore if user is typing in an input/textarea
      const target = event.target as HTMLElement;
      const isInput = ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName);

      // Escape key
      if (event.key === 'Escape' && shortcuts.escape) {
        shortcuts.escape();
      }

      // Ctrl/Cmd+N for new event
      if ((event.metaKey || event.ctrlKey) && event.key === 'n' && !isInput && shortcuts.newEvent) {
        event.preventDefault();
        shortcuts.newEvent();
      }

      // Enter to submit forms (handled by forms themselves)
      if (event.key === 'Enter' && !event.shiftKey && shortcuts.submit && !isInput) {
        event.preventDefault();
        shortcuts.submit();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [shortcuts]);
}
