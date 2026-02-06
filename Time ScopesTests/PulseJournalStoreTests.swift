import Foundation
import XCTest
@testable import Time_Scopes

@MainActor
final class PulseJournalStoreTests: XCTestCase {
    private var suiteNames: [String] = []

    override func tearDown() {
        suiteNames.forEach { name in
            UserDefaults(suiteName: name)?.removePersistentDomain(forName: name)
        }
        suiteNames = []
        super.tearDown()
    }

    func testAddUpdateDeleteAndFiltering() throws {
        let defaults = makeDefaults()
        let center = NotificationCenter()
        let store = PulseJournalStore(
            defaults: defaults,
            legacyDefaults: defaults,
            storeKey: "PulseJournalStoreTests.entries",
            notificationCenter: center,
            observeLifecycle: false
        )

        store.addEntry(note: "   ")
        XCTAssertTrue(store.entries.isEmpty)

        let firstDate = TestDateFactory.date("2026-02-06 09:00:00")
        let secondDate = TestDateFactory.date("2026-02-07 10:30:00")
        store.addEntry(note: "  first  ", date: firstDate)
        store.addEntry(note: "second", date: secondDate)

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.entries.first?.note, "second")
        XCTAssertEqual(store.recentEntries(limit: 1).map(\.note), ["second"])

        let firstID = try XCTUnwrap(store.entries.last?.id)
        store.updateEntry(id: firstID, note: "updated")
        XCTAssertEqual(store.entries.last?.note, "updated")
        store.updateEntry(id: firstID, note: "   ")
        XCTAssertEqual(store.entries.last?.note, "updated")

        let calendar = TestDateFactory.makeCalendar()
        XCTAssertEqual(store.entries(on: firstDate, calendar: calendar).count, 1)
        XCTAssertEqual(store.entries(on: secondDate, calendar: calendar).count, 1)

        store.deleteEntry(id: firstID)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.note, "second")
    }

    func testMigrateFromLegacyDefaultsWhenSharedStoreIsEmpty() throws {
        let defaults = makeDefaults()
        let legacyDefaults = makeDefaults()
        let key = "PulseJournalStoreTests.migration"

        let legacyEntry = PulseJournalEntry(
            id: UUID(),
            date: TestDateFactory.date("2026-02-06 12:00:00"),
            note: "legacy"
        )
        legacyDefaults.set(try encode([legacyEntry]), forKey: key)

        let store = PulseJournalStore(
            defaults: defaults,
            legacyDefaults: legacyDefaults,
            storeKey: key,
            notificationCenter: NotificationCenter(),
            observeLifecycle: false
        )

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.note, "legacy")
        XCTAssertNotNil(defaults.data(forKey: key))
    }

    func testObserverReloadsOnPulseChangeAndForegroundNotification() throws {
        let defaults = makeDefaults()
        let center = NotificationCenter()
        let key = "PulseJournalStoreTests.observer"
        let foregroundName = Notification.Name("PulseJournalStoreTests.Foreground")
        let store = PulseJournalStore(
            defaults: defaults,
            legacyDefaults: defaults,
            storeKey: key,
            notificationCenter: center,
            observeLifecycle: true,
            foregroundNotificationName: foregroundName
        )

        XCTAssertTrue(store.entries.isEmpty)

        let first = PulseJournalEntry(
            id: UUID(),
            date: TestDateFactory.date("2026-02-06 15:00:00"),
            note: "fromNotification"
        )
        defaults.set(try encode([first]), forKey: key)
        center.post(name: .pulseJournalDidChange, object: nil)
        waitUntil(store.entries.count == 1)
        XCTAssertEqual(store.entries.first?.note, "fromNotification")

        let second = PulseJournalEntry(
            id: UUID(),
            date: TestDateFactory.date("2026-02-06 16:00:00"),
            note: "fromForeground"
        )
        defaults.set(try encode([second]), forKey: key)
        center.post(name: foregroundName, object: nil)
        waitUntil(store.entries.count == 1 && store.entries.first?.note == "fromForeground")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "PulseJournalStoreTests.\(UUID().uuidString)"
        suiteNames.append(suiteName)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create UserDefaults suite: \(suiteName)")
        }
        return defaults
    }

    private func encode(_ entries: [PulseJournalEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(entries)
    }

    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 1.0) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        XCTFail("Condition not met before timeout")
    }
}
