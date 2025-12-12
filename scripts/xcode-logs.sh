#!/bin/bash

# Xcode iOS Log Streamer
# Streams logs from iOS simulators and devices for debugging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUNDLE_ID="com.nuzzle.Nuzzle"
OUTPUT_FILE=""
DEVICE_TYPE="auto"  # auto, simulator, device
LOG_LEVEL="default"  # default, debug, info, error
FILTER=""

# Help message
show_help() {
    cat << EOF
📱 Xcode iOS Log Streamer

Streams logs from iOS simulators and physical devices.

Usage:
    ./scripts/xcode-logs.sh [OPTIONS]

Options:
    -b, --bundle-id ID       Bundle identifier to filter (default: com.nuzzle.Nuzzle)
    -o, --output FILE        Save logs to file (optional)
    -t, --type TYPE          Device type: auto, simulator, device (default: auto)
    -l, --level LEVEL        Log level: default, debug, info, error (default: default)
    -f, --filter TEXT        Filter logs by text pattern (case-insensitive)
    -h, --help               Show this help message

Examples:
    # Stream all logs from running simulator
    ./scripts/xcode-logs.sh

    # Stream only app logs with bundle ID
    ./scripts/xcode-logs.sh -b com.nuzzle.Nuzzle

    # Save logs to file
    ./scripts/xcode-logs.sh -o logs.txt

    # Filter for errors only
    ./scripts/xcode-logs.sh -l error

    # Filter by text pattern
    ./scripts/xcode-logs.sh -f "NetworkError"

    # Stream from specific device type
    ./scripts/xcode-logs.sh -t simulator

Notes:
    - If no device/simulator is running, the script will show available options
    - Press Ctrl+C to stop streaming
    - Logs are colorized for better readability
    - Simulator logs use 'xcrun simctl spawn booted log stream'
    - Device logs use 'xcrun devicectl device process monitor'

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -t|--type)
            DEVICE_TYPE="$2"
            shift 2
            ;;
        -l|--level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check if xcrun is available
if ! command -v xcrun &> /dev/null; then
    echo -e "${RED}❌ Error: xcrun not found. Please install Xcode Command Line Tools.${NC}"
    echo "Run: xcode-select --install"
    exit 1
fi

# Function to detect running simulators
get_running_simulator() {
    xcrun simctl list devices | grep -E "Booted" | head -1 | grep -oE "\([A-F0-9-]+\)" | tr -d "()" || echo ""
}

# Function to detect connected devices
get_connected_device() {
    xcrun devicectl list devices 2>/dev/null | grep -E "connected" | head -1 | awk '{print $1}' || echo ""
}

# Function to stream simulator logs
stream_simulator_logs() {
    local sim_udid="$1"
    
    echo -e "${BLUE}📱 Streaming logs from iOS Simulator${NC}"
    if [ -n "$BUNDLE_ID" ]; then
        echo -e "${BLUE}   Filtering for bundle: ${BUNDLE_ID}${NC}"
    fi
    if [ -n "$FILTER" ]; then
        echo -e "${BLUE}   Text filter: ${FILTER}${NC}"
    fi
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    # Use the unified logging system via log stream
    # This works for both simulator and provides better filtering
    
    # Build the base command
    local base_cmd="log stream"
    
    # Add predicate if bundle ID provided
    if [ -n "$BUNDLE_ID" ]; then
        base_cmd="$base_cmd --predicate 'processImagePath contains \"${BUNDLE_ID}\"'"
    fi
    
    # Add log level
    if [ "$LOG_LEVEL" != "default" ]; then
        base_cmd="$base_cmd --level $LOG_LEVEL"
    fi
    
    # Add style for readability
    base_cmd="$base_cmd --style compact"
    
    # For simulator, we spawn the log command inside the booted simulator
    local full_cmd="xcrun simctl spawn booted $base_cmd"
    
    # Add text filtering via grep if needed
    if [ -n "$FILTER" ]; then
        full_cmd="$full_cmd | grep -i --color=always \"$FILTER\""
    fi
    
    # Execute command with optional file output
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "${GREEN}💾 Saving logs to: $OUTPUT_FILE${NC}\n"
        eval "$full_cmd" 2>&1 | tee "$OUTPUT_FILE"
    else
        eval "$full_cmd" 2>&1
    fi
}

