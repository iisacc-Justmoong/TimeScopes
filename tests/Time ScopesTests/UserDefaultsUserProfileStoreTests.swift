import XCTest
@testable import Time_Scopes

final class UserDefaultsUserProfileStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TimeScopesTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSaveAndLoadProfileRoundTrip() {
        let store = UserDefaultsUserProfileStore(userDefaults: defaults, userDefaultsKey: "profile")
        let profile = UserProfile(
            name: "Tester",
            birthday: TestDateFactory.date("2000-01-01 00:00:00"),
            deathDate: TestDateFactory.date("2080-01-01 00:00:00"),
            sex: "Other",
            workHoursPerDay: 7,
            sleepHoursPerDay: 8
        )

        store.saveProfile(profile)
        let loaded = store.loadProfile()

        XCTAssertEqual(loaded?.name, "Tester")
        XCTAssertEqual(loaded?.workHoursPerDay, 7)
        XCTAssertEqual(loaded?.sleepHoursPerDay, 8)
    }

    func testLoadLegacySnapshotUsesDefaultWorkAndSleep() throws {
        struct LegacySnapshot: Codable {
            let name: String
            let birthday: Date
            let deathDate: Date
            let age: Int?
            let deathAge: Int?
            let sex: String
        }

        let legacy = LegacySnapshot(
            name: "Legacy",
            birthday: TestDateFactory.date("1990-01-01 00:00:00"),
            deathDate: TestDateFactory.date("2070-01-01 00:00:00"),
            age: 35,
            deathAge: 80,
            sex: "Male"
        )
        let data = try JSONEncoder().encode(legacy)
        defaults.set(data, forKey: "profile")

        let store = UserDefaultsUserProfileStore(userDefaults: defaults, userDefaultsKey: "profile")
        let loaded = store.loadProfile()

        XCTAssertEqual(loaded?.workHoursPerDay, 8)
        XCTAssertEqual(loaded?.sleepHoursPerDay, 8)
    }
}
