#!/bin/bash
# Get logs from connected iPhone device

DEVICE_ID="00008150-001034AE3CB8401C"
BUNDLE_ID="com.lovable.nestlingcarelog"

echo "=== Getting logs from Ty's iPhone 17 Pro ==="
echo "Device ID: $DEVICE_ID"
echo "Bundle ID: $BUNDLE_ID"
echo ""

echo "--- Method 1: Console App Logs (Last 2 minutes) ---"
log show --predicate "processImagePath contains 'App' AND (eventMessage contains 'Error' OR eventMessage contains 'error' OR eventMessage contains 'Failed' OR eventMessage contains '404' OR eventMessage contains 'JavaScript' OR eventMessage contains 'Capacitor')" --last 2m --style syslog 2>/dev/null | grep -i -E "app|nestling|capacitor|error|failed|404|javascript" | tail -50

echo ""
echo "--- Method 2: Device Console (if available) ---"
echo "To see live logs, run this command:"
echo "log stream --device $DEVICE_ID --predicate 'subsystem contains \"$BUNDLE_ID\" OR processImagePath contains \"App\"' --level debug"
echo ""
echo "--- Method 3: Xcode Console (Best) ---"
echo "1. In Xcode, make sure app is running"
echo "2. Press Cmd+Shift+Y to open Debug Area"
echo "3. Look at bottom console for errors"
echo ""
echo "--- Method 4: Safari Web Inspector (Best for Web) ---"
echo "1. Connect iPhone via USB"
echo "2. Safari → Develop → [Your iPhone] → nestling-care-log"
echo "3. Check Console and Network tabs"
