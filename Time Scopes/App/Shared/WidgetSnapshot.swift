import Foundation

struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct Profile: Codable, Equatable, Sendable {
        let name: String
        let age: Int
        let monthsLeft: Int
        let weeksLeft: Int
        let daysLeft: Int

        static let empty = Profile(name: "", age: 0, monthsLeft: 0, weeksLeft: 0, daysLeft: 0)
    }

    struct Elapsed: Codable, Equatable, Sendable {
        let months: Int
        let weeks: Int
        let days: Int
        let hours: Int
        let minutes: Int
        let seconds: Int

        static let empty = Elapsed(months: 0, weeks: 0, days: 0, hours: 0, minutes: 0, seconds: 0)
    }

    struct Milestones: Codable, Equatable, Sendable {
        let nextDecadeAge: Int
        let yearsUntilNextDecade: Int
        let daysUntilNextBirthday: Int
        let weekdaysRemaining: Int

        static let empty = Milestones(nextDecadeAge: 0, yearsUntilNextDecade: 0, daysUntilNextBirthday: 0, weekdaysRemaining: 0)
    }

    struct Highlights: Codable, Equatable, Sendable {
        let yearRemainingDays: Int
        let nextChristmasDays: Int
        let remainingMondays: Int

        static let empty = Highlights(yearRemainingDays: 0, nextChristmasDays: 0, remainingMondays: 0)
    }

    struct DailySummary: Codable, Equatable, Sendable {
        let nextHourText: String
        let nextHourPercent: String
        let sunTitle: String
        let sunValueText: String
        let sunPercentText: String
        let timeLeftText: String
        let timeLeftPercent: String
        let freeTimeText: String
        let freeTimePercent: String
        let allocatedTimeText: String
        let allocatedTimePercent: String

        static let empty = DailySummary(
            nextHourText: "0m 0s",
            nextHourPercent: "0%",
            sunTitle: "Until Sunrise/Sunset",
            sunValueText: "0h 0m 0s",
            sunPercentText: "0%",
            timeLeftText: "0h 0m 0s",
            timeLeftPercent: "0%",
            freeTimeText: "0h 0m 0s",
            freeTimePercent: "0%",
            allocatedTimeText: "0h 0m 0s",
            allocatedTimePercent: "0%"
        )
    }

    struct Pulse: Codable, Equatable, Sendable {
        struct Day: Codable, Equatable, Sendable {
            let label: String
            let intensity: Double
        }

        struct Prescription: Codable, Equatable, Sendable {
            let focus: String
            let title: String
            let impact: String
        }

        struct JournalEntry: Codable, Equatable, Sendable {
            let date: Date
            let note: String
        }

        let todaySeries: [Double]
        let todayMax: Double
        let currentFraction: Double
        let weeklyDays: [Day]
        let weeklyPatternText: String
        let weeklyPeakText: String
        let weeklyLowText: String
        let prescriptions: [Prescription]
        let recentEntries: [JournalEntry]

        static let empty = Pulse(
            todaySeries: Array(repeating: 0, count: 24),
            todayMax: 0,
            currentFraction: 0,
            weeklyDays: [],
            weeklyPatternText: "Not enough data yet.",
            weeklyPeakText: "No data",
            weeklyLowText: "No data",
            prescriptions: [],
            recentEntries: []
        )
    }

    let syncVersion: Int64
    let updatedAt: Date
    let profile: Profile
    let elapsed: Elapsed
    let milestones: Milestones
    let highlights: Highlights
    let daily: DailySummary
    let pulse: Pulse

    enum CodingKeys: String, CodingKey {
        case syncVersion
        case updatedAt
        case profile
        case elapsed
        case milestones
        case highlights
        case daily
        case pulse
    }

    static let empty = WidgetSnapshot(
        syncVersion: 0,
        updatedAt: Date(timeIntervalSince1970: 0),
        profile: .empty,
        elapsed: .empty,
        milestones: .empty,
        highlights: .empty,
        daily: .empty,
        pulse: .empty
    )

    init(
        syncVersion: Int64 = 0,
        updatedAt: Date,
        profile: Profile,
        elapsed: Elapsed,
        milestones: Milestones,
        highlights: Highlights,
        daily: DailySummary,
        pulse: Pulse
    ) {
        self.syncVersion = syncVersion
        self.updatedAt = updatedAt
        self.profile = profile
        self.elapsed = elapsed
        self.milestones = milestones
        self.highlights = highlights
        self.daily = daily
        self.pulse = pulse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        syncVersion = try container.decodeIfPresent(Int64.self, forKey: .syncVersion) ?? 0
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date(timeIntervalSince1970: 0)
        profile = try container.decodeIfPresent(Profile.self, forKey: .profile) ?? .empty
        elapsed = try container.decodeIfPresent(Elapsed.self, forKey: .elapsed) ?? .empty
        milestones = try container.decodeIfPresent(Milestones.self, forKey: .milestones) ?? .empty
        highlights = try container.decodeIfPresent(Highlights.self, forKey: .highlights) ?? .empty
        daily = try container.decodeIfPresent(DailySummary.self, forKey: .daily) ?? .empty
        pulse = try container.decodeIfPresent(Pulse.self, forKey: .pulse) ?? .empty
    }
}
