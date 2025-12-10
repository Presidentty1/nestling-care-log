# 📱 iOS/Xcode Log Viewing Guide

This guide explains how to view and stream logs from iOS simulators and devices during development.

## Quick Start

### Stream Logs from Simulator

```bash
# Basic usage - streams all logs from running simulator
npm run ios:logs

# Save logs to file
npm run ios:logs:save

# Or use the script directly
./scripts/xcode-logs.sh
```

## Detailed Usage

### Available Options

```bash
./scripts/xcode-logs.sh [OPTIONS]
```

**Options:**

- `-b, --bundle-id ID` - Filter logs by bundle identifier (default: `com.nuzzle.Nuzzle`)
- `-o, --output FILE` - Save logs to a file
- `-t, --type TYPE` - Device type: `auto`, `simulator`, `device` (default: `auto`)
- `-l, --level LEVEL` - Log level: `default`, `debug`, `info`, `error` (default: `default`)
- `-f, --filter TEXT` - Filter logs by text pattern (case-insensitive)
- `-h, --help` - Show help message

### Examples

**Stream all logs from running simulator:**

```bash
npm run ios:logs
```

**Filter logs by bundle ID:**

```bash
./scripts/xcode-logs.sh -b com.nuzzle.Nuzzle
```

**Stream only error logs:**

```bash
./scripts/xcode-logs.sh -l error
```

**Filter for specific text pattern:**

```bash
./scripts/xcode-logs.sh -f "NetworkError"
```

**Save filtered logs to file:**

```bash
./scripts/xcode-logs.sh -l error -f "Error" -o error-logs.txt
```

**Stream from simulator only:**

```bash
./scripts/xcode-logs.sh -t simulator
```

## How It Works

### Simulator Logs

- Automatically detects running iOS simulators
- Uses `xcrun simctl spawn booted log stream` to stream logs
- Provides real-time log output with color coding
- Supports filtering by process, log level, and text patterns

### Device Logs

- Detects connected physical devices
- **Note:** Device log streaming has limitations
- **Recommended:** Use Xcode Console for best results with physical devices

## Alternative Methods

### Xcode Console

1. Open your project in Xcode
2. Run the app on simulator/device
3. View logs in the bottom console pane
4. Filter by process or search text

### Xcode Devices Window

1. Xcode → Window → Devices and Simulators
2. Select your device
3. Click "Open Console" or "View Device Logs"
4. Filter by app bundle identifier

### Console.app (macOS)

1. Open Console.app (Applications → Utilities)
2. Select your device from the sidebar
3. Filter by process name or search text
4. Real-time streaming available

## Tips

1. **Start simulator first**: Boot a simulator before running the log script

   ```bash
   # Boot a specific simulator
   xcrun simctl boot <UDID>

   # Or open Simulator app and boot from there
   open -a Simulator
   ```

2. **Filter for your app**: Use bundle ID to see only your app's logs

   ```bash
   ./scripts/xcode-logs.sh -b com.nuzzle.Nuzzle
   ```

3. **Save important logs**: Redirect to file for later analysis

   ```bash
   ./scripts/xcode-logs.sh -o debug-session-$(date +%Y%m%d-%H%M%S).txt
   ```

4. **Combine filters**: Use multiple filters for precise log viewing

   ```bash
   ./scripts/xcode-logs.sh -l error -f "Crash" -b com.nuzzle.Nuzzle
   ```

5. **Stop streaming**: Press `Ctrl+C` to stop the log stream

## Troubleshooting

### "No running simulator found"

- Boot a simulator first: `open -a Simulator` or boot from Xcode
- Or specify a simulator to boot:

  ```bash
  # List available simulators
  xcrun simctl list devices available

  # Boot a specific simulator
  xcrun simctl boot <UDID>
  ```

### "xcrun not found"

- Install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

### Logs not showing

- Ensure the app is running on the simulator/device
- Check that the bundle ID is correct
- Try removing filters to see all logs first

### Device logs not working

- Device log streaming requires proper Xcode setup
- **Recommended:** Use Xcode Console for physical devices
- Ensure device is trusted and connected via USB

## Integration with Development Workflow

### During Development

```bash
# Terminal 1: Start dev server
npm run dev

# Terminal 2: Stream logs
npm run ios:logs

# Terminal 3: Run app from Xcode or use hot-reload
```

### Debugging Session

```bash
# Stream only errors and save to file
./scripts/xcode-logs.sh -l error -o errors.txt

# In another terminal, reproduce the issue
# Errors will be captured in errors.txt
```

### CI/CD

```bash
# Save all logs during test run
npm run ios:logs:save &
LOG_PID=$!

# Run your tests
xcodebuild test ...

# Stop log capture
kill $LOG_PID
```

## See Also

- [DEVELOPMENT.md](../DEVELOPMENT.md) - General development setup
- [ios/README.md](../ios/README.md) - iOS-specific documentation
- [Xcode Documentation](https://developer.apple.com/documentation/xcode) - Official Xcode docs
