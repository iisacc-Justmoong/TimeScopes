import XCTest
@testable import Time_Scopes

final class DateUtilityTests: XCTestCase {
    func testDaysInLeapYear() {
        let date = TestDateFactory.date("2024-02-01 00:00:00")
        XCTAssertEqual(DateUtility.daysInYear(for: date), 366)
    }

    func testStartOfDay() {
        let date = TestDateFactory.date("2026-02-06 12:34:56")
        let start = DateUtility.startOfDay(for: date)

        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
        XCTAssertEqual(calendar.component(.minute, from: start), 0)
    }
}
