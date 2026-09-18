import XCTest
@testable import Time_Scopes

final class PulseJournalWidgetActionTests: XCTestCase {
    private struct StoredEntry: Decodable {
        let id: UUID
        let date: Date
        let note: String
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetSharedConstants.appGroupID) ?? .standard
    }

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: PulseJournalWidgetAction.openComposerRequestKey)
        defaults.removeObject(forKey: WidgetSharedConstants.pulseJournalEntriesStoreKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: PulseJournalWidgetAction.openComposerRequestKey)
        defaults.removeObject(forKey: WidgetSharedConstants.pulseJournalEntriesStoreKey)
        super.tearDown()
    }

    func testRequestAndConsume() {
        XCTAssertFalse(PulseJournalWidgetAction.hasPendingOpenComposerRequest)

        PulseJournalWidgetAction.requestOpenComposer()
        XCTAssertTrue(PulseJournalWidgetAction.hasPendingOpenComposerRequest)

        XCTAssertTrue(PulseJournalWidgetAction.consumeOpenComposerRequest())
        XCTAssertFalse(PulseJournalWidgetAction.hasPendingOpenComposerRequest)
    }

    func testAppendEntryPersistsEntry() throws {
        XCTAssertTrue(PulseJournalWidgetAction.appendEntry(note: "Quick capture"))

        guard let data = defaults.data(forKey: WidgetSharedConstants.pulseJournalEntriesStoreKey) else {
            return XCTFail("Expected persisted data.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([StoredEntry].self, from: data)
        XCTAssertEqual(entries.first?.note, "Quick capture")
    }

    func testAppendEntryRejectsBlankInput() {
        XCTAssertFalse(PulseJournalWidgetAction.appendEntry(note: "   "))
        XCTAssertNil(defaults.data(forKey: WidgetSharedConstants.pulseJournalEntriesStoreKey))
    }
}
