import XCTest
@testable import Time_Scopes

final class NextEventCalculatorTests: XCTestCase {
    func testBirthdayStatsWhenBirthdayIsToday() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-02-06 10:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let calculator = NextEventCalculator(dateProvider: provider)
        let birthday = TestDateFactory.date("2000-02-06 00:00:00")

        let stats = calculator.nextBirthdayStats(from: birthday)

        XCTAssertEqual(stats.daysUntilNextBirthday, 0)
        XCTAssertEqual(stats.daysInYear, 365)
    }

    func testBirthdayStatsForFutureBirthday() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-02-06 10:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let calculator = NextEventCalculator(dateProvider: provider)
        let birthday = TestDateFactory.date("2000-05-01 00:00:00")

        let stats = calculator.nextBirthdayStats(from: birthday)
        let expectedNextBirthday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let expectedDays = calendar.dateComponents([.day], from: provider.today(), to: expectedNextBirthday).day!

        XCTAssertEqual(stats.daysUntilNextBirthday, expectedDays)
    }

    func testNextDecadeStats() {
        let calculator = NextEventCalculator()
        let stats = calculator.nextDecadeStats(from: 34)

        XCTAssertEqual(stats.nextDecade, 40)
        XCTAssertEqual(stats.yearsUntilNextDecade, 6)
    }
}
