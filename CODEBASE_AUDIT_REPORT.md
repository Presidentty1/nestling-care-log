# Codebase Audit Report
## Performance, Bugs, and UX Issues

**Date:** 2025-01-20  
**Scope:** iOS (SwiftUI) and Web (React/TypeScript) codebases

---

## 🔴 Critical Issues (Must Fix)

### 1. **DateFormatter Performance Issue** (iOS)
**Location:** `ios/Sources/Utilities/DateUtils.swift:14-29`

**Problem:** `DateFormatter` instances are created on every call to `formatTime()` and `formatDate()`. DateFormatter initialization is expensive and should be cached.

**Impact:** 
- Causes UI lag when rendering many timeline events
- Wastes CPU cycles on repeated allocations
- Can cause frame drops during scrolling

**Fix:**
```swift
private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale.current
    return formatter
}()

private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale.current
    return formatter
}()
```

---

### 2. **Search Input Not Debounced** (iOS)
**Location:** `ios/Sources/Features/Home/HomeViewModel.swift:36-66`

**Problem:** `filteredEvents` computed property recalculates on every keystroke. With many events, this causes UI lag during typing.

**Impact:**
- Typing in search feels sluggish with 100+ events
- Battery drain from excessive filtering
- Poor user experience

**Fix:** Add debouncing to `searchText` changes:
```swift
@Published var searchText: String = "" {
    didSet {
        debounceSearch()
    }
}

private var searchDebounceTask: Task<Void, Never>?

private func debounceSearch() {
    searchDebounceTask?.cancel()
    searchDebounceTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        if !Task.isCancelled {
            // Trigger UI update
            objectWillChange.send()
        }
    }
}
```

**Alternative:** Use `onChange` modifier with debounce in `HomeView.swift`.

---

### 3. **Toast Auto-Dismiss Logic Bug** (iOS)
**Location:** `ios/Sources/Features/History/HistoryView.swift:72-76`

**Problem:** Line 73 compares `showToast?.id == showToast?.id`, which is always `true`. This means toasts never auto-dismiss properly.

**Impact:**
- Toasts accumulate and don't dismiss
- Memory leak from retained closures
- UI clutter

**Fix:**
```swift
let toastId = showToast?.id
DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
    if showToast?.id == toastId {
        showToast = nil
    }
}
```

**Also check:** `ios/Sources/Features/Home/HomeView.swift:106-110` has the same bug.

---

### 4. **Memory Leak in React useEffect** (Web)
**Location:** `src/pages/Home.tsx:126-180`

**Problem:** `useEffect` subscribes to `eventsService` but the cleanup function (`unsubscribe`) may not be called if component unmounts during async operations. Also, the effect depends on `events.length` which can cause infinite loops.

**Impact:**
- Memory leaks from retained subscriptions
- Potential infinite re-render loops
- Performance degradation over time

**Fix:**
```typescript
useEffect(() => {
  const unsubscribe = eventsService.subscribe((action, data) => {
    // ... handler logic
  });
  
  return () => {
    unsubscribe?.();
  };
}, [activeBabyId]); // Remove events.length from deps
```

**Note:** Move `events.length` checks inside the handler, not as dependencies.

---

## 🟡 Performance Issues (Should Fix)

### 5. **CryRecorder Timer Frequency** (Web)
**Location:** `src/components/CryRecorder.tsx:80-88`

**Problem:** Timer runs every 100ms to update progress. This is excessive for a progress bar.

**Impact:**
- Unnecessary re-renders (10x per second)
- Battery drain
- Can cause jank on slower devices

**Fix:** Reduce to 250ms or 500ms:
```typescript
timerRef.current = setInterval(() => {
  const elapsed = Date.now() - startTime;
  const newProgress = Math.min((elapsed / maxDuration) * 100, 100);
  setProgress(newProgress);
  
  if (elapsed >= maxDuration) {
    stopRecording();
  }
}, 250); // Changed from 100ms
```

---

### 6. **filteredEvents Recalculation** (iOS)
**Location:** `ios/Sources/Features/Home/HomeViewModel.swift:19-69`

**Problem:** `filteredEvents` is a computed property that recalculates on every access. With large event lists, this is inefficient.

**Impact:**
- Multiple recalculations during single render cycle
- Lag when scrolling timeline
- Battery drain

**Fix:** Cache filtered results:
```swift
@Published private var _filteredEvents: [Event] = []
var filteredEvents: [Event] {
    _filteredEvents
}

private func updateFilteredEvents() {
    // ... filtering logic
    _filteredEvents = filtered
}
```

Call `updateFilteredEvents()` when `events`, `searchText`, or `selectedFilter` change.

---

### 7. **DateFormatter in Search Filtering** (iOS)
**Location:** `ios/Sources/Features/Home/HomeViewModel.swift:57-60`

**Problem:** Creates a new `DateFormatter` for every event during search filtering.

**Impact:**
- Performance hit when searching with many events
- Memory churn

**Fix:** Use cached formatter from `DateUtils` or create a static one.

---

### 8. **Missing Cleanup in CryRecorder** (Web)
**Location:** `src/components/CryRecorder.tsx:95-105`

