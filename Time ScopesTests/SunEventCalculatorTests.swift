import CoreLocation
import XCTest
@testable import Time_Scopes

final class SunEventCalculatorTests: XCTestCase {
    func testNextEventWindowForSeoulAtNoon() {
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        var calendar = TestDateFactory.makeCalendar(timeZone: timeZone)
        calendar.timeZone = timeZone
        let date = TestDateFactory.date("2026-06-01 12:00:00", timeZone: timeZone)
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)

        let window = SunEventCalculator.nextEventWindow(
            for: date,
            location: location,
            calendar: calendar,
            timeZone: timeZone
        )

        XCTAssertNotNil(window)
        XCTAssertTrue(window!.nextDate > date)
        XCTAssertTrue(window!.previousDate < window!.nextDate)
    }

    func testNextEventWindowReturnsNilForPolarCondition() {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let calendar = TestDateFactory.makeCalendar(timeZone: timeZone)
        let date = TestDateFactory.date("2026-06-21 12:00:00", timeZone: timeZone)
        let location = CLLocation(latitude: 89.9, longitude: 0)

        let window = SunEventCalculator.nextEventWindow(
            for: date,
            location: location,
            calendar: calendar,
            timeZone: timeZone
        )

        XCTAssertNil(window)
    }
}
