import { expect, afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';
import * as matchers from '@testing-library/jest-dom/matchers';

// Add jest-dom matchers
expect.extend(matchers);

// Mock CSS imports
vi.mock('*.css', () => ({}));
vi.mock('*.scss', () => ({}));

// Mock lucide-react icons with a fallback
vi.mock('lucide-react', () => {
  const mockIcon = () => 'Icon';
  return new Proxy({}, {
    get: () => mockIcon,
  });
});


