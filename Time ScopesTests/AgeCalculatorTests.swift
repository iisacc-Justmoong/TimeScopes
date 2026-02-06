import XCTest
@testable import Time_Scopes

final class AgeCalculatorTests: XCTestCase {
    func testAgeAndDeathAge() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-02-06 12:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let calculator = AgeCalculator(dateProvider: provider)

        let birthday = TestDateFactory.date("2000-02-07 00:00:00")
        let deathDate = TestDateFactory.date("2080-02-07 00:00:00")

        XCTAssertEqual(calculator.age(birthday: birthday, now: now), 25)
        XCTAssertEqual(calculator.deathAge(birthday: birthday, deathDate: deathDate), 80)
    }
}
