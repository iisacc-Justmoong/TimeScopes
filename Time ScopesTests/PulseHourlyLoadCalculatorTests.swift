import XCTest
@testable import Time_Scopes

final class PulseHourlyLoadCalculatorTests: XCTestCase {
    private let calendar = TestDateFactory.makeCalendar()

    func testEmptyInputsReturn24Zeros() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 12:00:00"),
            calendar: calendar,
            eventSpans: [],
            reminderSpans: [],
            reminderMoments: []
        )

        XCTAssertEqual(series.count, 24)
        XCTAssertTrue(series.allSatisfy { $0 == 0 })
    }

    func testEventSpanCountsOverlappingHours() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [
                .init(
                    start: TestDateFactory.date("2026-02-06 09:30:00"),
                    end: TestDateFactory.date("2026-02-06 11:00:00")
                )
            ],
            reminderSpans: [],
            reminderMoments: []
        )

        XCTAssertEqual(series[8], 0)
        XCTAssertEqual(series[9], 1)
        XCTAssertEqual(series[10], 1)
        XCTAssertEqual(series[11], 0)
    }

    func testEventEndingAtBoundaryDoesNotSpillIntoNextHour() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [
                .init(
                    start: TestDateFactory.date("2026-02-06 10:00:00"),
                    end: TestDateFactory.date("2026-02-06 12:00:00")
                )
            ],
            reminderSpans: [],
            reminderMoments: []
        )

        XCTAssertEqual(series[10], 1)
        XCTAssertEqual(series[11], 1)
        XCTAssertEqual(series[12], 0)
    }

    func testCrossMidnightEventClampsToDayBounds() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [
                .init(
                    start: TestDateFactory.date("2026-02-05 23:30:00"),
                    end: TestDateFactory.date("2026-02-06 01:15:00")
                )
            ],
            reminderSpans: [],
            reminderMoments: []
        )

        XCTAssertEqual(series[0], 1)
        XCTAssertEqual(series[1], 1)
        XCTAssertEqual(series[2], 0)
    }

    func testReminderMomentCountsSingleHour() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [],
            reminderSpans: [],
            reminderMoments: [
                TestDateFactory.date("2026-02-06 14:00:00"),
                TestDateFactory.date("2026-02-06 14:59:59")
            ]
        )

        XCTAssertEqual(series[13], 0)
        XCTAssertEqual(series[14], 2)
        XCTAssertEqual(series[15], 0)
    }

    func testReminderSpanAndMomentAccumulateWithEvents() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [
                .init(
                    start: TestDateFactory.date("2026-02-06 09:00:00"),
                    end: TestDateFactory.date("2026-02-06 10:30:00")
                )
            ],
            reminderSpans: [
                .init(
                    start: TestDateFactory.date("2026-02-06 09:15:00"),
                    end: TestDateFactory.date("2026-02-06 11:10:00")
                )
            ],
            reminderMoments: [
                TestDateFactory.date("2026-02-06 10:05:00")
            ]
        )

        XCTAssertEqual(series[8], 0)
        XCTAssertEqual(series[9], 2)
        XCTAssertEqual(series[10], 3)
        XCTAssertEqual(series[11], 1)
        XCTAssertEqual(series[12], 0)
    }

    func testOutOfDayMomentsAreIgnored() {
        let series = PulseHourlyLoadCalculator.makeSeries(
            for: TestDateFactory.date("2026-02-06 00:00:00"),
            calendar: calendar,
            eventSpans: [],
            reminderSpans: [],
            reminderMoments: [
                TestDateFactory.date("2026-02-05 23:59:59"),
                TestDateFactory.date("2026-02-07 00:00:00")
            ]
        )

        XCTAssertTrue(series.allSatisfy { $0 == 0 })
    }
}
