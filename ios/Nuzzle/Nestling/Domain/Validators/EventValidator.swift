import Foundation

/// Validates event data before saving
enum EventValidationError: LocalizedError {
    case endBeforeStart
    case negativeDuration
    case zeroDuration
    case zeroAmount
    case negativeAmount
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .endBeforeStart:
            return "End time cannot be before start time"
        case .negativeDuration:
            return "Duration cannot be negative"
        case .zeroDuration:
            return "Duration must be at least 1 minute"
        case .zeroAmount:
            return "Amount must be greater than 0"
        case .negativeAmount:
            return "Amount cannot be negative"
        case .invalidDateRange:
            return "Event date is too far in the future"
        }
    }
}

struct EventValidator {
    /// Validate an event before saving
    static func validate(_ event: Event) throws {
        // Validate time relationships
        if let endTime = event.endTime {
            if endTime < event.startTime {
                throw EventValidationError.endBeforeStart
            }
        }
        
        // Validate duration
        if let duration = event.durationMinutes {
            if duration < 0 {
                throw EventValidationError.negativeDuration
            }
            if duration == 0 && event.type == .sleep {
                throw EventValidationError.zeroDuration
            }
        }
        
        // Validate amount (for feeds)
        if event.type == .feed {
            if let amount = event.amount {
                if amount < 0 {
                    throw EventValidationError.negativeAmount
                }
                if amount == 0 && event.subtype != "breast" {
                    throw EventValidationError.zeroAmount
                }
            } else if event.subtype != "breast" {
                // Non-breast feeds must have amount
                throw EventValidationError.zeroAmount
            }
        }
        
        // Validate date range (prevent future dates - allow up to 5 minutes for clock drift)
        let maxFutureDate = Date().addingTimeInterval(5 * 60) // 5 minutes in future for clock drift
        if event.startTime > maxFutureDate {
            throw EventValidationError.invalidDateRange
        }
    }
    
    /// Validate feed-specific requirements
    static func validateFeed(amount: Double?, unit: String?, subtype: String) throws {
        if subtype != "breast" {
            guard let amount = amount, amount > 0 else {
                throw EventValidationError.zeroAmount
            }
            
            // UX-01: Validate minimum
            if amount < AppConstants.minimumFeedAmountML {
                throw EventValidationError.zeroAmount // Will show minimum message
            }
            
            // UX-01: Validate maximum to prevent unrealistic values like "118 oz"
            let maxML = (unit == "oz") ? AppConstants.maximumFeedAmountOZ * AppConstants.mlPerOz : AppConstants.maximumFeedAmountML
            if amount > maxML {
                throw EventValidationError.invalidDateRange // Reuse error type, will show max message
            }
        }
    }
    
    /// Validate sleep-specific requirements
    static func validateSleep(startTime: Date, endTime: Date?) throws {
        if let endTime = endTime {
            if endTime < startTime {
                throw EventValidationError.endBeforeStart
            }
            
            let duration = DateUtils.durationMinutes(from: startTime, to: endTime)
            if duration < 1 {
                throw EventValidationError.zeroDuration
            }
        }
    }
}

