#!/bin/bash
# Script to capture iOS app logs

echo "=== Capturing App Logs ==="
echo ""

# Method 1: Console app logs
echo "--- Recent System Logs (App related) ---"
log show --predicate 'processImagePath contains "App" OR subsystem contains "com.lovable" OR eventMessage contains "Capacitor" OR eventMessage contains "Error" OR eventMessage contains "error" OR eventMessage contains "Failed"' --last 2m --style syslog 2>/dev/null | tail -100

echo ""
echo "--- Checking for JavaScript Errors ---"
log show --predicate 'eventMessage contains "JavaScript" OR eventMessage contains "JS" OR eventMessage contains "console.error" OR eventMessage contains "Uncaught"' --last 2m --style syslog 2>/dev/null | tail -50

echo ""
echo "--- Checking for Network/Asset Loading Issues ---"
log show --predicate 'eventMessage contains "404" OR eventMessage contains "Failed to load" OR eventMessage contains "network" OR eventMessage contains "HTTP"' --last 2m --style syslog 2>/dev/null | tail -50

echo ""
echo "=== To see live logs, run: ==="
echo "log stream --predicate 'processImagePath contains \"App\"' --level debug"
