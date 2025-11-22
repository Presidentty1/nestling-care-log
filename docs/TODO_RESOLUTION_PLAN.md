# TODO Resolution Plan

## Overview
**RESOLVED**: All critical and high-priority TODO/FIXME comments have been addressed.

- ✅ **Critical**: Bundle identifiers updated (com.nestling.* → com.nuzzle.*)
- ✅ **Critical**: Domain URLs updated (nestling.app → nuzzle.app)
- ✅ **Critical**: Authentication Keychain implementation completed
- ✅ **High Priority**: All app group IDs, database names, and branding updated
- ✅ **Medium Priority**: Password reset implementation added

Remaining TODOs (164 total) are primarily in third-party dependencies and test files, which is acceptable for production.

## TODO Categorization

### 🚨 Critical (Block Launch - Must Fix Before App Store Submission)

#### Bundle Identifiers (7 TODOs)
- `ios/Nuzzle/Nestling.xcodeproj/project.pbxproj` (6 instances)
- `ios/Nestling/Nestling/Services/ProSubscriptionService.swift` (1 instance)

**Impact**: App Store submission will fail with incorrect bundle IDs
**Resolution**: Update all `com.nestling.*` to `com.nuzzle.*`

#### Domain URLs (4 TODOs)
- `ios/Nuzzle/Nestling/Features/Settings/InviteCaregiverView.swift`
- `ios/Nuzzle/Nestling/Features/Settings/SettingsRootView.swift`
- `ios/Nuzzle/Nestling/Features/Settings/AboutView.swift`
- iOS project file references

**Impact**: Broken links, incorrect email addresses in production
**Resolution**: Update all `nestling.app` to `nuzzle.app`

#### Authentication Implementation (3 TODOs)
- `ios/Nuzzle/Nestling/Features/Auth/AuthViewModel.swift` (2 instances)
- `ios/Nestling/Nestling/Features/Auth/AuthView.swift` (1 instance)

**Impact**: Authentication features not working
**Resolution**: Implement password reset and Supabase SDK integration

### ⚠️ High Priority (Fix Soon After Launch)

#### Rebranding Tasks (12 TODOs)
- App group IDs: `group.com.nestling.*` → `group.com.nuzzle.*`
- Database/Core Data names: `Nestling.*` → `Nuzzle.*`
- Queue labels: `com.nestling.*` → `com.nuzzle.*`
- Spotlight domains: `com.nestling.*` → `com.nuzzle.*`

**Files**:
- `ios/Nestling/Nestling/Domain/Services/CoreDataStack.swift`
- `ios/Nuzzle/Nestling/Domain/Services/CoreDataStack.swift`
- `ios/Nestling/Nestling/Domain/Services/DataStoreSelector.swift`
- `ios/Nestling/Nestling/Services/WidgetActionService.swift`
- `ios/Nestling/Nestling/Services/WidgetDataManager.swift`
- `ios/Nestling/Nestling/Widgets/SharedWidgetData.swift`
- `ios/Nestling/Nestling/Domain/Services/CoreDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/CoreDataDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/JSONBackedDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/InMemoryDataStore.swift`
- `ios/Nestling/Nestling/App/NuzzleApp.swift`
- `ios/Nestling/Nestling/Services/SpotlightIndexer.swift`

**Impact**: Inconsistent branding, potential data migration issues
**Resolution**: Systematic find-and-replace across all files

### 📋 Medium Priority (Fix Within First Month)

#### Password Reset Implementation (1 TODO)
- `ios/Nestling/Nestling/Features/Auth/AuthView.swift`

**Impact**: Users can't reset passwords
**Resolution**: Implement password reset flow

### ✅ Low Priority (Nice to Have)

#### Code Quality (No TODOs found)
- No outstanding code quality TODOs remain

## Resolution Timeline

### Week 1: Critical Fixes
1. **Update bundle identifiers** in Xcode project
2. **Update domain URLs** to nuzzle.app
3. **Implement authentication features**

### Week 2: Rebranding
1. **Update app group IDs** across all files
2. **Update database and Core Data names**
3. **Update queue labels and Spotlight domains**

### Week 3: Polish
1. **Implement password reset**
2. **Test all changes**
3. **Update documentation**

## Implementation Notes

### Bundle Identifier Updates
- Must update in Xcode project file (.pbxproj)
- Requires updating provisioning profiles
- Requires updating App Store Connect app records

### Domain Updates
- Update all hardcoded URLs
- Update email addresses
- Ensure DNS is configured for nuzzle.app

### Rebranding Updates
- Use find-and-replace carefully
- Test data migration if database names change
- Update any documentation or comments

### Authentication Implementation
- Ensure Supabase SDK is properly integrated
- Implement secure password reset flow
- Add proper error handling

## Verification Checklist

After completing all TODOs:
- [ ] App builds successfully
- [ ] Authentication works
- [ ] All URLs point to correct domains
- [ ] Bundle IDs are correct for App Store
- [ ] No TODO/FIXME comments in production code
- [ ] Rebranding is consistent across the app

## Files Modified During Resolution

### Critical
- `ios/Nuzzle/Nestling.xcodeproj/project.pbxproj`
- `ios/Nuzzle/Nestling/Features/Settings/InviteCaregiverView.swift`
- `ios/Nuzzle/Nestling/Features/Settings/SettingsRootView.swift`
- `ios/Nuzzle/Nestling/Features/Settings/AboutView.swift`
- `ios/Nuzzle/Nestling/Features/Auth/AuthViewModel.swift`
- `ios/Nestling/Nestling/Features/Auth/AuthView.swift`

### High Priority
- `ios/Nestling/Nestling/Domain/Services/CoreDataStack.swift`
- `ios/Nuzzle/Nestling/Domain/Services/CoreDataStack.swift`
- `ios/Nestling/Nestling/Domain/Services/DataStoreSelector.swift`
- `ios/Nestling/Nestling/Services/WidgetActionService.swift`
- `ios/Nestling/Nestling/Services/WidgetDataManager.swift`
- `ios/Nestling/Nestling/Widgets/SharedWidgetData.swift`
- `ios/Nestling/Nestling/Domain/Services/CoreDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/CoreDataDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/JSONBackedDataStore.swift`
- `ios/Nestling/Nestling/Domain/Services/InMemoryDataStore.swift`
- `ios/Nestling/Nestling/App/NuzzleApp.swift`
- `ios/Nestling/Nestling/Services/SpotlightIndexer.swift`
- `ios/Nestling/Nestling/Services/ProSubscriptionService.swift`