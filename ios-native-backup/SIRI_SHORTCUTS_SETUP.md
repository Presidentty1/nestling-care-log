# Siri Shortcuts Setup Guide

## Overview

Nuzzle supports Siri Shortcuts for hands-free baby tracking. Users can say voice commands like:

- "Hey Siri, log a feed"
- "Hey Siri, start nap timer"
- "Hey Siri, how long since last feed?"

## Implemented Shortcuts

### Logging Shortcuts
- **Log Feed**: Records a feeding with optional amount and unit
- **Start Sleep**: Begins sleep tracking timer
- **Stop Sleep**: Ends sleep tracking
- **Log Diaper**: Records diaper change
- **Log Tummy Time**: Records tummy time session

### Query Shortcuts
- **Time Since Last Feed**: Reports how long ago baby was fed
- **Time Since Last Diaper**: Reports time since last diaper change
- **Time Since Last Nap**: Reports time since baby woke up

## Setup Instructions

### 1. Enable Siri Shortcuts in iOS
1. Open **Settings → Siri & Search**
2. Ensure **Allow Siri When Locked** is enabled (optional)
3. Enable **Siri Suggestions** for better shortcut discovery

### 2. Add Nuzzle Shortcuts
1. Open **Shortcuts app**
2. Tap **+** to create new shortcut
3. Search for **Nuzzle** in the action library
4. Add desired shortcuts to your collection

### 3. Siri Voice Commands
Users can activate shortcuts by saying:
- "Hey Siri, log a feed in Nuzzle"
- "Hey Siri, start sleep timer in Nuzzle"
- "Hey Siri, when was last feed in Nuzzle"

### 4. Customize Quick Actions
In the Shortcuts app, users can:
- Rename shortcuts for personal preference
- Add to Siri watch face (Apple Watch)
- Create automation triggers

## Technical Implementation

### App Intents
- Located in `ios/NuzzleIntents/` directory
- Each intent handles specific functionality
- Integration with shared data via App Groups

### Siri Integration
- `AppShortcuts.swift` defines available shortcuts
- Natural language phrases for voice recognition
- Fallback to manual activation if voice fails

### Data Flow
1. User speaks Siri command
2. Siri matches to Nuzzle shortcut
3. Intent executes using shared App Group data
4. Result returned to user
5. Widgets update automatically

## Privacy & Security

- All shortcuts require user authentication
- Data accessed through secure App Groups
- No sensitive data exposed to Siri
- User permission required for each shortcut type

## Testing

### Manual Testing
1. **Voice Commands**: Test all Siri phrases
2. **Shortcuts App**: Verify manual activation
3. **Apple Watch**: Test watch face complications
4. **Background**: Ensure shortcuts work when app closed

### Edge Cases
- Test when no data available
- Verify behavior when app not logged in
- Check offline functionality
- Test with multiple babies

## User Education

### In-App Prompts
- Settings page includes Siri shortcut suggestions
- Onboarding can mention voice commands
- Help documentation covers shortcut usage

### Siri Suggestions
- iOS automatically suggests shortcuts based on usage
- Contextual suggestions appear in relevant situations

## Future Enhancements

### Advanced Queries
- "How much milk today?"
- "When next nap?"
- "Baby sleep quality this week?"

### Smart Defaults
- Learn user's preferred amounts/units
- Suggest common feeding times

### Watch Integration
- Dedicated watch app complications
- Haptic feedback for timers

