#!/bin/bash

# Direct iPhone Device Log Streamer
# Streams logs directly from your connected iPhone

set -e

BUNDLE_ID="${1:-com.nuzzle.Nuzzle}"
FILTER="${2:-}"

echo "📱 Streaming logs from your iPhone 17 Pro"
echo "   Bundle ID: $BUNDLE_ID"
if [ -n "$FILTER" ]; then
    echo "   Filter: $FILTER"
fi
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Use macOS unified logging to stream from connected device
# This works best when device is connected via Core Device (wireless) or USB

if [ -n "$FILTER" ]; then
    log stream --predicate "processImagePath contains '${BUNDLE_ID}'" --style compact | grep -i --color=always "$FILTER"
else
    log stream --predicate "processImagePath contains '${BUNDLE_ID}'" --style compact
fi


