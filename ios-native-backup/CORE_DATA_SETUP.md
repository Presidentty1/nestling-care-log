# Core Data Setup for Nuzzle iOS App

## Overview

This guide explains how to set up Core Data for persistent storage in the Nuzzle iOS app. The implementation includes:

- `CoreDataStore` - Main data store implementation
- Managed Object classes for all entities
- Automatic migration support
- Background context for performance
- Data validation and error handling

## Xcode Setup

### 1. Create Core Data Model

1. Open `ios/Nuzzle/Nuzzle.xcodeproj` in Xcode
2. **File → New → File...**
3. Select **Data Model** under Core Data
4. Name it: `NuzzleDataModel.xcdatamodeld`
5. Save in `ios/Nuzzle/Nuzzle/Domain/Models/`

### 2. Create Entities

Create the following entities with these attributes:

#### BabyMO Entity

| Attribute           | Type   | Optional |
| ------------------- | ------ | -------- |
| id                  | UUID   | No       |
| name                | String | No       |
| dateOfBirth         | Date   | No       |
| sex                 | String | Yes      |
| timezone            | String | No       |
| primaryFeedingStyle | String | Yes      |
| createdAt           | Date   | No       |
| updatedAt           | Date   | No       |

#### EventMO Entity

| Attribute | Type   | Optional |
| --------- | ------ | -------- |
| id        | UUID   | No       |
| babyId    | UUID   | No       |
| type      | String | No       |
| subtype   | String | Yes      |
| startTime | Date   | No       |
| endTime   | Date   | Yes      |
| amount    | Double | Yes      |
| unit      | String | Yes      |
| side      | String | Yes      |
| note      | String | Yes      |
| createdAt | Date   | No       |
| updatedAt | Date   | No       |

#### PredictionMO Entity

| Attribute     | Type   | Optional |
| ------------- | ------ | -------- |
| id            | UUID   | No       |
| babyId        | UUID   | No       |
| type          | String | No       |
| predictedTime | Date   | No       |
| confidence    | Double | No       |
| explanation   | String | No       |
| createdAt     | Date   | No       |

#### AppSettingsMO Entity

| Attribute                | Type       | Optional |
| ------------------------ | ---------- | -------- |
| aiDataSharingEnabled     | Boolean    | No       |
| feedReminderEnabled      | Boolean    | No       |
| feedReminderHours        | Integer 32 | No       |
| napWindowAlertEnabled    | Boolean    | No       |
| diaperReminderEnabled    | Boolean    | No       |
| diaperReminderHours      | Integer 32 | No       |
| quietHoursStart          | Date       | Yes      |
| quietHoursEnd            | Date       | Yes      |
| cryInsightsNotifyMe      | Boolean    | No       |
| onboardingCompleted      | Boolean    | No       |
| preferredUnit            | String     | No       |
| timeFormat24Hour         | Boolean    | No       |
| preferMediumSheet        | Boolean    | No       |
| spotlightIndexingEnabled | Boolean    | No       |

#### LastUsedValuesMO Entity

| Attribute       | Type       | Optional |
| --------------- | ---------- | -------- |
| eventType       | String     | No       |
| amount          | Double     | Yes      |
| unit            | String     | Yes      |
| side            | String     | Yes      |
| subtype         | String     | Yes      |
| durationMinutes | Integer 32 | Yes      |

### 3. Generate NSManagedObject Subclasses

1. Select the data model file
2. **Editor → Create NSManagedObject Subclass...**
3. Select all entities
4. Choose language: **Swift**
5. Check **Use Core Data** generic classes
6. Save in `ios/Nuzzle/Nuzzle/Domain/Models/CoreData/`

This will generate the NSManagedObject subclasses that match the files we created.

### 4. Enable Code Generation

For each entity:

1. Select the entity in the data model editor
2. In the Data Model Inspector (right panel):
   - **Codegen**: Set to **Manual/None**
   - This ensures Xcode uses our custom subclasses

## Configuration

### Persistent Store Options

The Core Data stack is configured with:

- **Automatic Lightweight Migration**: Enabled
- **Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy`
- **Automatic Merge**: Changes from parent context automatically merged

### Background Context

- Separate background context for all data operations
- Prevents blocking the main UI thread
- Automatic conflict resolution

## Testing

### Performance Testing

Test with large datasets:

```swift
// Test with 1000+ events
func testLargeDataset() async throws {
    let store = CoreDataStore()
    let baby = Baby.mock()

    // Create 1000 events
    for i in 0..<1000 {
        let event = Event(
            babyId: baby.id,
            type: .feed,
            amount: Double(i),
            unit: "ml"
        )
        try await store.addEvent(event)
    }

    // Test fetch performance
    let start = Date()
    let events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
    let duration = Date().timeIntervalSince(start)

    XCTAssertEqual(events.count, 1000)
    XCTAssertLessThan(duration, 1.0) // Should be < 1 second
}
```

### Migration Testing

Test schema migrations:

```swift
func testMigration() async throws {
    // Test that old data migrates correctly
    let store = CoreDataStore()
    let babies = try await store.fetchBabies()
    XCTAssertFalse(babies.isEmpty)
}
```

## Troubleshooting

### Common Issues

1. **"Entity not found" errors**
   - Ensure entity names in code match data model exactly
   - Check that the .xcdatamodeld file is included in the target

2. **Migration errors**
   - Check that migration policy is set correctly
   - Ensure all required attributes have default values

3. **Performance issues**
   - Use background context for heavy operations
   - Add appropriate indexes in the data model
   - Use fetch limits and predicates effectively

### Debug Mode

Enable Core Data debugging:

```swift
// In Xcode scheme environment variables
COM.apple.CoreData.SQLDebug = 1
COM.apple.CoreData.MigrationDebug = 1
```

## Performance Optimizations

### Fetch Request Optimization

- Use predicates to limit results
- Sort descriptors for consistent ordering
- Fetch limits for large datasets
- Batch operations for bulk inserts

### Memory Management

- Use `NSFetchedResultsController` for table views
- Release objects when not needed
- Use background contexts for long-running operations

### Caching Strategy

- Predictions cached in Core Data
- Last used values cached per event type
- App settings cached in memory

## Migration Strategy

### Versioning

- Increment model version for schema changes
- Use automatic lightweight migration for simple changes
- Custom migration logic for complex changes

### Backup and Restore

- Export data as JSON for backup
- Restore from JSON backup files
- Validate data integrity during restore

## Integration with Supabase

The Core Data store is designed to work with Supabase sync:

1. Local changes saved to Core Data immediately
2. Background sync pushes changes to Supabase
3. Conflicts resolved using last-write-wins
4. Real-time updates from Supabase merged into Core Data

## Monitoring

### Performance Metrics

Track these metrics in production:

- Average fetch time for events
- Memory usage during large fetches
- Background sync duration
- Migration time

### Error Tracking

Monitor these errors:

- Core Data save failures
- Migration errors
- Fetch request failures
- Background context deadlocks
