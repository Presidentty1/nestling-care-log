# Contributing to Nestling

Thank you for your interest in contributing to Nestling! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/nestling.git`
3. Install dependencies: `npm install`
4. Create a branch: `git checkout -b feature/your-feature-name`

## Development Setup

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm run test
npm run test:e2e

# Build for production
npm run build
```

## Code Style

We use ESLint and Prettier for code formatting:

```bash
# Check linting
npm run lint

# Auto-fix issues
npm run lint --fix
```

### TypeScript

- Use TypeScript for all new code
- Define proper types - avoid `any`
- Use interfaces for object shapes
- Export types from `types/` directory

### React

- Use functional components with hooks
- Prefer composition over inheritance
- Keep components small and focused
- Use semantic HTML elements

### Naming Conventions

- Components: PascalCase (`BabySelector.tsx`)
- Hooks: camelCase with `use` prefix (`useEventLogger.ts`)
- Utilities: camelCase (`time.ts`)
- Constants: UPPER_SNAKE_CASE

## Project Structure

```
src/
├── components/      # React components
│   ├── common/     # Shared components
│   ├── sheets/     # Bottom sheet forms
│   ├── today/      # Today screen components
│   ├── history/    # History screen components
│   └── ui/         # Base UI components (shadcn)
├── hooks/          # Custom React hooks
├── pages/          # Route pages
├── services/       # Business logic & data services
├── store/          # Zustand state management
├── types/          # TypeScript type definitions
├── lib/            # Utility libraries
└── utils/          # Helper functions
```

## Making Changes

### Before You Start

1. Check existing issues for similar work
2. Create an issue to discuss major changes
3. Comment on the issue if you want to work on it

### Development Process

1. **Write tests first** (TDD approach)
   ```typescript
   // Write failing test
   test('should format duration', () => {
     expect(formatDuration(90)).toBe('1h 30m');
   });
   
   // Implement feature
   export function formatDuration(min: number): string {
     // implementation
   }
   ```

2. **Implement the feature**
   - Follow existing patterns
   - Keep functions pure when possible
   - Add JSDoc comments for complex logic

3. **Test thoroughly**
   - Unit tests for logic
   - E2E tests for user flows
   - Manual testing on mobile viewport

4. **Update documentation**
   - Add/update JSDoc comments
   - Update README if needed
   - Add inline comments for complex code

### Commit Messages

Use conventional commits:

```
feat: add nap prediction feedback
fix: correct duration calculation across midnight
docs: update testing guide
style: format time service
refactor: extract sheet frame component
test: add E2E tests for history page
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

## Testing

### Unit Tests

Required for:
- Utility functions
- Data transformations
- Business logic
- Hooks (when possible)

```typescript
import { describe, it, expect } from 'vitest';

describe('formatDuration', () => {
  it('formats hours and minutes', () => {
    expect(formatDuration(90)).toBe('1h 30m');
  });
  
  it('formats minutes only', () => {
    expect(formatDuration(45)).toBe('45m');
  });
});
```

### E2E Tests

Required for:
- User flows
- Critical features
- Bug fixes

```typescript
import { test, expect } from '@playwright/test';

test('should log a feed', async ({ page }) => {
  await page.goto('/home');
  // Test implementation
});
```

## Accessibility

All contributions must maintain WCAG 2.1 AA compliance:

- Use semantic HTML
- Add ARIA labels to icon buttons
- Ensure 4.5:1 color contrast
- Support keyboard navigation
- Test with screen readers
- Maintain 44px minimum touch targets

## Performance

Target metrics:
- LCP < 2.5s
- FID < 100ms
- CLS < 0.1
- Time to Interactive < 3.5s

Use performance hooks:
```typescript
import { usePerformance } from '@/hooks/usePerformance';

function MyComponent() {
  usePerformance('MyComponent');
  // component code
}
```

## Pull Request Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase main
   ```

2. **Run checks**
   ```bash
   npm run lint
   npm run test
   npm run test:e2e
   npm run build
   ```

3. **Create PR**
   - Use descriptive title
   - Reference related issues
   - Add screenshots for UI changes
   - List manual testing performed

4. **PR Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   
   ## Testing
   - [ ] Unit tests added/updated
   - [ ] E2E tests added/updated
   - [ ] Manually tested on mobile
   
   ## Screenshots
   (if applicable)
   ```

5. **Review Process**
   - Address review comments
   - Keep PR focused and small
   - Respond within 24-48 hours

## Common Issues

### IndexedDB in Tests

Always clear between tests:
```typescript
test.beforeEach(async ({ page }) => {
  await page.evaluate(() => {
    indexedDB.deleteDatabase('nestling');
  });
});
```

### Type Errors

Import types correctly:
```typescript
import type { Baby, EventRecord } from '@/types/events';
```

### Mobile Viewport

Test on mobile sizes:
```bash
npx playwright test --project="Mobile Chrome"
```

## Code Review Checklist

Before submitting, verify:

- [ ] Code follows style guide
- [ ] Tests pass locally
- [ ] No console errors
- [ ] Accessibility maintained
- [ ] Performance not degraded
- [ ] Types properly defined
- [ ] Documentation updated
- [ ] No hardcoded values
- [ ] Error handling added
- [ ] Edge cases considered

## Getting Help

- Check [README.md](README.md) for setup
- Review existing code for patterns
- Ask questions in PR comments
- Open an issue for discussion

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be added to the README and release notes. Thank you for helping make Nestling better!
