import XCTest
@testable import Time_Scopes

final class WidgetSnapshotTests: XCTestCase {
    func testDecodeMissingFieldsFallsBackToEmpty() throws {
        let json = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: json)

        XCTAssertEqual(decoded.profile, .empty)
        XCTAssertEqual(decoded.elapsed, .empty)
        XCTAssertEqual(decoded.milestones, .empty)
        XCTAssertEqual(decoded.highlights, .empty)
        XCTAssertEqual(decoded.daily, .empty)
        XCTAssertEqual(decoded.pulse, .empty)
    }

    func testEncodeDecodeRoundTrip() throws {
        let snapshot = WidgetSnapshot(
            updatedAt: TestDateFactory.date("2026-02-06 12:00:00"),
            profile: .init(name: "A", age: 30, monthsLeft: 600, weeksLeft: 2600, daysLeft: 18000),
            elapsed: .init(months: 300, weeks: 1300, days: 9000, hours: 200000, minutes: 12000000, seconds: 720000000),
            milestones: .init(nextDecadeAge: 40, yearsUntilNextDecade: 10, daysUntilNextBirthday: 100, weekdaysRemaining: 8000),
            highlights: .init(yearRemainingDays: 120, nextChristmasDays: 320, remainingMondays: 30),
            daily: .init(
                nextHourText: "10m",
                nextHourPercent: "20%",
                sunTitle: "Until Sunset",
                sunValueText: "3h",
                sunPercentText: "60%",
                timeLeftText: "12h",
                timeLeftPercent: "50%",
                freeTimeText: "4h",
                freeTimePercent: "16%",
                allocatedTimeText: "20h",
                allocatedTimePercent: "84%"
            ),
            pulse: .init(
                todaySeries: Array(repeating: 1.0, count: 24),
                todayMax: 3,
                currentFraction: 0.5,
                weeklyDays: [.init(label: "Mon", intensity: 0.4)],
                weeklyPatternText: "Pattern",
                weeklyPeakText: "Wed",
                weeklyLowText: "Sun",
                prescriptions: [.init(focus: "Focus", title: "Keep block", impact: "2h")],
                journalPrompt: "Write",
                recentEntries: [.init(date: TestDateFactory.date("2026-02-05 10:00:00"), note: "Entry")]
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

        XCTAssertEqual(decoded.profile.name, "A")
        XCTAssertEqual(decoded.pulse.weeklyPatternText, "Pattern")
        XCTAssertEqual(decoded.daily.timeLeftText, "12h")
    }
}
