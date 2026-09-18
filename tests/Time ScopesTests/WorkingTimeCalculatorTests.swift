import XCTest
@testable import Time_Scopes

final class WorkingTimeCalculatorTests: XCTestCase {
    func testRemainingWorkingTimeCountsWeekdaysOnly() {
        let calendar = TestDateFactory.makeCalendar()
        let today = TestDateFactory.date("2026-02-02 00:00:00") // Monday
        let provider = FixedDateProvider(now: today, calendar: calendar)
        let calculator = WorkingTimeCalculator(dateProvider: provider, workingHoursPerDay: 8)

        let working = calculator.remainingWorkingTime(from: today, currentAge: 30, deathAge: 30)

        XCTAssertEqual(working.remainingWorkingDays, 0)
        XCTAssertEqual(working.remainingWorkingHours, 0)
    }

    func testRemainingWorkingTimeReturnsZeroWhenDeathAgeIsPast() {
        let calendar = TestDateFactory.makeCalendar()
        let today = TestDateFactory.date("2026-02-02 00:00:00")
        let provider = FixedDateProvider(now: today, calendar: calendar)
        let calculator = WorkingTimeCalculator(dateProvider: provider, workingHoursPerDay: 8)

        let working = calculator.remainingWorkingTime(from: today, currentAge: 60, deathAge: 50)

        XCTAssertEqual(working.remainingWorkingDays, 0)
        XCTAssertEqual(working.remainingWorkingHours, 0)
    }
}
