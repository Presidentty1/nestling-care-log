# Nestling Pro Features

This document outlines which features are locked behind Nestling Pro subscription.

## Pro Features

### ✅ Implemented

1. **Multi-Caregiver Invites**
   - Inviting partners and family members
   - Real-time sync across devices
   - Role-based access (admin, member, viewer)
   - **Status**: Gated with Pro check in `ManageCaregivers.tsx`

### 🔒 Should Be Pro (Not Yet Implemented)

2. **AI Features**
   - AI Nap Predictions with wake window analysis
   - AI Cry Analysis
   - AI Assistant chat
   - **Files to update**: 
     - `src/pages/Predictions.tsx`
     - `src/pages/CryInsights.tsx`
     - `src/pages/AIAssistant.tsx`
     - Edge functions: `generate-predictions`, `analyze-cry`, `ai-assistant`

3. **CSV Export**
   - Export events to CSV for sharing with pediatrician
   - **Files to update**: 
     - `src/pages/Settings/PrivacyData.tsx`
     - `src/services/dataService.ts` (export functions)

4. **Advanced Analytics & Insights**
   - Weekly insights reports
   - Growth tracking
   - Advanced charts and trends
   - **Files to update**: 
     - `src/pages/Analytics.tsx` (if exists)
     - Any analytics components

## Free Features

These features remain free for all users:

- ✅ Unlimited event logging (feeds, sleep, diapers, tummy time)
- ✅ Timeline & history view
- ✅ Basic reminders & notifications
- ✅ Multi-device sync (for single user)
- ✅ Basic analytics (daily summaries)
- ✅ Dark mode
- ✅ Offline mode

## Implementation Status

### Pro Service & Hook
- ✅ `src/services/proService.ts` - Service to check Pro status
- ✅ `src/hooks/usePro.ts` - React hook for Pro status
- ✅ Checks `subscriptions` table for active/trialing status

### Pro Gating
- ✅ Multi-caregiver invites - Fully gated
- ⏳ AI features - Not yet gated
- ⏳ CSV export - Not yet gated
- ⏳ Advanced analytics - Not yet gated

## Usage Example

```typescript
import { usePro } from '@/hooks/usePro';

function MyComponent() {
  const { isPro, loading } = usePro();
  
  if (!isPro) {
    return <UpgradePrompt />;
  }
  
  return <ProFeature />;
}
```

## Next Steps

1. Gate AI features behind Pro check
2. Gate CSV export behind Pro check
3. Add Pro badges to locked features in UI
4. Update Settings page to show Pro status
5. Add upgrade CTAs throughout the app


