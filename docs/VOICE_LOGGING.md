# Voice Logging Documentation

## Overview

Voice logging allows parents to log events hands-free using voice commands. This is especially useful when holding a baby or during nighttime feedings.

## Current Implementation (Web)

### Technology Stack

- **Web Speech API** (Chrome/Edge only)
- Browser-native speech recognition
- No server-side processing for speech-to-text
- Works offline (after initial page load)

### Browser Support

- ✅ Chrome (desktop and Android)
- ✅ Edge (desktop)
- ✅ Safari (iOS 14.5+, limited)
- ❌ Firefox (not supported)

### Implementation Files

- Hook: `src/hooks/useVoiceLogging.ts`
- Edge function: `supabase/functions/process-voice-command/index.ts`
- UI Component: `src/components/VoiceLogModal.tsx`
- Settings: `src/pages/ShortcutsSettings.tsx`

## Supported Commands

### Feeding

```
"Baby had 4 ounces"
"Fed 120 milliliters"
"Bottle fed 5 ounces"
"Nursing left side"
"Breastfed right side"
```

### Sleep

```
"Start sleep timer"
"Stop sleep timer"
"Baby is sleeping"
"Put baby down for nap"
```

### Diaper

```
"Log wet diaper"
"Log dirty diaper"
"Change diaper mixed"
"Wet and dirty diaper"
```

### Command Parsing

The `process-voice-command` edge function uses pattern matching:

- Extracts numbers for amounts (ounces, milliliters)
- Detects keywords: "bottle", "nursing", "left", "right", "wet", "dirty"
- Maps to event types: feed, sleep, diaper
- Returns structured event data

## User Settings

### Enable/Disable Voice Logging

Location: Settings → Shortcuts & Voice Logging

**localStorage key**: `voice_enabled`

```typescript
// Check if enabled
const voiceEnabled = localStorage.getItem('voice_enabled') === 'true';
```

When disabled:

- Microphone button is hidden in FloatingActionButton
- Voice modal cannot be opened
- Voice features in Quick Actions are hidden

### Microphone Permission

Required: User must grant microphone permission in browser

- First use triggers browser permission prompt
- If denied, show instructions to enable in browser settings
- Permission persists across sessions

## How It Works

### 1. User Initiates Voice Logging

- Taps microphone button (FloatingActionButton or Quick Actions)
- `VoiceLogModal` opens
- Browser requests microphone permission (first time)

### 2. Speech Recognition

```typescript
// From useVoiceLogging.ts
const recognition = new (window.SpeechRecognition ||
  window.webkitSpeechRecognition)();
recognition.continuous = false; // Single command
recognition.interimResults = false; // Only final results
recognition.lang = 'en-US';

recognition.onresult = event => {
  const transcript = event.results[0][0].transcript;
  // Process transcript...
};
```

### 3. Command Processing

- Transcript sent to `process-voice-command` edge function
- Edge function parses command and extracts event data
- Returns structured event: `{ type: 'feed', amount: 4, unit: 'oz' }`

### 4. Event Logging

- Same flow as manual logging
- Event stored in `events` table via `eventsService`
- UI shows success toast
- Timeline updates immediately

## iOS Implementation Notes

### Future Native Implementation

When building iOS app with Capacitor:

**1. Use iOS Speech Framework**

```swift
import Speech

let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
let request = SFSpeechURLRecognitionRequest(url: audioURL)

recognizer?.recognitionTask(with: request) { result, error in
    guard let result = result else { return }
    let transcript = result.bestTranscription.formattedString
    // Send to process-voice-command
}
```

**2. Info.plist Requirements**

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition to help you log baby events hands-free.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to recognize your voice commands.</string>
```

**3. Permission Request**

```swift
SFSpeechRecognizer.requestAuthorization { status in
    switch status {
    case .authorized:
        // Enable voice logging
    case .denied, .restricted, .notDetermined:
        // Show settings prompt
    }
}
```

**4. Offline Support**

- iOS Speech Framework works offline (on-device recognition)
- Store transcripts in local queue if offline
- Process when connection restored

### Voice Shortcuts (iOS)

Consider adding Siri Shortcuts support:

```swift
import Intents

// Define custom intent
class LogFeedingIntent: INIntent {
    @NSManaged var amount: NSNumber?
    @NSManaged var unit: String?
}

