import XCTest
@testable import Time_Scopes

final class LifeRemainingWorkingTimeTests: XCTestCase {
    func testUpdateRemainingWorkingTimeUsesClampedWorkHours() {
        let calendar = TestDateFactory.makeCalendar()
        let now = TestDateFactory.date("2026-01-05 00:00:00")
        let provider = FixedDateProvider(now: now, calendar: calendar)
        let store = InMemoryUserProfileStore(
            initialProfile: UserProfile(
                name: "A",
                birthday: TestDateFactory.date("2000-01-01 00:00:00"),
                deathDate: TestDateFactory.date("2026-01-12 00:00:00"),
                sex: "Other",
                workHoursPerDay: 30,
                sleepHoursPerDay: 8
            )
        )

        let userData = UserData(
            store: store,
            ageCalculator: AgeCalculator(dateProvider: provider),
            dateProvider: provider
        )
        let livedTime = UserLivedTime(
            model: userData,
            livedTimeCalculator: LivedTimeCalculator(),
            dateProvider: provider
        )
        let remaining = LifeRemainingWorkingTime(userLivedTime: livedTime, dateProvider: provider)

        remaining.updateRemainingWorkingTime()

        XCTAssertEqual(remaining.remainingWorkingDays, 6)
        XCTAssertEqual(remaining.remainingWorkingHours, 6 * 24)
    }
}
