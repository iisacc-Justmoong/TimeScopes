import XCTest
@testable import Time_Scopes

final class AnnualEventTests: XCTestCase {
    func testAnnualChristmasOnChristmasDayIncludesToday() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-12-25 09:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let christmas = AnnualChristmasProperties(dateProvider: provider)

        XCTAssertEqual(christmas.count, 1)
    }

    func testAnnualMondayTotalAndRemaining() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-01-15 00:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let monday = AnnualMondayProperties(dateProvider: provider)

        XCTAssertGreaterThan(monday.totalMondaysInYear(), 0)
        XCTAssertGreaterThanOrEqual(monday.count, 0)
        XCTAssertLessThanOrEqual(monday.count, monday.totalMondaysInYear())
    }

    func testElapsedDateInThisYear() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-03-10 13:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let elapsed = ElapsedDateInThisYear(dateProvider: provider)

        XCTAssertGreaterThanOrEqual(elapsed.daysElapsedThisWeek, 0)
        XCTAssertGreaterThanOrEqual(elapsed.daysElapsedThisMonth, 0)
        XCTAssertGreaterThanOrEqual(elapsed.daysElapsedThisYear, 0)
    }
}
