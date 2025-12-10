import Foundation
import SwiftData

// MARK: - SwiftData Models for CloudKit Sync

@Model
final class SyncBaby {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateOfBirth: Date
    var sex: String? // Store as string for CloudKit compatibility
    var timezone: String
    var primaryFeedingStyle: String? // Store as string
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SyncEvent.baby)
    var events: [SyncEvent] = []

    init(
        id: UUID = UUID(),
        name: String,
        dateOfBirth: Date,
        sex: String? = nil,
        timezone: String = TimeZone.current.identifier,
        primaryFeedingStyle: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.sex = sex
        self.timezone = timezone
        self.primaryFeedingStyle = primaryFeedingStyle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convert from/to domain model
    func toDomainModel() -> Baby {
        return Baby(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            sex: sex.flatMap { Sex(rawValue: $0) },
            timezone: timezone,
            primaryFeedingStyle: primaryFeedingStyle.flatMap { FeedingStyle(rawValue: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func fromDomainModel(_ baby: Baby) -> SyncBaby {
        return SyncBaby(
            id: baby.id,
            name: baby.name,
            dateOfBirth: baby.dateOfBirth,
            sex: baby.sex?.rawValue,
            timezone: baby.timezone,
            primaryFeedingStyle: baby.primaryFeedingStyle?.rawValue,
            createdAt: baby.createdAt,
            updatedAt: baby.updatedAt
        )
    }
}

@Model
final class SyncEvent {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var type: String // Store EventType as string
    var subtype: String?
    var startTime: Date
    var endTime: Date?
    var amount: Double?
    var unit: String?
    var side: String?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var baby: SyncBaby?

    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: String,
        subtype: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        amount: Double? = nil,
        unit: String? = nil,
        side: String? = nil,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.subtype = subtype
        self.startTime = startTime
        self.endTime = endTime
        self.amount = amount
        self.unit = unit
        self.side = side
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convert from/to domain model
    func toDomainModel() -> Event {
        return Event(
            id: id,
            babyId: babyId,
            type: EventType(rawValue: type) ?? .feed,
            subtype: subtype,
            startTime: startTime,
            endTime: endTime,
            amount: amount,
            unit: unit,
            side: side,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func fromDomainModel(_ event: Event) -> SyncEvent {
        return SyncEvent(
            id: event.id,
            babyId: event.babyId,
            type: event.type.rawValue,
            subtype: event.subtype,
            startTime: event.startTime,
            endTime: event.endTime,
            amount: event.amount,
            unit: event.unit,
            side: event.side,
            note: event.note,
            createdAt: event.createdAt,
            updatedAt: event.updatedAt
        )
    }
}

@Model
final class SyncPrediction {
    @Attribute(.unique) var id: UUID
    var babyId: UUID
    var type: String
    var predictedTime: Date
    var confidence: Double
    var reasoning: String
    var createdAt: Date
    var expiresAt: Date

    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: String,
        predictedTime: Date,
        confidence: Double,
        reasoning: String,
        createdAt: Date = Date(),
        expiresAt: Date
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.predictedTime = predictedTime
        self.confidence = confidence
        self.reasoning = reasoning
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

@Model
final class SyncAppSettings {
    @Attribute(.unique) var id: UUID = UUID()
    var aiDataSharingEnabled: Bool
    var feedReminderEnabled: Bool
    var feedReminderHours: Int
    var napWindowAlertEnabled: Bool
    var diaperReminderEnabled: Bool
    var diaperReminderHours: Int
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    var cryInsightsNotifyMe: Bool
    var onboardingCompleted: Bool
    var preferredUnit: String
    var timeFormat24Hour: Bool
    var preferMediumSheet: Bool
    var spotlightIndexingEnabled: Bool
    var primaryGoal: String?
    var trialOffersDismissed: Bool

    init(from settings: AppSettings) {
        self.aiDataSharingEnabled = settings.aiDataSharingEnabled
        self.feedReminderEnabled = settings.feedReminderEnabled
        self.feedReminderHours = settings.feedReminderHours
        self.napWindowAlertEnabled = settings.napWindowAlertEnabled
        self.diaperReminderEnabled = settings.diaperReminderEnabled
        self.diaperReminderHours = settings.diaperReminderHours
        self.quietHoursStart = settings.quietHoursStart
        self.quietHoursEnd = settings.quietHoursEnd
        self.cryInsightsNotifyMe = settings.cryInsightsNotifyMe
        self.onboardingCompleted = settings.onboardingCompleted
        self.preferredUnit = settings.preferredUnit
        self.timeFormat24Hour = settings.timeFormat24Hour
        self.preferMediumSheet = settings.preferMediumSheet
        self.spotlightIndexingEnabled = settings.spotlightIndexingEnabled
        self.primaryGoal = settings.primaryGoal
        self.trialOffersDismissed = settings.trialOffersDismissed
    }

    func toDomainModel() -> AppSettings {
        return AppSettings(
            aiDataSharingEnabled: aiDataSharingEnabled,
            feedReminderEnabled: feedReminderEnabled,
            feedReminderHours: feedReminderHours,
            napWindowAlertEnabled: napWindowAlertEnabled,
            diaperReminderEnabled: diaperReminderEnabled,
            diaperReminderHours: diaperReminderHours,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
            cryInsightsNotifyMe: cryInsightsNotifyMe,
            onboardingCompleted: onboardingCompleted,
            preferredUnit: preferredUnit,
            timeFormat24Hour: timeFormat24Hour,
            preferMediumSheet: preferMediumSheet,
            spotlightIndexingEnabled: spotlightIndexingEnabled,
            primaryGoal: primaryGoal,
            trialOffersDismissed: trialOffersDismissed
        )
    }
}


