import XCTest
@testable import Time_Scopes

final class LivedTimeCalculatorTests: XCTestCase {
    func testLivedTimeUsesSecondBasedBreakdown() {
        let calculator = LivedTimeCalculator()
        let start = TestDateFactory.date("2026-01-01 00:00:00")
        let end = TestDateFactory.date("2026-01-02 01:01:01")

        let lived = calculator.livedTime(from: start, to: end)

        XCTAssertEqual(lived.days, 1)
        XCTAssertEqual(lived.hours, 25)
        XCTAssertEqual(lived.minutes, 1501)
        XCTAssertEqual(lived.seconds, 90061)
        XCTAssertEqual(lived.months, 0)
    }

    func testLivedTimeClampsWhenNowIsBeforeBirthday() {
        let calculator = LivedTimeCalculator()
        let birthday = TestDateFactory.date("2026-01-10 00:00:00")
        let now = TestDateFactory.date("2026-01-01 00:00:00")

        let lived = calculator.livedTime(from: birthday, to: now)
        XCTAssertEqual(lived.seconds, 0)
    }
}