**Problem:** `stopRecording()` clears the interval, but if component unmounts while recording, the interval may not be cleaned up.

**Impact:**
- Memory leak
- Timer continues running after component unmounts

**Fix:**
```typescript
useEffect(() => {
  return () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
    if (mediaRecorderRef.current?.state !== 'inactive') {
      mediaRecorderRef.current?.stop();
    }
  };
}, []);
```

---

## 🟢 UX/UI Improvements

### 9. **AI Assistant Empty State Logic** (iOS)
**Location:** `ios/Sources/Features/Assistant/AssistantView.swift:36-39`

**Problem:** Empty state shows even when welcome message exists. After `bootstrapConversation()` adds the intro message, `messages.isEmpty` becomes `false`, but there's a brief moment where both might show.

**Impact:**
- Confusing UI state
- Brief flash of empty state

**Fix:** Check should be:
```swift
if viewModel.messages.isEmpty && !viewModel.isSending {
    EmptyChatState()
        .padding(.top, .spacingXL)
}
```

Or better: Remove empty state entirely since welcome message is now seeded.

---

### 10. **No Loading Feedback on Filter Change** (iOS)
**Location:** `ios/Sources/Features/Home/HomeView.swift:30-40`

**Problem:** When tapping summary cards to change filter, there's no visual feedback if filtering takes time (with many events).

**Impact:**
- Users might think tap didn't register
- No indication that work is happening

**Fix:** Add subtle animation or loading indicator:
```swift
SummaryCardsView(summary: summary) { filter in
    withAnimation(.easeInOut(duration: 0.2)) {
        if viewModel.selectedFilter == filter {
            viewModel.selectedFilter = .all
        } else {
            viewModel.selectedFilter = filter
        }
    }
    Haptics.selection() // Add haptic feedback
}
```

---

### 11. **Search Suggestions Performance** (iOS)
**Location:** `ios/Sources/Features/Home/HomeViewModel.swift:72-87`

**Problem:** `searchSuggestions` computed property processes all events on every access to extract note terms.

**Impact:**
- Lag when opening search suggestions
- Unnecessary work if suggestions aren't shown

**Fix:** Cache suggestions and update only when events change:
```swift
@Published private var _searchSuggestions: [String] = []
var searchSuggestions: [String] {
    _searchSuggestions
}

private func updateSearchSuggestions() {
    // ... existing logic
    _searchSuggestions = suggestions
}
```

---

### 12. **Missing Error Boundaries** (Web)
**Location:** Various React components

**Problem:** No error boundaries to catch and handle component errors gracefully.

**Impact:**
- Entire app can crash from one component error
- Poor user experience

**Fix:** Add error boundaries around major sections:
```typescript
<ErrorBoundary fallback={<ErrorFallback />}>
  <Home />
</ErrorBoundary>
```

---

## 🔵 Code Quality Issues

### 13. **Duplicate Foundation Import** (iOS)
**Location:** `ios/Sources/Utilities/DateUtils.swift:1-3`

**Problem:** `import Foundation` appears twice.

**Fix:** Remove duplicate import.

---

### 14. **Inconsistent Error Handling** (iOS)
**Location:** `ios/Sources/Features/Home/HomeViewModel.swift:395-398`

**Problem:** `loadNextNapPrediction()` silently fails with `print()`. Should use proper error logging or user notification.

**Fix:**
```swift
} catch {
    // Use proper logging
    Logger.ui.error("Failed to load nap prediction: \(error.localizedDescription)")
    // Or set errorMessage if user-facing
}
```

---

### 15. **Magic Numbers** (Web)
**Location:** `src/components/CryRecorder.tsx:78-88`

**Problem:** Hardcoded `20000` (20 seconds) and `100` (milliseconds) should be constants.

**Fix:**
```typescript
const MAX_RECORDING_DURATION_MS = 20000;
const PROGRESS_UPDATE_INTERVAL_MS = 250; // Also fix the performance issue
```

---

## 📊 Summary

**Critical Issues:** 4  
**Performance Issues:** 4  
**UX/UI Improvements:** 4  
**Code Quality:** 3  

**Total Issues:** 15

### Priority Order:
1. Fix DateFormatter caching (Critical)
2. Add search debouncing (Critical)
3. Fix toast auto-dismiss bug (Critical)
4. Fix React useEffect cleanup (Critical)
5. Optimize CryRecorder timer (Performance)
6. Cache filteredEvents (Performance)
7. Fix AI Assistant empty state (UX)
8. Add error boundaries (UX)
9. Remaining items (Code Quality)

---

## 🛠️ Recommended Next Steps

1. **Immediate:** Fix the 4 critical issues
2. **Short-term:** Address performance issues (items 5-7)
3. **Medium-term:** UX improvements and code quality
4. **Long-term:** Add performance monitoring and error tracking

---

**Note:** This audit focused on static code analysis. For complete validation, run:
- Performance profiling (Instruments for iOS, React DevTools Profiler for Web)
- Memory leak detection (Leaks instrument, React DevTools)
- User testing for UX issues






