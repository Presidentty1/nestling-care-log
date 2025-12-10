import Foundation

/// Service for providing contextual tips and guidance to parents
@MainActor
class TipService {
    static let shared = TipService()

    private let tipStorageKey = "shown_tips"
    private let lastTipDateKey = "last_tip_date"

    // Store IDs of tips that have been shown
    private var shownTipIds: Set<String> = []

    private init() {
        loadShownTips()
    }

    // MARK: - Tip Management

    /// Get the next relevant tip for a baby and goal
    func getNextTip(for baby: Baby, goal: String?, dataStore: DataStore) async -> ParentalTip? {
        // Check if we should show a new tip (once per week)
        guard shouldShowNewTip() else { return nil }

        let babyAgeWeeks = calculateBabyAgeInWeeks(birthDate: baby.dateOfBirth)

        // Get all available tips for this age and goal
        let availableTips = getTipsForAge(babyAgeWeeks, goal: goal)

        // Filter out tips that have already been shown
        let newTips = availableTips.filter { !shownTipIds.contains($0.id) }

        // Return the first new tip
        guard let tip = newTips.first else {
            // All tips shown, start over with a random tip
            let randomTip = availableTips.randomElement()
            if let randomTip = randomTip {
                markTipAsShown(randomTip.id)
            }
            return randomTip
        }

        markTipAsShown(tip.id)
        return tip
    }

    /// Mark a tip as shown and update last shown date
    private func markTipAsShown(_ tipId: String) {
        shownTipIds.insert(tipId)
        saveShownTips()

        // Update last tip date
        UserDefaults.standard.set(Date(), forKey: lastTipDateKey)
    }

    /// Check if we should show a new tip (max once per week)
    private func shouldShowNewTip() -> Bool {
        guard let lastTipDate = UserDefaults.standard.object(forKey: lastTipDateKey) as? Date else {
            return true // Never shown a tip before
        }

        let daysSinceLastTip = Calendar.current.dateComponents([.day], from: lastTipDate, to: Date()).day ?? 0
        return daysSinceLastTip >= 7 // Show new tip once per week
    }

    private func loadShownTips() {
        if let data = UserDefaults.standard.data(forKey: tipStorageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            shownTipIds = decoded
        }
    }

    private func saveShownTips() {
        if let data = try? JSONEncoder().encode(shownTipIds) {
            UserDefaults.standard.set(data, forKey: tipStorageKey)
        }
    }

    private func calculateBabyAgeInWeeks(birthDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: birthDate, to: Date())
        return (components.day ?? 0) / 7
    }

    // MARK: - Tip Content

    private func getTipsForAge(_ ageWeeks: Int, goal: String?) -> [ParentalTip] {
        var tips: [ParentalTip] = []

        // Newborn tips (0-4 weeks)
        if ageWeeks <= 4 {
            tips.append(contentsOf: [
                ParentalTip(
                    id: "newborn_feeding",
                    title: "Newborn Feeding Patterns",
                    content: "Newborns typically feed every 2-3 hours around the clock. Watch for hunger cues like rooting, sucking on fists, or increased alertness.",
                    category: .feeding,
                    ageRange: 0...4
                ),
                ParentalTip(
                    id: "newborn_sleep",
                    title: "Newborn Sleep Cycles",
                    content: "Newborns sleep in short cycles of 2-4 hours. They haven't developed day/night patterns yet, so expect frequent wake-ups.",
                    category: .sleep,
                    ageRange: 0...4
                ),
                ParentalTip(
                    id: "newborn_diapers",
                    title: "Frequent Diaper Changes",
                    content: "Newborns can have 8-12 wet diapers and several dirty ones per day. This is normal and shows they're getting enough milk.",
                    category: .diapering,
                    ageRange: 0...4
                )
            ])
        }

        // 1-3 months
        if ageWeeks >= 4 && ageWeeks <= 12 {
            tips.append(contentsOf: [
                ParentalTip(
                    id: "3month_feeding",
                    title: "Feeding Schedules",
                    content: "Around 3 months, babies often settle into more predictable feeding patterns. Some may start sleeping longer stretches at night.",
                    category: .feeding,
                    ageRange: 4...12
                ),
                ParentalTip(
                    id: "3month_naps",
                    title: "Nap Routines",
                    content: "Most 3-month-olds take 3-5 naps per day, with longer naps in the morning and afternoon. A consistent routine helps.",
                    category: .sleep,
                    ageRange: 4...12
                ),
                ParentalTip(
                    id: "3month_tummy_time",
                    title: "Tummy Time Benefits",
                    content: "Tummy time helps develop neck and core strength. Start with 2-3 minutes several times a day and gradually increase.",
                    category: .development,
                    ageRange: 4...12
                )
            ])
        }

        // Goal-specific tips
        if let goal = goal {
            switch goal {
            case "better_naps":
                tips.append(contentsOf: [
                    ParentalTip(
                        id: "nap_routine",
                        title: "Consistent Nap Routine",
                        content: "A consistent pre-nap routine (diaper change, quiet time, same sleep space) helps babies learn when it's time to sleep.",
                        category: .sleep,
                        ageRange: 4...52
                    ),
                    ParentalTip(
                        id: "nap_environment",
                        title: "Nap Environment",
                        content: "Keep the nap environment dark, quiet, and cool (68-72°F). White noise can help drown out household sounds.",
                        category: .sleep,
                        ageRange: 4...52
                    )
                ])

            case "track_feeds":
                tips.append(contentsOf: [
                    ParentalTip(
                        id: "feeding_log",
                        title: "Detailed Feeding Logs",
                        content: "Log not just when feeds happen, but also duration, amount, which side (for breastfeeding), and how baby behaved.",
                        category: .feeding,
                        ageRange: 0...52
                    ),
                    ParentalTip(
                        id: "feeding_patterns",
                        title: "Recognizing Patterns",
                        content: "After a few weeks, you'll notice feeding patterns. Some babies feed more in the evenings, others have growth spurts.",
                        category: .feeding,
                        ageRange: 4...52
                    )
                ])

            case "coordinate_caregiver":
                tips.append(contentsOf: [
                    ParentalTip(
                        id: "caregiver_handoff",
                        title: "Caregiver Handoff Notes",
                        content: "Leave notes about recent feeds, diaper changes, and baby's mood to help the next caregiver.",
                        category: .general,
                        ageRange: 0...52
                    ),
                    ParentalTip(
                        id: "shared_routines",
                        title: "Shared Routines",
                        content: "When possible, maintain similar routines across caregivers. This provides consistency for your baby.",
                        category: .general,
                        ageRange: 0...52
                    )
                ])
            default:
                break
            }
        }

        // General tips for all ages
        tips.append(contentsOf: [
            ParentalTip(
                id: "responsive_parenting",
                title: "Responsive Parenting",
                content: "Responding to your baby's cues builds trust and security. It's okay to comfort a crying baby - this doesn't create 'bad habits'.",
                category: .general,
                ageRange: 0...52
            ),
            ParentalTip(
                id: "self_care",
                title: "Parent Self-Care",
                content: "Taking care of yourself helps you take better care of your baby. Try to nap when baby naps and accept help when offered.",
                category: .general,
                ageRange: 0...52
            )
        ])

        // Filter tips by age range
        return tips.filter { $0.ageRange.contains(ageWeeks) }
    }
}

struct ParentalTip: Identifiable {
    let id: String
    let title: String
    let content: String
    let category: TipCategory
    let ageRange: ClosedRange<Int>

    enum TipCategory {
        case feeding
        case sleep
        case diapering
        case development
        case general
    }
}

