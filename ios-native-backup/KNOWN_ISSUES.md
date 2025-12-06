# Known Issues

## Current Limitations

### Predictions
- **Issue**: Predictions use local heuristics, not cloud-based AI
- **Impact**: Less accurate than cloud-trained models
- **Mitigation**: Clear labeling that predictions are "local estimates"
- **Timeline**: Cloud AI integration planned for future release

### Cry Insights
- **Issue**: Beta feature uses rule-based classification, not ML
- **Impact**: Classification accuracy is limited
- **Mitigation**: Prominent "Beta" labeling, medical disclaimers
- **Timeline**: ML-based classification planned for future release

### Multi-Caregiver Sync
- **Issue**: Cloud sync not implemented in MVP
- **Impact**: Caregivers must use same device or manual export/import
- **Mitigation**: Export/import functionality available
- **Timeline**: Cloud sync planned for future release

### Widgets
- **Issue**: Widgets show mock data in preview
- **Impact**: Widgets may not update immediately
- **Mitigation**: Widget refresh intervals configured
- **Timeline**: Real-time widget updates planned

## Edge Cases

### DST Transitions
- **Status**: Handled correctly
- **Behavior**: Durations calculated correctly across DST boundaries
- **Testing**: Unit tests cover DST forward/backward transitions

### Timezone Changes
- **Status**: Handled correctly
- **Behavior**: Events maintain original timestamps
- **Testing**: Unit tests cover timezone adjustments

### Active Sleep Persistence
- **Status**: Implemented
- **Behavior**: Active sleep persists across app kills
- **Testing**: Resilience tests cover app kill scenarios

## Performance

### Large Timelines
- **Status**: Optimized
- **Behavior**: LazyVStack used for efficient rendering
- **Testing**: Performance tests with 100+ events

### Memory Usage
- **Status**: Monitored
- **Behavior**: Core Data background contexts prevent main thread blocking
- **Testing**: Memory profiling in Instruments

## Accessibility

### VoiceOver
- **Status**: Fully supported
- **Coverage**: All interactive elements have labels/hints
- **Testing**: Manual VoiceOver testing completed

### Dynamic Type
- **Status**: Supported
- **Coverage**: All text uses system fonts
- **Testing**: Tested up to AX5

## Future Improvements

### P1 (Next Release)
- Real-time widget updates
- Improved prediction accuracy
- Enhanced Cry Insights classification

### P2 (Future)
- Cloud sync for multi-caregiver
- HealthKit integration
- Apple Watch companion app
- Advanced analytics/insights


