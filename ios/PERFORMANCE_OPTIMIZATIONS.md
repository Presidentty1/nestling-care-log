# Performance Optimizations

This document outlines performance optimizations implemented and recommended for the iOS app.

## Implemented Optimizations

### 1. Lazy Loading

- **Timeline**: Uses `LazyVStack` for event lists (only visible items rendered)
- **Images**: Lazy loading when image attachments are added
- **Predictions**: Generated on-demand, cached

### 2. Background Contexts

- **Core Data**: Uses background contexts for heavy operations
- **JSON Storage**: Concurrent queue for reads/writes
- **Predictions**: Generated on background thread

### 3. Caching

- **Predictions**: Cached in Core Data (`PredictionCacheEntity`)
- **Last Used Values**: Cached in memory and persisted
- **App Settings**: Cached in `AppEnvironment`

### 4. View Optimization

- **ViewModels**: Separate from Views (MVVM pattern)
- **Published Properties**: Only update when needed
- **Computed Properties**: Cached where appropriate

### 5. Signpost Logging

- **Performance Monitoring**: OSLog signposts for critical paths
- **Launch Time**: Tracked with signposts
- **Timeline Rendering**: Measured for performance

## Recommended Optimizations

### 1. Image Optimization

When adding photo attachments:

```swift
// Resize images before saving
func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    // Implementation to resize large images
}

// Use thumbnail cache
let thumbnailCache = NSCache<NSString, UIImage>()
```

### 2. Pagination

For large event lists:

```swift
// Load events in batches
func fetchEvents(for baby: Baby, offset: Int, limit: Int) async throws -> [Event] {
    // Fetch only needed events
}
```

### 3. Debouncing

For search and filters:

```swift
// Debounce search input
@State private var searchDebouncer: Task<Void, Never>?

func search(_ text: String) {
    searchDebouncer?.cancel()
    searchDebouncer = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        await performSearch(text)
    }
}
```

### 4. Prefetching

For History view:

```swift
// Prefetch next day's events
func prefetchNextDay() {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
    Task {
        _ = try? await dataStore.fetchEvents(for: baby, on: tomorrow)
    }
}
```

### 5. Memory Management

```swift
// Release large objects when not needed
deinit {
    imageCache.removeAllObjects()
    predictionCache.clear()
}

// Use weak references in closures
Task { [weak self] in
    guard let self = self else { return }
    // ...
}
```

## Performance Budgets

### Launch Time
- **Target**: < 400ms to first content
- **Current**: Measured with signposts
- **Optimization**: Lazy initialization, background loading

### Scrolling Performance
- **Target**: 60 FPS with 100+ events
- **Current**: Uses LazyVStack
- **Optimization**: Virtualization, view recycling

### Memory Usage
- **Target**: < 50MB for typical usage
- **Current**: Monitored via Instruments
- **Optimization**: Release unused data, cache limits

### Battery Impact
- **Target**: Minimal background activity
- **Current**: No continuous background tasks
- **Optimization**: Efficient timers, batch operations

## Monitoring

### Instruments

Use Xcode Instruments to monitor:

1. **Time Profiler**: CPU usage
2. **Allocations**: Memory usage
3. **Leaks**: Memory leaks
4. **Energy Log**: Battery impact
5. **System Trace**: Overall performance

### Signposts

View signposts in Instruments:

1. Run app in Xcode
2. Open Instruments → "os_signpost" instrument
3. Filter by subsystem: `com.nestling.app`
4. View intervals and events

### Performance Logger

Use `PerformanceLogger` for custom metrics:

```swift
PerformanceLogger.measure("TimelineLoad") {
    // Load timeline
}
```

## Best Practices

1. **Minimize Main Thread Work**: Move heavy operations to background
2. **Batch Operations**: Group multiple operations together
3. **Cache Wisely**: Cache frequently accessed data, limit cache size
4. **Lazy Initialization**: Initialize only when needed
5. **Weak References**: Prevent retain cycles
6. **Debounce Input**: Reduce unnecessary work
7. **Prefetch Data**: Load data before user needs it
8. **Release Resources**: Clean up when views disappear

## Testing Performance

### Unit Tests

```swift
func testTimelinePerformance() {
    measure {
        // Load 100 events
        let events = (0..<100).map { _ in Event.mockFeed() }
        let viewModel = HomeViewModel(dataStore: mockStore, baby: mockBaby)
        viewModel.events = events
    }
}
```

### UI Tests

```swift
func testScrollPerformance() {
    let app = XCUIApplication()
    app.launch()
    
    let timeline = app.scrollViews.firstMatch
    measure {
        timeline.swipeUp()
        timeline.swipeDown()
    }
}
```

## Future Optimizations

1. **Core Data Batch Operations**: Use batch inserts/updates
2. **Image Compression**: Compress images before storage
3. **Incremental Sync**: Only sync changed data
4. **Background Refresh**: Refresh data in background
5. **Predictive Prefetching**: ML-based prefetching


