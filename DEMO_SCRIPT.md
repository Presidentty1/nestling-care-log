# Demo Script for Nuzzle MVP

## Overview

This script provides a structured walkthrough for demonstrating Nuzzle to stakeholders, investors, or potential users. Follow this flow to showcase key features effectively.

## Pre-Demo Setup

### Environment Preparation

1. **Test Account:**
   - Use seed data: `supabase db reset`
   - Test user: `test@example.com` / `testpassword`
   - Baby profile: "Test Baby" (60 days old)

2. **Data Preparation:**
   - Ensure sample events exist (feeds, sleep, diapers)
   - Have at least 3-5 events for today
   - Include events from yesterday for history demo

3. **Browser Setup:**
   - Clear cache and cookies
   - Use incognito/private window
   - Have multiple tabs ready (for multi-device demo)

## Demo Flow (15-20 minutes)

### 1. Introduction (2 minutes)

**Opening:**

> "Nuzzle is a baby care tracking app designed for sleep-deprived parents. It helps you log feeds, sleep, diapers, and more with one-tap quick actions and AI-powered insights."

**Key Value Props:**

- ⚡ **Fast**: One-tap logging
- 🧠 **Smart**: AI nap predictions
- 📱 **Offline**: Works without internet
- 👨‍👩‍👧‍👦 **Multi-caregiver**: Family sharing

### 2. Authentication & Onboarding (3 minutes)

**Sign Up Flow:**

1. Navigate to `/auth`
2. Show sign up form
3. Create account: `demo@nuzzle.app`
4. **Highlight**: Auto-redirect to onboarding

**Onboarding:**

1. Welcome screen
2. Create baby profile:
   - Name: "Demo Baby"
   - Date of birth: 60 days ago
   - Feeding style: Combo
3. **Highlight**: Smooth onboarding, no friction

### 3. Home Dashboard (4 minutes)

**Overview:**

> "This is the main dashboard. Everything you need is here."

**Key Features to Show:**

1. **Baby Selector** (top)
   - Show baby name
   - Mention multi-baby support

2. **Nap Prediction Card**
   - "AI predicts next nap based on age and sleep patterns"
   - Show prediction time
   - **Highlight**: Age-based wake windows

3. **Quick Actions**
   - "One-tap logging for common events"
   - Demonstrate: Tap "Log Feed" → Form opens
   - **Highlight**: Speed and convenience

4. **Timeline**
   - "All events in chronological order"
   - Show today's events
   - **Highlight**: Visual timeline, easy to scan

5. **Summary Chips**
   - "Quick stats: feeds today, diapers, sleep"
   - **Highlight**: At-a-glance information

### 4. Event Logging (3 minutes)

**Quick Action:**

1. Tap "Log Feed" quick action
2. Form opens with smart defaults
3. Fill amount: 120ml
4. Submit
5. **Highlight**: Event appears instantly in timeline

**Manual Entry:**

1. Tap FAB (floating action button)
2. Show event type selector
3. Select "Diaper"
4. Fill form
5. Submit
6. **Highlight**: Flexible logging options

**Edit Event:**

1. Tap event in timeline
2. Show edit form
3. Update amount
4. Save
5. **Highlight**: Easy editing

### 5. History View (2 minutes)

**Navigation:**

1. Go to History tab
2. Show date picker
3. Select yesterday
4. **Highlight**: Day-by-day navigation

**Features:**

- Filter by event type
- Export data (CSV/PDF)
- **Highlight**: Doctor visit reports

### 6. AI Features (3 minutes)

**Nap Predictor:**

1. Navigate to Nap Predictor
2. Show prediction details
3. Explain age-based calculations
4. **Highlight**: Personalized predictions

**AI Assistant** (if time):

1. Navigate to AI Assistant
2. Ask: "When should my baby nap next?"
3. Show contextual response
4. **Highlight**: AI-powered insights

### 7. Settings & Multi-Caregiver (2 minutes)

**Settings Overview:**

