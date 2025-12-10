# SwiftLint Setup Instructions

SwiftLint is optional but recommended for iOS development. It provides automated Swift code linting to maintain code quality.

## Installation

### Option 1: Homebrew (Recommended)

```bash
# Fix Homebrew permissions if needed
sudo chown -R $(whoami) /usr/local/share/man/man8
chmod u+w /usr/local/share/man/man8

# Install SwiftLint
brew install swiftlint
```

### Option 2: CocoaPods

Add to your `Podfile`:

```ruby
pod 'SwiftLint'
```

Then run:

```bash
pod install
```

### Option 3: Mint

```bash
mint install realm/SwiftLint
```

### Option 4: Download Binary

Download the latest release from:
https://github.com/realm/SwiftLint/releases

Extract and move to `/usr/local/bin`:

```bash
unzip SwiftLint-darwin.zip
sudo mv swiftlint /usr/local/bin/
```

## Verification

After installation, verify it works:

```bash
swiftlint version
```

## Configuration

SwiftLint is already configured in this project:

- `.swiftlint.yml` - Root configuration
- `ios/.swiftlint.yml` - iOS-specific configuration

## Usage

The pre-commit hook will automatically skip SwiftLint if it's not installed, so installation is optional. However, to lint Swift code manually:

```bash
npm run lint:swift
```

Or directly:

```bash
swiftlint --config ios/.swiftlint.yml
```

## Pre-commit Hook

The pre-commit hook checks for SwiftLint installation and:

- **If installed**: Runs SwiftLint on Swift files
- **If not installed**: Skips with a warning message

You can still commit without SwiftLint installed.