// Donate shortcut
let intent = LogFeedingIntent()
intent.amount = 5
intent.unit = "oz"
let interaction = INInteraction(intent: intent, response: nil)
interaction.donate()
```

User can then say:

> "Hey Siri, log a feeding in Nuzzle"

## Troubleshooting

### Issue: Voice recognition not starting

**Cause**: Microphone permission denied or browser not supported

**Fix**:

1. Check browser compatibility (Chrome recommended)
2. Grant microphone permission in browser settings
3. Ensure HTTPS (required for Web Speech API)

### Issue: Commands not recognized

**Cause**: Accent, background noise, or unclear speech

**Fix**:

1. Speak clearly and at moderate pace
2. Reduce background noise
3. Use standard phrases from supported commands
4. Consider adding more command variations to parser

### Issue: Wrong amount logged

**Cause**: Speech recognition error (e.g., "four" → "for")

**Fix**:

1. Speak numbers clearly
2. Add confirmation step (show parsed data before saving)
3. Allow editing after voice log

### Issue: Voice button not visible

**Cause**: Voice logging disabled in settings

**Fix**:

1. Go to Settings → Shortcuts & Voice Logging
2. Enable "Voice Logging"
3. Refresh page or restart app

## Best Practices

### For Users

- **Speak clearly** in quiet environment
- **Use standard phrases** from supported commands
- **Include units** explicitly ("5 ounces" not just "5")
- **Review before saving** (if confirmation step added)

### For Developers

- **Test with various accents** and speech patterns
- **Provide feedback** during recognition (animated mic icon)
- **Show transcript** before processing (user confirmation)
- **Handle errors gracefully** (fallback to manual entry)
- **Log edge cases** to improve parser

## Performance Considerations

### Latency

- Speech recognition: 1-3 seconds (browser-dependent)
- Command processing: < 500ms (edge function)
- Total: 1.5-3.5 seconds from start to saved event

### Battery Impact

- Microphone use: Minimal (short bursts)
- Network: One API call per command
- Recommendation: Not suitable for continuous listening

### Data Usage

- Transcript text: < 1 KB per command
- Audio not transmitted (processed locally in browser)
- Very low data consumption

## Future Enhancements

### Phase 2+ Ideas

- **Multi-language support**: Spanish, French, German, etc.
- **Continuous listening mode**: "Hey Nuzzle, log a feeding"
- **Voice profiles**: Distinguish between different caregivers
- **Smart context**: "Same as last time" command
- **Voice editing**: "Change that to 6 ounces"
- **Conversation mode**: Follow-up questions without reopening

### Advanced Features

- **Natural language**: "Baby ate well this morning"
- **Multiple events**: "Changed diaper and started feeding"
- **Time specification**: "Log a nap from 2pm to 3:30pm"
- **Notes via voice**: "Add note: baby seemed fussy"

## Testing Voice Commands

### Manual Testing Checklist

- [ ] Open voice modal
- [ ] Grant microphone permission
- [ ] Test each command type (feed, sleep, diaper)
- [ ] Test various phrasings
- [ ] Test with background noise
- [ ] Verify event saved correctly
- [ ] Check toast notification
- [ ] Verify timeline update

### Automated Testing

Voice features are hard to test automatically. Consider:

- Mock Web Speech API in tests
- Test command parser independently
- Use recorded audio samples (if possible)
- Test edge function with known transcripts

### Example Test Cases

```typescript
// Test command parser
describe('Voice Command Parser', () => {
  it('should parse bottle feeding', () => {
    const result = parseCommand('Baby had 5 ounces');
    expect(result.type).toBe('feed');
    expect(result.amount).toBe(5);
    expect(result.unit).toBe('oz');
  });

  it('should handle milliliters', () => {
    const result = parseCommand('Fed 120 milliliters');
    expect(result.amount).toBe(120);
    expect(result.unit).toBe('ml');
  });
});
```

## Privacy & Security

### Data Flow

1. Audio captured locally in browser
2. Browser converts to text (locally, not sent to server)
3. Text transcript sent to edge function
4. Edge function parses and returns structured data
5. Audio is never transmitted or stored

### User Control

- Users can disable voice logging anytime
- Microphone permission can be revoked in browser
- No audio recordings are persisted
- Transcripts are not stored (only parsed events)

### Compliance

- GDPR: Audio processing is local, no personal data stored
- CCPA: No audio data collection beyond session
- App Store: Clear microphone usage description required

## Support & Resources

- Web Speech API: https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API
- iOS Speech Framework: https://developer.apple.com/documentation/speech
- Capacitor Audio: https://capacitorjs.com/docs/apis/device
- Browser Compatibility: https://caniuse.com/speech-recognition
