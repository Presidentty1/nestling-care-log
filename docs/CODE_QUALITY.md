# Code Quality Guidelines

## Overview
This project maintains high code quality standards through automated linting, formatting, and type checking.

## Tools

### ESLint (JavaScript/TypeScript)
- **Configuration**: `eslint.config.js`
- **Rules**: TypeScript strict, React best practices, import optimization
- **Command**: `npm run lint`

### Prettier (Code Formatting)
- **Configuration**: `.prettierrc`
- **Rules**: Consistent formatting, 100 char line width, single quotes
- **Commands**:
  - `npm run format` - Format all files
  - `npm run format:check` - Check formatting without changes

### TypeScript (Type Checking)
- **Configuration**: `tsconfig.json`
- **Command**: `npm run type-check`

### SwiftLint (Swift/iOS)
- **Configuration**: `ios/.swiftlint.yml`
- **Rules**: Swift best practices, custom project rules
- **Command**: `npm run lint:swift` (requires SwiftLint installation)

### Husky (Git Hooks)
- **Pre-commit**: Runs all linting and formatting checks
- **Commit-msg**: Validates commit message format
- **Location**: `.husky/`

## Development Workflow

### Before Committing
All checks run automatically via pre-commit hooks. To run manually:

```bash
# Run all checks
npm run lint
npm run format:check
npm run type-check
npm run lint:swift  # (if SwiftLint installed)

# Or run all at once (what pre-commit does)
./.husky/pre-commit
```

### Fixing Issues
```bash
# Auto-fix ESLint issues
npm run lint:fix

# Format code
npm run format
```

## Rules Summary

### ESLint Rules
- **TypeScript**: Strict typing, no `any`, consistent imports
- **React**: Hooks rules, component optimization
- **Code Quality**: No unused vars, prefer const, no debugger

### Prettier Rules
- **Line Width**: 100 characters
- **Quotes**: Single quotes for JS/TS, double for JSX
- **Semicolons**: Required
- **Trailing Commas**: ES5 style

### SwiftLint Rules
- **Custom Rules**: Discourage force unwrapping, encourage type imports
- **Line Length**: 120 chars (warning), 150 (error)
- **Complexity**: Cyclomatic complexity limits

## Continuous Integration
- Pre-commit hooks prevent commits with linting errors
- CI/CD should run: `npm run lint && npm run format:check && npm run type-check`

## Installation

### SwiftLint (macOS)
```bash
brew install swiftlint
```

### Husky Hooks
```bash
npm run prepare  # Sets up git hooks
```

## Troubleshooting

### Pre-commit Hook Failing
1. Run checks manually to identify issues
2. Fix linting errors with `npm run lint:fix`
3. Format code with `npm run format`
4. Commit again

### SwiftLint Not Found
- Install SwiftLint: `brew install swiftlint`
- Or comment out SwiftLint in `.husky/pre-commit` if not needed

### ESLint Configuration Issues
- Check `eslint.config.js` for rule conflicts
- Use `npx eslint --print-config file.js` to debug




