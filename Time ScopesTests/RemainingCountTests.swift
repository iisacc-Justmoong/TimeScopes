import XCTest
@testable import Time_Scopes

private struct StubRemainingTimeCalculator: RemainingTimeCalculating {
    let value: Int

    func remaining(unit: RemainingTimeUnit, from now: Date, to deathDate: Date) -> Int {
        value
    }
}

private final class TestRemainingCount: RemainingCount {
    private let unit: RemainingTimeUnit

    init(userData: UserData, unit: RemainingTimeUnit, calculator: RemainingTimeCalculating, dateProvider: DateProviding) {
        self.unit = unit
        super.init(userData: userData, calculator: calculator, dateProvider: dateProvider)
    }

    override func remainingUnit() -> RemainingTimeUnit {
        unit
    }
}

final class RemainingCountTests: XCTestCase {
    func testRecalculateClampsNegativeValuesToZero() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-01-01 00:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let store = InMemoryUserProfileStore(
            initialProfile: UserProfile(
                name: "A",
                birthday: TestDateFactory.date("2000-01-01 00:00:00"),
                deathDate: TestDateFactory.date("2025-12-31 00:00:00"),
                sex: "Other",
                workHoursPerDay: 8,
                sleepHoursPerDay: 8
            )
        )
        let userData = UserData(
            store: store,
            ageCalculator: AgeCalculator(dateProvider: provider),
            dateProvider: provider
        )

        let count = TestRemainingCount(
            userData: userData,
            unit: .days,
            calculator: StubRemainingTimeCalculator(value: -10),
            dateProvider: provider
        )

        count.recalculate()
        XCTAssertEqual(count.remaining, 0)
    }

    func testConcreteUnitsMapCorrectly() {
        let store = InMemoryUserProfileStore()
        let userData = UserData(store: store)

        XCTAssertEqual(MonthCount(viewModel: userData).remainingUnit(), .months)
        XCTAssertEqual(WeekCount(viewModel: userData).remainingUnit(), .weeks)
        XCTAssertEqual(DayCount(viewModel: userData).remainingUnit(), .days)
    }
}