# Function to stream device logs
stream_device_logs() {
    local device_udid="$1"
    
    echo -e "${YELLOW}⚠️  Physical device log streaming has limitations${NC}\n"
    echo -e "${BLUE}Recommended approaches for device logs:${NC}"
    echo -e "1. ${GREEN}Xcode Console${NC}: Run app from Xcode and view logs in Console pane"
    echo -e "2. ${GREEN}Xcode Devices Window${NC}: Window → Devices and Simulators → Select device → View Device Logs"
    echo -e "3. ${GREEN}Console.app${NC}: Open Console.app → Select your device → Filter by process"
    echo -e "4. ${GREEN}WWDC Console${NC}: Use Console.app's device streaming feature"
    echo ""
    
    # Try using Console framework approach (requires device to be connected via Xcode)
    echo -e "${YELLOW}Attempting to stream device logs...${NC}"
    echo -e "${YELLOW}(This may not work for all devices. Use Xcode Console for best results.)${NC}\n"
    
    # Use the unified logging stream which works for connected devices
    # Note: This requires the device to be properly connected via Xcode
    local cmd="log stream"
    
    # Add bundle filter if provided
    if [ -n "$BUNDLE_ID" ]; then
        cmd="$cmd --predicate 'processImagePath contains \"${BUNDLE_ID}\"'"
    fi
    
    # Add log level
    if [ "$LOG_LEVEL" != "default" ]; then
        cmd="$cmd --level $LOG_LEVEL"
    fi
    
    cmd="$cmd --style compact"
    
    if [ -n "$FILTER" ]; then
        cmd="$cmd | grep -i --color=always \"$FILTER\""
    fi
    
    echo -e "${BLUE}💡 Tip: For better device log streaming, run the app from Xcode${NC}\n"
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "${GREEN}💾 Saving logs to: $OUTPUT_FILE${NC}\n"
        eval "$cmd" 2>&1 | tee "$OUTPUT_FILE"
    else
        eval "$cmd" 2>&1
    fi
}

# Main execution
main() {
    echo -e "${GREEN}🔍 Detecting iOS devices/simulators...${NC}\n"
    
    local running_sim=""
    local connected_device=""
    
    # Detect devices based on type preference
    if [ "$DEVICE_TYPE" = "auto" ] || [ "$DEVICE_TYPE" = "simulator" ]; then
        running_sim=$(get_running_simulator)
    fi
    
    if [ "$DEVICE_TYPE" = "auto" ] || [ "$DEVICE_TYPE" = "device" ]; then
        connected_device=$(get_connected_device)
    fi
    
    # Determine which device to use
    if [ -n "$running_sim" ]; then
        echo -e "${GREEN}✅ Found running simulator${NC}"
        stream_simulator_logs "$running_sim"
    elif [ -n "$connected_device" ]; then
        echo -e "${GREEN}✅ Found connected device${NC}"
        stream_device_logs "$connected_device"
    else
        echo -e "${RED}❌ No running simulator or connected device found${NC}\n"
        
        echo -e "${YELLOW}Available simulators:${NC}"
        xcrun simctl list devices available | grep -E "iPhone|iPad" | head -5
        echo ""
        
        echo -e "${YELLOW}To start a simulator:${NC}"
        echo "  1. Open Xcode"
        echo "  2. Xcode → Open Developer Tool → Simulator"
        echo "  3. Or run: xcrun simctl boot <UDID>"
        echo ""
        
        echo -e "${YELLOW}To boot a specific simulator:${NC}"
        local first_sim=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE "\([A-F0-9-]+\)" | tr -d "()")
        if [ -n "$first_sim" ]; then
            echo "  xcrun simctl boot $first_sim"
        fi
        echo ""
        
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}⏹️  Log streaming stopped${NC}"; exit 0' INT

# Run main function
main






