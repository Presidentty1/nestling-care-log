# Demo Script

A 5-10 minute walkthrough of Nestling for stakeholders, investors, or team members.

## Setup (Before Demo)

1. **Web App**: Open http://localhost:5173 (or production URL)
2. **iOS App**: Open in simulator (if Xcode project exists)
3. **Test Account**: Sign in with demo credentials
4. **Test Data**: Ensure seed data is loaded (or create a baby)

## Demo Flow

### 1. Introduction (30 seconds)

> "Nestling is a comprehensive baby care logging app that helps parents track feeds, sleep, diapers, and more. It's built with a local-first architecture, meaning it works offline and prioritizes privacy."

**Show**: Home screen with summary cards

### 2. Quick Logging (1 minute)

> "The core value is quick, one-tap logging. Let me show you how easy it is to log a feed."

**Actions**:
- Click "Feed" quick action
- Show form with sensible defaults
- Enter amount (120 ml)
- Save
- **Show**: Event appears in timeline immediately

> "Notice how the summary card updates instantly. The app works completely offline - all data is stored locally first."

### 3. Multiple Event Types (1 minute)

> "Let's log a few more events to show the variety."

**Actions**:
- Log a diaper (wet)
- Log sleep (start timer, then stop)
- Log tummy time

**Show**: Timeline with all event types, color-coded

> "Each event type has its own color and icon for quick visual scanning."

### 4. History & Navigation (1 minute)

> "Parents often need to look back at past days, especially for doctor visits."

**Actions**:
- Navigate to History tab
- Select yesterday's date
- Show events from that day
- Navigate to different dates

> "The timeline is searchable and filterable. You can also export data as CSV or PDF for doctor visits."

### 5. Smart Predictions (1 minute)

> "One of our key differentiators is AI-powered predictions."

**Actions**:
- Navigate to Labs/Predictions
- Show nap prediction card
- Explain age-based wake windows
- Show "Next Feed" prediction

> "These predictions get smarter over time as we learn the baby's patterns. All analysis happens on-device for privacy."

### 6. Settings & Privacy (1 minute)

> "Privacy is core to our product. Let me show you the settings."

**Actions**:
- Navigate to Settings
- Show AI data sharing toggle
- Show units preference (ml/oz)
- Show data export options
- Show privacy policy link

> "Users have full control. They can export all their data, delete it, or disable AI features entirely. We never sell data."

### 7. iOS Native Features (1 minute - if iOS available)

> "The iOS app takes advantage of native features."

**Actions**:
- Show home screen widget
- Show lock screen widget
- Demonstrate Siri shortcut: "Hey Siri, log a feed"
- Show Live Activity for sleep timer

> "Parents can log events without even opening the app. The Dynamic Island shows active sleep timers."

### 8. Multi-Baby Support (30 seconds)

> "Many families have multiple children."

**Actions**:
- Show baby switcher
- Switch between babies
- Show context changes (different timelines, predictions)

### 9. Closing (30 seconds)

> "That's Nestling in a nutshell. It's designed to be:
> - **Fast**: One-tap logging
> - **Private**: Local-first, no tracking
> - **Smart**: AI predictions without compromising privacy
> - **Reliable**: Works offline, syncs when online"

**Show**: Summary cards one more time

> "Questions?"

## Key Talking Points

### If Asked About Offline Support

> "Yes, the app works completely offline. All data is stored locally first, then synced to the cloud when online. This means parents can log events even in areas with poor connectivity, like hospitals."

### If Asked About AI

> "Our AI features are opt-in. Users can disable AI data sharing entirely. When enabled, we use Google Gemini via Supabase Edge Functions. All analysis happens server-side, but we never store audio recordings or sell data."

### If Asked About Pricing

> "We're currently in beta. Future plans include a free tier with basic features and a Pro tier with advanced analytics, unlimited babies, and family sharing."

### If Asked About Data Export

> "Users can export all their data as CSV or PDF at any time. We also support secure deletion - when a user deletes their account, all data is permanently removed from our servers."

## Demo Tips

1. **Keep it moving**: Don't get stuck on one feature
2. **Show, don't tell**: Let the UI speak for itself
3. **Handle errors gracefully**: If something breaks, acknowledge it and move on
4. **Emphasize privacy**: This is a key differentiator
5. **Show speed**: Quick actions should feel instant

## Common Questions & Answers

**Q: How is this different from other baby trackers?**
A: Local-first architecture, AI predictions without compromising privacy, and modern iOS features like widgets and Siri shortcuts.

**Q: Can multiple caregivers use it?**
A: Yes, we support family sharing. Multiple caregivers can log events for the same baby, and changes sync in real-time.

**Q: What about data security?**
A: All data is encrypted in transit and at rest. We use Supabase with Row Level Security, so users can only access their own family's data.

**Q: Is there a mobile app?**
A: Yes, we have a native iOS app with all the same features plus widgets, Siri shortcuts, and Live Activities. Android is planned for the future.


