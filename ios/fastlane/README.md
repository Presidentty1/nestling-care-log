# Fastlane Configuration

This directory contains Fastlane configuration for automated iOS builds and deployments.

## Setup

1. Install Fastlane:

   ```bash
   gem install fastlane
   ```

2. Install dependencies:

   ```bash
   cd ios
   bundle install
   ```

3. Configure your App Store Connect credentials:
   ```bash
   fastlane match init
   ```

## Available Lanes

### Testing

- `fastlane test` - Run unit tests and UI tests

### Building

- `fastlane beta` - Build and upload to TestFlight
- `fastlane release` - Build and submit to App Store

### Utilities

- `fastlane certificates` - Set up code signing certificates
- `fastlane screenshots` - Generate app screenshots

## Configuration Files

- `Fastfile` - Lane definitions and build logic
- `Appfile` - App Store Connect configuration
- `Matchfile` - Code signing configuration (created during setup)

## CI/CD Integration

These lanes are designed to work with GitHub Actions. See `.github/workflows/ios-ci.yml` for the CI configuration.

## Environment Variables

Set these in your CI environment:

- `MATCH_PASSWORD` - Match repository password
- `FASTLANE_APPLE_ID` - Apple ID for App Store Connect
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` - App-specific password
- `FASTLANE_TEAM_ID` - Developer team ID

