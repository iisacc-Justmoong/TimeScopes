import XCTest
@testable import Time_Scopes

final class RemainingTimeCalculatorTests: XCTestCase {
    func testRemainingByUnit() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-02-06 00:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let calculator = RemainingTimeCalculator(dateProvider: provider)
        let deathDate = TestDateFactory.date("2026-03-20 00:00:00")

        XCTAssertEqual(calculator.remaining(unit: .days, from: now, to: deathDate), 42)
        XCTAssertEqual(calculator.remaining(unit: .weeks, from: now, to: deathDate), 6)
        XCTAssertEqual(calculator.remaining(unit: .months, from: now, to: deathDate), 1)
    }
}
