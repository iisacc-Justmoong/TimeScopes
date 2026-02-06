import XCTest
@testable import Time_Scopes

@available(iOS 17.0, *)
final class PulseJournalIntentTests: XCTestCase {
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

    func testPerformRequestsComposerOpenActionWhenNoTextProvided() async throws {
        var intent = AddPulseJournalEntryIntent()
        intent.note = nil
        _ = try await intent.perform()

        XCTAssertTrue(PulseJournalWidgetAction.consumeOpenComposerRequest())
    }

    func testPerformStoresEntryWhenTextProvided() async throws {
        var intent = AddPulseJournalEntryIntent()
        intent.note = "Capture this thought"
        _ = try await intent.perform()

        XCTAssertFalse(PulseJournalWidgetAction.hasPendingOpenComposerRequest)
        guard let data = defaults.data(forKey: WidgetSharedConstants.pulseJournalEntriesStoreKey) else {
            return XCTFail("Expected a persisted journal entry.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([StoredEntry].self, from: data)
        XCTAssertEqual(entries.first?.note, "Capture this thought")
    }
}