1. Navigate to Settings
2. Show key options:
   - Baby management
   - Caregiver invites
   - Notification settings
   - Privacy controls

**Family Sharing:**

1. Show caregiver management
2. Explain invite flow
3. **Highlight**: Multi-device sync

### 8. Offline Demo (1 minute)

**Offline Capability:**

1. Disable network (dev tools)
2. Log an event
3. Show it queues
4. Re-enable network
5. Show automatic sync
6. **Highlight**: Works offline, syncs when online

## Key Talking Points

### Problem Statement

> "New parents are overwhelmed. They're sleep-deprived, trying to remember when baby last fed, which side to feed from, when naps happened. Nuzzle solves this with one-tap logging and AI insights."

### Solution Highlights

1. **Speed**: "One tap to log a feed. No forms, no friction."
2. **Intelligence**: "AI learns your baby's patterns and predicts naps."
3. **Reliability**: "Works offline, syncs across devices."
4. **Family**: "Multiple caregivers can log, everyone stays in sync."

### Competitive Advantages

- **Faster than competitors**: One-tap vs. multi-step forms
- **Smarter**: AI predictions vs. manual tracking
- **More reliable**: Offline-first vs. online-only
- **Better UX**: iOS-quality design vs. generic web apps

## Common Questions & Answers

**Q: How does AI work?**
A: "We use age-based wake windows and sleep pattern analysis. The more you log, the more accurate predictions become."

**Q: Is my data secure?**
A: "Yes. All data is encrypted in transit and at rest. We use Row Level Security so you can only see your family's data."

**Q: Can I export my data?**
A: "Yes. You can export to CSV or PDF at any time. We believe in data portability."

**Q: What about privacy?**
A: "We're privacy-first. No ads, no tracking. Your data stays yours. AI features are opt-in."

**Q: How much does it cost?**
A: "Free tier includes basic logging. Pro ($5.99/month) adds AI predictions, unlimited cry insights, and advanced analytics."

## Demo Tips

### Do's

✅ **Do:**

- Keep it conversational
- Focus on user benefits, not features
- Show real scenarios ("Imagine it's 3 AM...")
- Highlight speed and ease
- Address concerns proactively

### Don'ts

❌ **Don't:**

- Get too technical
- Show bugs or errors
- Rush through features
- Ignore questions
- Overwhelm with features

## Post-Demo

### Follow-Up

1. **Send Materials:**
   - Privacy policy
   - Feature comparison
   - Pricing information

2. **Schedule Next Steps:**
   - Beta testing
   - Feedback session
   - Custom demo if needed

3. **Collect Feedback:**
   - What resonated?
   - What's missing?
   - Would they use it?

## Demo Variations

### Short Demo (5 minutes)

- Authentication
- Home dashboard
- Quick action logging
- Nap prediction

### Technical Demo (30 minutes)

- Full feature walkthrough
- Architecture overview
- Security deep-dive
- Q&A session

### Investor Pitch (10 minutes)

- Problem/solution
- Market opportunity
- Key features
- Business model
- Traction/roadmap

## Troubleshooting

### If Something Breaks

1. **Stay Calm**: "Let me show you another feature..."
2. **Have Backup**: Pre-recorded video demo
3. **Acknowledge**: "This is beta, we're improving daily"
4. **Pivot**: Move to working features

### If Questions Come Up

1. **Answer Honestly**: Don't make up features
2. **Take Notes**: "Great question, let me follow up"
3. **Show Roadmap**: "That's planned for Q2"
4. **Be Transparent**: About limitations

## Success Metrics

**Good Demo Signs:**

- ✅ Questions about pricing
- ✅ Requests for beta access
- ✅ Interest in specific features
- ✅ Comparisons to competitors
- ✅ "When can I use this?"

## Related Documentation

- `MVP_CHECKLIST.md` - Feature completeness
- `ARCHITECTURE_WEB.md` - Technical details
- `USER_REVIEW_AND_VALUE_PROPOSITION.md` - User perspective
