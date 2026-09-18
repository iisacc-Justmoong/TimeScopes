import Foundation
import XCTest
@testable import Time_Scopes

@MainActor
final class UntilBirthTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDown() {
        let fileManager = FileManager.default
        temporaryDirectories.forEach { directory in
            try? fileManager.removeItem(at: directory)
        }
        temporaryDirectories = []
        super.tearDown()
    }

    func testDaysUntilBirthReturnsZeroWhenBirthdayIsPast() {
        let userData = makeUserData()
        let calendar = SystemDateProvider().calendar
        let today = SystemDateProvider().today()
        userData.birthday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        XCTAssertEqual(userData.daysUntilBirth(), 0)
    }

    func testDaysUntilBirthReturnsPositiveDaysForFutureBirthday() {
        let userData = makeUserData()
        let calendar = SystemDateProvider().calendar
        let today = SystemDateProvider().today()
        userData.birthday = calendar.date(byAdding: .day, value: 12, to: today) ?? today

        XCTAssertEqual(userData.daysUntilBirth(), 12)
    }

    private func makeUserData() -> UserData {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("UntilBirthTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directory)
        let widgetStore = WidgetSnapshotStore(
            container: WidgetSharedContainer(appGroupID: "UntilBirthTests", fixedContainerURL: directory),
            reloadTimelines: {}
        )
        return UserData(
            store: InMemoryUserProfileStore(),
            ageCalculator: AgeCalculator(),
            dateProvider: SystemDateProvider(),
            widgetStore: widgetStore
        )
    }
}
